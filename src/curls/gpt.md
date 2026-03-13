Below are the **cURL requests for the main APIs used with** TallyPrime when integrating through the **Tally HTTP XML interface** (usually running on `http://localhost:9000`).

These are the **same APIs typically used in your Node/Express server** for:

* connectivity check
* fetching ledgers
* fetching creditors
* bill-wise outstanding
* stock items (optional)
* voucher data

You can run these directly in **Postman / terminal** to verify if the **XML request and Tally response are correct**.

---

# 1️⃣ Check if Tally is running (Ping)

```bash
curl -X POST http://localhost:9000 \
-H "Content-Type: text/xml" \
-d '
<ENVELOPE>
 <HEADER>
  <TALLYREQUEST>Export</TALLYREQUEST>
 </HEADER>
 <BODY>
  <EXPORTDATA>
   <REQUESTDESC>
    <REPORTNAME>List of Companies</REPORTNAME>
   </REQUESTDESC>
  </EXPORTDATA>
 </BODY>
</ENVELOPE>'
```

Expected response → Company list.

---

# 2️⃣ Fetch all Ledgers

```bash
curl -X POST http://localhost:9000 \
-H "Content-Type: text/xml" \
-d '
<ENVELOPE>
 <HEADER>
  <VERSION>1</VERSION>
  <TALLYREQUEST>Export</TALLYREQUEST>
  <TYPE>Collection</TYPE>
  <ID>Ledger</ID>
 </HEADER>
 <BODY>
  <DESC>
   <STATICVARIABLES>
    <SVEXPORTFORMAT>$$SysName:XML</SVEXPORTFORMAT>
   </STATICVARIABLES>
   <TDL>
    <TDLMESSAGE>
     <COLLECTION NAME="AllLedgers">
      <TYPE>Ledger</TYPE>
      <FETCH>Name,Parent,ClosingBalance</FETCH>
     </COLLECTION>
    </TDLMESSAGE>
   </TDL>
  </DESC>
 </BODY>
</ENVELOPE>'
```

---

# 3️⃣ Fetch **Sundry Creditors (Vendors)**

This is the one typically used for **due payments dashboard**.

```bash
curl -X POST http://localhost:9000 \
-H "Content-Type: text/xml" \
-d '
<ENVELOPE>
 <HEADER>
  <VERSION>1</VERSION>
  <TALLYREQUEST>Export</TALLYREQUEST>
  <TYPE>Collection</TYPE>
  <ID>SundryCreditors</ID>
 </HEADER>
 <BODY>
  <DESC>
   <STATICVARIABLES>
    <SVEXPORTFORMAT>$$SysName:XML</SVEXPORTFORMAT>
   </STATICVARIABLES>
   <TDL>
    <TDLMESSAGE>
     <COLLECTION NAME="SundryCreditors">
      <TYPE>Ledger</TYPE>
      <CHILDOF>Sundry Creditors</CHILDOF>
      <FETCH>Name,ClosingBalance</FETCH>
     </COLLECTION>
    </TDLMESSAGE>
   </TDL>
  </DESC>
 </BODY>
</ENVELOPE>'
```

---

# 4️⃣ Fetch **Bill-wise Outstanding**

This is **most important for aging calculation**.

```bash
curl -X POST http://localhost:9000 \
-H "Content-Type: text/xml" \
-d '
<ENVELOPE>
 <HEADER>
  <VERSION>1</VERSION>
  <TALLYREQUEST>Export</TALLYREQUEST>
  <TYPE>Data</TYPE>
  <ID>Bill-wise Outstandings</ID>
 </HEADER>
 <BODY>
  <DESC>
   <STATICVARIABLES>
    <SVEXPORTFORMAT>$$SysName:XML</SVEXPORTFORMAT>
   </STATICVARIABLES>
  </DESC>
 </BODY>
</ENVELOPE>'
```

Response contains:

```
LEDGERNAME
BILLDATE
BILLTYPE
BILLAMOUNT
AMOUNT
```

This is used for **aging buckets**.

---

# 5️⃣ Fetch Voucher Data (Optional but useful)

```bash
curl -X POST http://localhost:9000 \
-H "Content-Type: text/xml" \
-d '
<ENVELOPE>
 <HEADER>
  <TALLYREQUEST>Export</TALLYREQUEST>
  <TYPE>Collection</TYPE>
  <ID>Voucher</ID>
 </HEADER>
 <BODY>
  <DESC>
   <STATICVARIABLES>
    <SVEXPORTFORMAT>$$SysName:XML</SVEXPORTFORMAT>
   </STATICVARIABLES>
   <TDL>
    <TDLMESSAGE>
     <COLLECTION NAME="AllVouchers">
      <TYPE>Voucher</TYPE>
      <FETCH>Date,VoucherTypeName,PartyLedgerName,Amount</FETCH>
     </COLLECTION>
    </TDLMESSAGE>
   </TDL>
  </DESC>
 </BODY>
</ENVELOPE>'
```

---

# 6️⃣ Fetch Stock Items (Optional)

```bash
curl -X POST http://localhost:9000 \
-H "Content-Type: text/xml" \
-d '
<ENVELOPE>
 <HEADER>
  <TALLYREQUEST>Export</TALLYREQUEST>
  <TYPE>Collection</TYPE>
  <ID>StockItem</ID>
 </HEADER>
 <BODY>
  <DESC>
   <STATICVARIABLES>
    <SVEXPORTFORMAT>$$SysName:XML</SVEXPORTFORMAT>
   </STATICVARIABLES>
   <TDL>
    <TDLMESSAGE>
     <COLLECTION NAME="StockItems">
      <TYPE>StockItem</TYPE>
      <FETCH>Name,ClosingBalance</FETCH>
     </COLLECTION>
    </TDLMESSAGE>
   </TDL>
  </DESC>
 </BODY>
</ENVELOPE>'
```

---

# 7️⃣ Ledger Outstanding (Single Ledger)

```bash
curl -X POST http://localhost:9000 \
-H "Content-Type: text/xml" \
-d '
<ENVELOPE>
 <HEADER>
  <TALLYREQUEST>Export</TALLYREQUEST>
 </HEADER>
 <BODY>
  <EXPORTDATA>
   <REQUESTDESC>
    <REPORTNAME>Ledger Outstanding</REPORTNAME>
    <STATICVARIABLES>
     <LEDGERNAME>ABC Traders</LEDGERNAME>
     <SVEXPORTFORMAT>$$SysName:XML</SVEXPORTFORMAT>
    </STATICVARIABLES>
   </REQUESTDESC>
  </EXPORTDATA>
 </BODY>
</ENVELOPE>'
```

---

# ⚠️ Important Settings in Tally

Inside **TallyPrime enable:

```
F1 → Help
Settings
Connectivity
Enable ODBC / HTTP Server = YES
Port = 9000
```

---

# 👍 Tip for Debugging

If Tally returns **empty XML**, check:

1️⃣ Company is loaded
2️⃣ HTTP server enabled
3️⃣ Correct **ledger group name**

Example:

```
Sundry Creditors
Sundry Debtors
```

Names must match exactly.

---

✅ If you want, I can also give you **one "master curl" that returns all vendors + bill allocations in a single request**, which makes your **Node API 5× faster and simpler**.
