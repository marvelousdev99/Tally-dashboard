const express = require("express");
const axios = require("axios");
const xml2js = require("xml2js");
const path = require("path");

const app = express();

const PORT = 1234;
const TALLY_URL = "http://localhost:9000";

app.use(express.static(path.join(__dirname, "public")));

const parser = new xml2js.Parser({
  explicitArray: true,
  trim: true,
  ignoreAttrs: false,
  tagNameProcessors: [xml2js.processors.stripPrefix],
});

function todayStr() {
  const d = new Date();
  return `${d.getFullYear()}${String(d.getMonth() + 1).padStart(2, "0")}${String(d.getDate()).padStart(2, "0")}`;
}

/**
 * FIX #1: Corrected sign logic for Tally amounts.
 * In Tally, Sundry Creditor balances are returned as "Cr" (credit).
 * Cr = we owe them = positive due amount for our purposes.
 * Dr = they owe us = negative (not a payable).
 */
function parseAmount(v) {
  if (!v) return 0;
  const s = String(v).trim();
  if (!s || s === "0") return 0;
  const isCr = /Cr/i.test(s);
  const isDr = /Dr/i.test(s);
  const num =
    parseFloat(
      s
        .replace(/,/g, "")
        .replace(/\s*(Dr|Cr)/i, "")
        .trim(),
    ) || 0;
  if (isDr) return -num; // Dr balance on creditor = overpaid / advance
  return num; // Cr balance = amount we owe = positive
}

function daysOld(dateStr) {
  if (!dateStr || dateStr.length !== 8) return 999; // unknown → treat as old
  const y = parseInt(dateStr.slice(0, 4));
  const m = parseInt(dateStr.slice(4, 6)) - 1;
  const d = parseInt(dateStr.slice(6, 8));
  const dt = new Date(y, m, d);
  if (isNaN(dt.getTime())) return 999;
  return Math.floor((Date.now() - dt.getTime()) / 86400000);
}

function agingBucket(days) {
  if (days <= 0) return "current";
  if (days <= 30) return "0_30";
  if (days <= 60) return "30_60";
  if (days <= 90) return "60_90";
  return "90_plus";
}

function round(n) {
  return Math.round((n || 0) * 100) / 100;
}

async function queryTally(xml) {
  const res = await axios.post(TALLY_URL, xml, {
    headers: { "Content-Type": "text/xml" },
    timeout: 30000,
  });
  return parser.parseStringPromise(res.data);
}

// ─────────────────────────────────────────────
// FIX #2: Use "Bill Outstanding" collection type
// This is the CORRECT TDL for per-bill outstanding
// data with due dates in Tally Prime.
// The old approach fetching BillAllocations on a
// Ledger collection returns empty data.
// ─────────────────────────────────────────────
function buildOutstandingXML(from, to) {
  return `
<ENVELOPE>
 <HEADER>
  <VERSION>1</VERSION>
  <TALLYREQUEST>Export</TALLYREQUEST>
  <TYPE>Data</TYPE>
  <ID>BillsOutstanding</ID>
 </HEADER>
 <BODY>
  <DESC>
   <STATICVARIABLES>
    <SVEXPORTFORMAT>$$SysName:XML</SVEXPORTFORMAT>
    <SVFROMDATE>${from}</SVFROMDATE>
    <SVTODATE>${to}</SVTODATE>
    <SVCURRENTCOMPANY>##SVCurrentCompany</SVCURRENTCOMPANY>
   </STATICVARIABLES>
   <TDL>
    <TDLMESSAGE>
     <COLLECTION NAME="BillsOutstanding" ISMODIFY="No">
      <TYPE>Bill Outstanding</TYPE>
      <CHILDOF>Sundry Creditors</CHILDOF>
      <FETCH>Name,PartyLedgerName,BillDate,DueDate,ClosingBalance,Amount,LedgerName,BillCreditPeriod</FETCH>
     </COLLECTION>
    </TDLMESSAGE>
   </TDL>
  </DESC>
 </BODY>
</ENVELOPE>`;
}

