/**
 * Tally Due Payments Dashboard — Backend
 * Run: node server.js
 * Open: http://localhost:3000  (or share http://YOUR-IP:3000 on LAN)
 *
 * Requires Tally to be running with HTTP server enabled on port 9000.
 * Enable in Tally: Gateway of Tally → F12 → Advanced Config → Enable ODBC Server (Port 9000)
 */

const express = require('express');
const axios   = require('axios');
const xml2js  = require('xml2js');
const path    = require('path');

const app        = express();
const TALLY_URL  = 'http://localhost:9000';
const PORT       = process.env.PORT || 3000;

app.use(express.static(path.join(__dirname, 'public')));

// ─── Helpers ────────────────────────────────────────────────────────────────

function buildTallyRequest(reportName, fromDate, toDate, companyName = '') {
  return `
<ENVELOPE>
  <HEADER>
    <TALLYREQUEST>Export Data</TALLYREQUEST>
  </HEADER>
  <BODY>
    <EXPORTDATA>
      <REQUESTDESC>
        <REPORTNAME>${reportName}</REPORTNAME>
        <STATICVARIABLES>
          <SVEXPORTFORMAT>$$SysName:XML</SVEXPORTFORMAT>
          ${fromDate  ? `<SVFROMDATE>${fromDate}</SVFROMDATE>` : ''}
          ${toDate    ? `<SVTODATE>${toDate}</SVTODATE>`       : ''}
          ${companyName ? `<SVCURRENTCOMPANY>${companyName}</SVCURRENTCOMPANY>` : ''}
        </STATICVARIABLES>
      </REQUESTDESC>
    </EXPORTDATA>
  </BODY>
</ENVELOPE>`.trim();
}

async function queryTally(xml) {
  const response = await axios.post(TALLY_URL, xml, {
    headers: { 'Content-Type': 'text/xml' },
    timeout: 15000,
  });
  return xml2js.parseStringPromise(response.data, {
    explicitArray: false,
    ignoreAttrs: false,
    trim: true,
  });
}

function parseAmount(val) {
  if (!val) return 0;
  // Tally amounts can be "1,23,456.78 Dr" or "-12345.67"
  const str = String(val).replace(/,/g, '').replace(/\s*(Dr|Cr)\s*/i, '').trim();
  const num = parseFloat(str) || 0;
  // "Cr" means they owe us (vendor receivable) — negate sign convention
  return /Cr/i.test(String(val)) ? -num : num;
}

function daysBetween(dateStr) {
  // Tally date format: YYYYMMDD
  if (!dateStr || dateStr.length < 8) return 0;
  const y = parseInt(dateStr.slice(0, 4));
  const m = parseInt(dateStr.slice(4, 6)) - 1;
  const d = parseInt(dateStr.slice(6, 8));
  const then = new Date(y, m, d);
  const now  = new Date();
  return Math.floor((now - then) / 86400000);
}

function agingBucket(days) {
  if (days <= 0)  return 'current';
  if (days <= 30) return '0_30';
  if (days <= 60) return '30_60';
  if (days <= 90) return '60_90';
  return '90_plus';
}

// ─── API: Ping Tally ─────────────────────────────────────────────────────────

app.get('/api/ping', async (req, res) => {
  try {
    const xml = `<ENVELOPE><HEADER><TALLYREQUEST>Export Data</TALLYREQUEST></HEADER>
    <BODY><EXPORTDATA><REQUESTDESC><REPORTNAME>List of Companies</REPORTNAME></REQUESTDESC></EXPORTDATA></BODY></ENVELOPE>`;
    await axios.post(TALLY_URL, xml, { timeout: 5000 });
    res.json({ ok: true, message: 'Tally is running' });
  } catch {
    res.status(503).json({ ok: false, message: 'Cannot reach Tally on port 9000. Is Tally open with HTTP server enabled?' });
  }
});

// ─── API: Due Payments ───────────────────────────────────────────────────────