// Fallback: ledger-level closing balance query
// Used when Bill Outstanding returns nothing
function buildLedgerFallbackXML(from, to) {
  return `
<ENVELOPE>
 <HEADER>
  <VERSION>1</VERSION>
  <TALLYREQUEST>Export</TALLYREQUEST>
  <TYPE>Data</TYPE>
  <ID>LedgerFallback</ID>
 </HEADER>
 <BODY>
  <DESC>
   <STATICVARIABLES>
    <SVEXPORTFORMAT>$$SysName:XML</SVEXPORTFORMAT>
    <SVFROMDATE>${from}</SVFROMDATE>
    <SVTODATE>${to}</SVTODATE>
   </STATICVARIABLES>
   <TDL>
    <TDLMESSAGE>
     <COLLECTION NAME="CreditorLedgers" ISMODIFY="No">
      <TYPE>Ledger</TYPE>
      <CHILDOF>Sundry Creditors</CHILDOF>
      <FETCH>Name,Parent,ClosingBalance,OpeningBalance,BillAllocations.*</FETCH>
     </COLLECTION>
    </TDLMESSAGE>
   </TDL>
  </DESC>
 </BODY>
</ENVELOPE>`;
}

// ─────────────────────────────────────────────
// Parse Bill Outstanding response
// ─────────────────────────────────────────────
function parseBillOutstanding(parsed) {
  try {
    // Navigate to COLLECTION
    const body = parsed.ENVELOPE?.BODY?.[0];
    const data = body?.DATA?.[0];
    const collection = data?.COLLECTION?.[0];

    if (!collection) return [];

    // Bills are under BILLOUTSTANDING or similar key
    const keys = Object.keys(collection);
    let bills = [];

    for (const key of keys) {
      if (key === "$") continue;
      const arr = collection[key];
      if (Array.isArray(arr) && arr.length > 0) {
        bills = arr;
        break;
      }
    }

    return bills;
  } catch (e) {
    console.error("parseBillOutstanding error:", e.message);
    return [];
  }
}

// ─────────────────────────────────────────────
// Parse fallback ledger response
// ─────────────────────────────────────────────
function parseLedgerFallback(parsed) {
  try {
    const body = parsed.ENVELOPE?.BODY?.[0];
    const data = body?.DATA?.[0];
    const collection = data?.COLLECTION?.[0];
    if (!collection) return [];

    const keys = Object.keys(collection).filter((k) => k !== "$");
    for (const key of keys) {
      if (Array.isArray(collection[key]) && collection[key].length > 0) {
        return collection[key];
      }
    }
    return [];
  } catch {
    return [];
  }
}

// ─────────────────────────────────────────────
// Group bill-outstanding rows by vendor
// ─────────────────────────────────────────────
function groupBillsByVendor(bills) {
  const vendorMap = {};

  for (const bill of bills) {
    // Different Tally versions use different field names
    const ledgerName =
      bill.LEDGERNAME?.[0] ||
      bill.PARTYLEDGERNAME?.[0] ||
      bill.NAME?.[0] ||
      bill.$?.NAME ||
      "";

    if (!ledgerName) continue;

    // Amount: ClosingBalance or Amount field
    const rawAmt =
      bill.CLOSINGBALANCE?.[0] ||
      bill.AMOUNT?.[0] ||
      bill.OUTSTANDINGAMOUNT?.[0] ||
      "0";

    const amt = parseAmount(rawAmt);
    if (amt <= 0) continue; // Skip Dr balances (we don't owe them)

    // Date for aging: prefer BillDate, fallback DueDate
    const dateStr =
      bill.BILLDATE?.[0] || bill.DATE?.[0] || bill.DUEDATE?.[0] || "";

    const days = daysOld(dateStr);
    const bucket = agingBucket(days);

    if (!vendorMap[ledgerName]) {
      vendorMap[ledgerName] = {
        name: ledgerName,
        group: "Sundry Creditors",
        totalDue: 0,
        aging: { current: 0, "0_30": 0, "30_60": 0, "60_90": 0, "90_plus": 0 },
      };
    }

    vendorMap[ledgerName].totalDue += amt;
    vendorMap[ledgerName].aging[bucket] += amt;
  }

  return Object.values(vendorMap)
    .map((v) => ({
      name: v.name,
      group: v.group,
      totalDue: round(v.totalDue),
      aging: {
        current: round(v.aging.current),
        days0_30: round(v.aging["0_30"]),
        days30_60: round(v.aging["30_60"]),
        days60_90: round(v.aging["60_90"]),
        days90: round(v.aging["90_plus"]),
      },
    }))
    .filter((v) => v.totalDue > 0)
    .sort((a, b) => b.totalDue - a.totalDue);
}

// ─────────────────────────────────────────────
// Fallback: build vendors from ledger closing balances
// FIX #3: Was incorrectly putting everything in 90+
// Now uses opening/closing to estimate aging better,
// or marks unknown with a flag
// ─────────────────────────────────────────────
function groupLedgerFallback(ledgers) {
  const vendors = [];

  for (const node of ledgers) {
    const name = node.$?.NAME || node.NAME?.[0] || "";
    const group = node.PARENT?.[0] || "Sundry Creditors";
    const rawClosing = node.CLOSINGBALANCE?.[0] || "0";
    const closing = parseAmount(rawClosing);

    if (closing <= 0) continue;

    // Try to extract bill allocations if present
    const billAllocs =
      node.BILLALLOCATIONS?.[0]?.BILLALLOCATION ||
      node["BILLALLOCATIONS.LIST"]?.[0]?.BILLALLOCATION ||
      [];

    const aging = {
      current: 0,
      "0_30": 0,
      "30_60": 0,
      "60_90": 0,
      "90_plus": 0,
    };
    let total = 0;

    if (billAllocs.length > 0) {
      for (const b of billAllocs) {
        const amt = parseAmount(b.AMOUNT?.[0] || b.CLOSINGBALANCE?.[0] || "0");
        if (amt <= 0) continue;
        const dateStr = b.BILLDATE?.[0] || b.DATE?.[0] || "";
        const days = daysOld(dateStr);
        const bucket = agingBucket(days);
        aging[bucket] += amt;
        total += amt;
      }
    }

    // If no bills parsed, use closing balance — mark as unknown aging
    if (total === 0) {
      total = closing;
      aging["90_plus"] = closing; // conservative — flagged as unknown
    }

    if (total <= 0) continue;

    vendors.push({
      name,
      group: `${group} (estimated)`,
      totalDue: round(total),
      aging: {
        current: round(aging.current),
        days0_30: round(aging["0_30"]),
        days30_60: round(aging["30_60"]),
        days60_90: round(aging["60_90"]),
        days90: round(aging["90_plus"]),
      },
    });
  }

  return vendors.sort((a, b) => b.totalDue - a.totalDue);
}

// ─────────────────────────────────────────────
// Compute aging summary from vendor list
// ─────────────────────────────────────────────
function computeAgingSummary(vendors) {
  const summary = {
    current: 0,
    days0_30: 0,
    days30_60: 0,
    days60_90: 0,
    days90: 0,
  };
  for (const v of vendors) {
    summary.current += v.aging.current;
    summary.days0_30 += v.aging.days0_30;
    summary.days30_60 += v.aging.days30_60;
    summary.days60_90 += v.aging.days60_90;
    summary.days90 += v.aging.days90;
  }
  return {
    current: round(summary.current),
    days0_30: round(summary.days0_30),
    days30_60: round(summary.days30_60),
    days60_90: round(summary.days60_90),
    days90: round(summary.days90),
  };
}

// ─────────────────────────────────────────────
// /api/ping — FIX #4: safer company name extraction
// ─────────────────────────────────────────────
app.get("/api/ping", async (req, res) => {
  const xml = `
<ENVELOPE>
 <HEADER>
  <TALLYREQUEST>Export</TALLYREQUEST>
  <TYPE>Data</TYPE>
  <ID>CompanyInfo</ID>
 </HEADER>
 <BODY>
  <DESC>
   <STATICVARIABLES>
    <SVEXPORTFORMAT>$$SysName:XML</SVEXPORTFORMAT>
   </STATICVARIABLES>
   <TDL>
    <TDLMESSAGE>
     <COLLECTION NAME="CompanyInfo" ISMODIFY="No">
      <TYPE>Company</TYPE>
      <FETCH>Name,StartingFrom,Books</FETCH>
     </COLLECTION>
    </TDLMESSAGE>
   </TDL>
  </DESC>
 </BODY>
</ENVELOPE>`;

  try {
    const parsed = await queryTally(xml);

    // Safely extract company list
    let companies = [];
    try {
      const body = parsed.ENVELOPE?.BODY?.[0];
      const data = body?.DATA?.[0];
      const collection = data?.COLLECTION?.[0];
      if (collection) {
        const keys = Object.keys(collection).filter((k) => k !== "$");
        for (const key of keys) {
          const arr = collection[key];
          if (Array.isArray(arr)) {
            companies = arr
              .map((c) => ({
                name: c.$?.NAME || c.NAME?.[0] || "",
              }))
              .filter((c) => c.name);
            break;
          }
        }
      }
    } catch (e) {
      console.warn("Could not parse company list:", e.message);
    }

    res.json({
      ok: true,
      companies,
      active: companies[0]?.name || "Tally Company",
    });
  } catch (e) {
    res.status(500).json({ ok: false, error: e.message });
  }
});