app.get('/api/due-payments', async (req, res) => {
  try {
    const today = new Date();
    const fmt   = d => `${d.getFullYear()}${String(d.getMonth()+1).padStart(2,'0')}${String(d.getDate()).padStart(2,'0')}`;
    const from  = req.query.from || '20240401'; // default: start of FY
    const to    = req.query.to   || fmt(today);

    // Ledger Outstanding — gives bill-by-bill outstanding per ledger
    const xml    = buildTallyRequest('Ledger Outstanding', from, to);
    const parsed = await queryTally(xml);

    const envelope = parsed.ENVELOPE || {};
    const body     = envelope.BODY   || {};
    const data     = body.DATA       || {};

    // Tally XML structure: ENVELOPE > BODY > DATA > TALLYMESSAGE > LEDGER[]
    let ledgers = data.TALLYMESSAGE
      ? [].concat(data.TALLYMESSAGE)
      : [];

    // Also handle COLLECTION structure
    if (!ledgers.length && data.COLLECTION) {
      ledgers = [].concat(data.COLLECTION.LEDGER || []);
    }

    const vendors = [];

    for (const msg of ledgers) {
      const ledger = msg.LEDGER || msg;
      if (!ledger) continue;

      const name    = ledger['$']?.NAME || ledger.NAME || '';
      const group   = ledger.PARENT || '';
      const closing = parseAmount(ledger.CLOSINGBALANCE || ledger.OPENINGBALANCE);

      // Only include payable ledgers (creditors / suppliers)
      const isPayable = /creditor|supplier|vendor|payable|purchase/i.test(group) ||
                        /creditor|supplier|vendor|payable|purchase/i.test(name);
      if (!isPayable && !req.query.all) continue;

      // Bill-level outstanding
      const bills = [].concat(ledger.BILLALLOCATIONS?.BILLALLOCATION || []);
      const aging = { current: 0, '0_30': 0, '30_60': 0, '60_90': 0, '90_plus': 0 };
      let totalDue = 0;

      for (const bill of bills) {
        const amt  = parseAmount(bill.AMOUNT);
        const days = daysBetween(bill.BILLDATE);
        if (amt > 0) {
          totalDue += amt;
          aging[agingBucket(days)] += amt;
        }
      }

      // Fall back to closing balance if no bill detail
      if (bills.length === 0 && closing > 0) {
        totalDue = closing;
        aging['90_plus'] = closing;
      }

      if (totalDue > 0) {
        vendors.push({
          name,
          group,
          totalDue: Math.round(totalDue * 100) / 100,
          aging: {
            current:  Math.round(aging.current  * 100) / 100,
            days0_30: Math.round(aging['0_30']  * 100) / 100,
            days30_60:Math.round(aging['30_60'] * 100) / 100,
            days60_90:Math.round(aging['60_90'] * 100) / 100,
            days90:   Math.round(aging['90_plus']* 100) / 100,
          }
        });
      }
    }

    // Sort by totalDue desc
    vendors.sort((a, b) => b.totalDue - a.totalDue);

    const grandTotal   = vendors.reduce((s, v) => s + v.totalDue, 0);
    const overdueCount = vendors.filter(v => (v.aging.days0_30 + v.aging.days30_60 + v.aging.days60_90 + v.aging.days90) > 0).length;
    const criticalCount= vendors.filter(v => v.aging.days90 > 0).length;
    const agingSummary = vendors.reduce((acc, v) => {
      acc.current   += v.aging.current;
      acc.days0_30  += v.aging.days0_30;
      acc.days30_60 += v.aging.days30_60;
      acc.days60_90 += v.aging.days60_90;
      acc.days90    += v.aging.days90;
      return acc;
    }, { current: 0, days0_30: 0, days30_60: 0, days60_90: 0, days90: 0 });

    res.json({
      asOf: to,
      from,
      grandTotal:    Math.round(grandTotal * 100) / 100,
      totalVendors:  vendors.length,
      overdueCount,
      criticalCount,
      agingSummary,
      vendors,
    });

  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

// ─── Start ───────────────────────────────────────────────────────────────────

app.listen(PORT, '0.0.0.0', () => {
  console.log(`\n✅ Tally Dashboard running`);
  console.log(`   Local:   http://localhost:${PORT}`);
  console.log(`   Network: http://<YOUR-IP>:${PORT}  ← share this with your team\n`);
});