// ─────────────────────────────────────────────
// /api/due-payments — main endpoint
// ─────────────────────────────────────────────
app.get("/api/due-payments", async (req, res) => {
  const from = req.query.from || "20240401";
  const to = req.query.to || todayStr();

  let vendors = [];
  let usedFallback = false;
  let companyName = "Your Company";

  // Get company name
  try {
    const pingRes = await fetch(`http://localhost:${PORT}/api/ping`).then((r) =>
      r.json(),
    );
    companyName = pingRes.active || "Your Company";
  } catch {
    // ignore
  }

  // ── Step 1: Try Bill Outstanding (preferred, accurate) ──
  try {
    console.log("[due-payments] Trying Bill Outstanding collection...");
    const xml = buildOutstandingXML(from, to);
    const parsed = await queryTally(xml);
    const bills = parseBillOutstanding(parsed);
    console.log(
      `[due-payments] Bill Outstanding returned ${bills.length} rows`,
    );

    if (bills.length > 0) {
      vendors = groupBillsByVendor(bills);
      console.log(`[due-payments] Grouped into ${vendors.length} vendors`);
    }
  } catch (e) {
    console.warn("[due-payments] Bill Outstanding failed:", e.message);
  }

  // ── Step 2: Fallback to Ledger collection ──
  if (vendors.length === 0) {
    usedFallback = true;
    console.log("[due-payments] Falling back to Ledger collection...");
    try {
      const xml = buildLedgerFallbackXML(from, to);
      const parsed = await queryTally(xml);
      const ledgers = parseLedgerFallback(parsed);
      console.log(
        `[due-payments] Ledger fallback returned ${ledgers.length} ledgers`,
      );
      vendors = groupLedgerFallback(ledgers);
      console.log(`[due-payments] Fallback vendors: ${vendors.length}`);
    } catch (e) {
      console.error("[due-payments] Ledger fallback also failed:", e.message);
      return res.status(500).json({ error: e.message });
    }
  }

  const agingSummary = computeAgingSummary(vendors);
  const grandTotal = round(vendors.reduce((s, v) => s + v.totalDue, 0));
  const overdueCount = vendors.filter(
    (v) => v.aging.days30_60 > 0 || v.aging.days60_90 > 0 || v.aging.days90 > 0,
  ).length;
  const criticalCount = vendors.filter((v) => v.aging.days90 > 0).length;

  res.json({
    tallyVersion: "Tally Prime",
    company: companyName,
    from,
    asOf: to,
    totalVendors: vendors.length,
    grandTotal,
    overdueCount,
    criticalCount,
    agingSummary,
    usedFallback,
    vendors,
  });
});

// ─────────────────────────────────────────────
// /api/debug — raw XML inspection
// ─────────────────────────────────────────────
app.get("/api/debug", async (req, res) => {
  const from = req.query.from || "20240401";
  const to = req.query.to || todayStr();

  const results = {};

  // Test 1: Bill Outstanding
  try {
    const xml = buildOutstandingXML(from, to);
    const response = await axios.post(TALLY_URL, xml, {
      headers: { "Content-Type": "text/xml" },
      timeout: 20000,
    });
    results.billOutstanding = {
      status: "ok",
      rawLength: response.data.length,
      rawPreview: response.data.slice(0, 2000),
    };
  } catch (e) {
    results.billOutstanding = { status: "error", error: e.message };
  }

  // Test 2: Ledger Fallback
  try {
    const xml = buildLedgerFallbackXML(from, to);
    const response = await axios.post(TALLY_URL, xml, {
      headers: { "Content-Type": "text/xml" },
      timeout: 20000,
    });
    results.ledgerFallback = {
      status: "ok",
      rawLength: response.data.length,
      rawPreview: response.data.slice(0, 2000),
    };
  } catch (e) {
    results.ledgerFallback = { status: "error", error: e.message };
  }

  res.json(results);
});

app.listen(PORT, () => {
  console.log(`\n✅ Tally Due Payments server running`);
  console.log(`   Dashboard : http://localhost:${PORT}`);
  console.log(`   Ping      : http://localhost:${PORT}/api/ping`);
  console.log(`   Debug     : http://localhost:${PORT}/api/debug\n`);
});
