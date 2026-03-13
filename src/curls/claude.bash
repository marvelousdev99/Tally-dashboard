#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
#  TALLY PRIME — Complete cURL Reference
#  All requests go to http://localhost:9000
#  Content-Type must always be: text/xml
#  Replace YOUR-IP if calling from another machine on LAN
# ═══════════════════════════════════════════════════════════════════════════════

TALLY="http://localhost:9000"
# TALLY="http://192.168.1.100:9000"   # ← use this for LAN access


# ───────────────────────────────────────────────────────────────────────────────
# 1. PING — Check if Tally is running
# ───────────────────────────────────────────────────────────────────────────────
curl -s -X POST "$TALLY" \
  -H "Content-Type: text/xml" \
  -d '<ENVELOPE>
  <HEADER><TALLYREQUEST>Export Data</TALLYREQUEST></HEADER>
  <BODY>
    <EXPORTDATA>
      <REQUESTDESC>
        <REPORTNAME>List of Companies</REPORTNAME>
        <STATICVARIABLES>
          <SVEXPORTFORMAT>$$SysName:XML</SVEXPORTFORMAT>
        </STATICVARIABLES>
      </REQUESTDESC>
    </EXPORTDATA>
  </BODY>
</ENVELOPE>'


# ───────────────────────────────────────────────────────────────────────────────
# 2. LIST OF COMPANIES — All companies loaded in Tally
# ───────────────────────────────────────────────────────────────────────────────
curl -s -X POST "$TALLY" \
  -H "Content-Type: text/xml" \
  -d '<ENVELOPE>
  <HEADER><TALLYREQUEST>Export Data</TALLYREQUEST></HEADER>
  <BODY>
    <EXPORTDATA>
      <REQUESTDESC>
        <REPORTNAME>List of Companies</REPORTNAME>
        <STATICVARIABLES>
          <SVEXPORTFORMAT>$$SysName:XML</SVEXPORTFORMAT>
        </STATICVARIABLES>
      </REQUESTDESC>
    </EXPORTDATA>
  </BODY>
</ENVELOPE>'


# ───────────────────────────────────────────────────────────────────────────────
# 3. LEDGER OUTSTANDING — Due payments for all ledgers (Tally Prime)
#    Replace SVFROMDATE / SVTODATE with your FY range: YYYYMMDD
# ───────────────────────────────────────────────────────────────────────────────
curl -s -X POST "$TALLY" \
  -H "Content-Type: text/xml" \
  -d '<ENVELOPE>
  <HEADER><TALLYREQUEST>Export Data</TALLYREQUEST></HEADER>
  <BODY>
    <EXPORTDATA>
      <REQUESTDESC>
        <REPORTNAME>Ledger Outstanding</REPORTNAME>
        <STATICVARIABLES>
          <SVEXPORTFORMAT>$$SysName:XML</SVEXPORTFORMAT>
          <SVFROMDATE>20240401</SVFROMDATE>
          <SVTODATE>20241231</SVTODATE>
        </STATICVARIABLES>
      </REQUESTDESC>
    </EXPORTDATA>
  </BODY>
</ENVELOPE>'


# ───────────────────────────────────────────────────────────────────────────────
# 4. LEDGER OUTSTANDING — for a specific company (multi-company setup)
#    Replace "Your Company Name" with exact name from Tally
# ───────────────────────────────────────────────────────────────────────────────
curl -s -X POST "$TALLY" \
  -H "Content-Type: text/xml" \
  -d '<ENVELOPE>
  <HEADER><TALLYREQUEST>Export Data</TALLYREQUEST></HEADER>
  <BODY>
    <EXPORTDATA>
      <REQUESTDESC>
        <REPORTNAME>Ledger Outstanding</REPORTNAME>
        <STATICVARIABLES>
          <SVEXPORTFORMAT>$$SysName:XML</SVEXPORTFORMAT>
          <SVFROMDATE>20240401</SVFROMDATE>
          <SVTODATE>20241231</SVTODATE>
          <SVCURRENTCOMPANY>Your Company Name</SVCURRENTCOMPANY>
        </STATICVARIABLES>
      </REQUESTDESC>
    </EXPORTDATA>
  </BODY>
</ENVELOPE>'


# ───────────────────────────────────────────────────────────────────────────────
# 5. LIST OF ALL LEDGERS — Every ledger with group/parent info
# ───────────────────────────────────────────────────────────────────────────────
curl -s -X POST "$TALLY" \
  -H "Content-Type: text/xml" \
  -d '<ENVELOPE>
  <HEADER><TALLYREQUEST>Export Data</TALLYREQUEST></HEADER>
  <BODY>
    <EXPORTDATA>
      <REQUESTDESC>
        <REPORTNAME>List of Accounts</REPORTNAME>
        <STATICVARIABLES>
          <SVEXPORTFORMAT>$$SysName:XML</SVEXPORTFORMAT>
          <ACCOUNTTYPE>Ledgers</ACCOUNTTYPE>
        </STATICVARIABLES>
      </REQUESTDESC>
    </EXPORTDATA>
  </BODY>
</ENVELOPE>'


# ───────────────────────────────────────────────────────────────────────────────
# 6. LIST OF LEDGERS — with closing balance + bill allocations (Tally Prime FETCH syntax)
# ───────────────────────────────────────────────────────────────────────────────
curl -s -X POST "$TALLY" \
  -H "Content-Type: text/xml" \
  -d '<ENVELOPE>
  <HEADER><TALLYREQUEST>Export Data</TALLYREQUEST></HEADER>
  <BODY>
    <EXPORTDATA>
      <REQUESTDESC>
        <REPORTNAME>List of Accounts</REPORTNAME>
        <STATICVARIABLES>
          <SVEXPORTFORMAT>$$SysName:XML</SVEXPORTFORMAT>
          <SVFROMDATE>20240401</SVFROMDATE>
          <SVTODATE>20241231</SVTODATE>
          <ACCOUNTTYPE>Ledgers</ACCOUNTTYPE>
        </STATICVARIABLES>
        <FETCHLIST>
          <FETCH>NAME</FETCH>
          <FETCH>PARENT</FETCH>
          <FETCH>CLOSINGBALANCE</FETCH>
          <FETCH>OPENINGBALANCE</FETCH>
          <FETCH>BILLALLOCATIONS.LIST</FETCH>
        </FETCHLIST>
      </REQUESTDESC>
    </EXPORTDATA>
  </BODY>
</ENVELOPE>'


# ───────────────────────────────────────────────────────────────────────────────
# 7. SUNDRY CREDITORS — Only vendor/supplier ledgers (payables)
# ───────────────────────────────────────────────────────────────────────────────
curl -s -X POST "$TALLY" \
  -H "Content-Type: text/xml" \
  -d '<ENVELOPE>
  <HEADER><TALLYREQUEST>Export Data</TALLYREQUEST></HEADER>
  <BODY>
    <EXPORTDATA>
      <REQUESTDESC>
        <REPORTNAME>List of Accounts</REPORTNAME>
        <STATICVARIABLES>
          <SVEXPORTFORMAT>$$SysName:XML</SVEXPORTFORMAT>
          <SVFROMDATE>20240401</SVFROMDATE>
          <SVTODATE>20241231</SVTODATE>
          <ACCOUNTTYPE>Ledgers</ACCOUNTTYPE>
          <SVLEDGERGROUPNAME>Sundry Creditors</SVLEDGERGROUPNAME>
        </STATICVARIABLES>
      </REQUESTDESC>
    </EXPORTDATA>
  </BODY>
</ENVELOPE>'


# ───────────────────────────────────────────────────────────────────────────────
# 8. SUNDRY DEBTORS — Customer/receivables ledgers
# ───────────────────────────────────────────────────────────────────────────────
curl -s -X POST "$TALLY" \
  -H "Content-Type: text/xml" \
  -d '<ENVELOPE>
  <HEADER><TALLYREQUEST>Export Data</TALLYREQUEST></HEADER>
  <BODY>
    <EXPORTDATA>
      <REQUESTDESC>
        <REPORTNAME>List of Accounts</REPORTNAME>
        <STATICVARIABLES>
          <SVEXPORTFORMAT>$$SysName:XML</SVEXPORTFORMAT>
          <SVFROMDATE>20240401</SVFROMDATE>
          <SVTODATE>20241231</SVTODATE>
          <ACCOUNTTYPE>Ledgers</ACCOUNTTYPE>
          <SVLEDGERGROUPNAME>Sundry Debtors</SVLEDGERGROUPNAME>
        </STATICVARIABLES>
      </REQUESTDESC>
    </EXPORTDATA>
  </BODY>
</ENVELOPE>'


# ───────────────────────────────────────────────────────────────────────────────
# 9. TRIAL BALANCE
# ───────────────────────────────────────────────────────────────────────────────
curl -s -X POST "$TALLY" \
  -H "Content-Type: text/xml" \
  -d '<ENVELOPE>
  <HEADER><TALLYREQUEST>Export Data</TALLYREQUEST></HEADER>
  <BODY>
    <EXPORTDATA>
      <REQUESTDESC>
        <REPORTNAME>Trial Balance</REPORTNAME>
        <STATICVARIABLES>
          <SVEXPORTFORMAT>$$SysName:XML</SVEXPORTFORMAT>
          <SVFROMDATE>20240401</SVFROMDATE>
          <SVTODATE>20241231</SVTODATE>
        </STATICVARIABLES>
      </REQUESTDESC>
    </EXPORTDATA>
  </BODY>
</ENVELOPE>'


# ───────────────────────────────────────────────────────────────────────────────
# 10. PROFIT & LOSS
# ───────────────────────────────────────────────────────────────────────────────
curl -s -X POST "$TALLY" \
  -H "Content-Type: text/xml" \
  -d '<ENVELOPE>
  <HEADER><TALLYREQUEST>Export Data</TALLYREQUEST></HEADER>
  <BODY>
    <EXPORTDATA>
      <REQUESTDESC>
        <REPORTNAME>Profit and Loss</REPORTNAME>
        <STATICVARIABLES>
          <SVEXPORTFORMAT>$$SysName:XML</SVEXPORTFORMAT>
          <SVFROMDATE>20240401</SVFROMDATE>
          <SVTODATE>20241231</SVTODATE>
        </STATICVARIABLES>
      </REQUESTDESC>
    </EXPORTDATA>
  </BODY>
</ENVELOPE>'


# ───────────────────────────────────────────────────────────────────────────────
# 11. BALANCE SHEET
# ───────────────────────────────────────────────────────────────────────────────
curl -s -X POST "$TALLY" \
  -H "Content-Type: text/xml" \
  -d '<ENVELOPE>
  <HEADER><TALLYREQUEST>Export Data</TALLYREQUEST></HEADER>
  <BODY>
    <EXPORTDATA>
      <REQUESTDESC>
        <REPORTNAME>Balance Sheet</REPORTNAME>
        <STATICVARIABLES>
          <SVEXPORTFORMAT>$$SysName:XML</SVEXPORTFORMAT>
          <SVFROMDATE>20240401</SVFROMDATE>
          <SVTODATE>20241231</SVTODATE>
        </STATICVARIABLES>
      </REQUESTDESC>
    </EXPORTDATA>
  </BODY>
</ENVELOPE>'


# ───────────────────────────────────────────────────────────────────────────────
# 12. CASH FLOW STATEMENT
# ───────────────────────────────────────────────────────────────────────────────
curl -s -X POST "$TALLY" \
  -H "Content-Type: text/xml" \
  -d '<ENVELOPE>
  <HEADER><TALLYREQUEST>Export Data</TALLYREQUEST></HEADER>
  <BODY>
    <EXPORTDATA>
      <REQUESTDESC>
        <REPORTNAME>Cash Flow</REPORTNAME>
        <STATICVARIABLES>
          <SVEXPORTFORMAT>$$SysName:XML</SVEXPORTFORMAT>
          <SVFROMDATE>20240401</SVFROMDATE>
          <SVTODATE>20241231</SVTODATE>
        </STATICVARIABLES>
      </REQUESTDESC>
    </EXPORTDATA>
  </BODY>
</ENVELOPE>'


# ───────────────────────────────────────────────────────────────────────────────
# 13. DAY BOOK — All vouchers for a date range
# ───────────────────────────────────────────────────────────────────────────────
curl -s -X POST "$TALLY" \
  -H "Content-Type: text/xml" \
  -d '<ENVELOPE>
  <HEADER><TALLYREQUEST>Export Data</TALLYREQUEST></HEADER>
  <BODY>
    <EXPORTDATA>
      <REQUESTDESC>
        <REPORTNAME>Day Book</REPORTNAME>
        <STATICVARIABLES>
          <SVEXPORTFORMAT>$$SysName:XML</SVEXPORTFORMAT>
          <SVFROMDATE>20241201</SVFROMDATE>
          <SVTODATE>20241231</SVTODATE>
        </STATICVARIABLES>
      </REQUESTDESC>
    </EXPORTDATA>
  </BODY>
</ENVELOPE>'


# ───────────────────────────────────────────────────────────────────────────────
# 14. VOUCHER LIST — Purchase vouchers only
#    Types: Purchase, Sales, Payment, Receipt, Journal, Contra, Credit Note, Debit Note
# ───────────────────────────────────────────────────────────────────────────────
curl -s -X POST "$TALLY" \
  -H "Content-Type: text/xml" \
  -d '<ENVELOPE>
  <HEADER><TALLYREQUEST>Export Data</TALLYREQUEST></HEADER>
  <BODY>
    <EXPORTDATA>
      <REQUESTDESC>
        <REPORTNAME>Day Book</REPORTNAME>
        <STATICVARIABLES>
          <SVEXPORTFORMAT>$$SysName:XML</SVEXPORTFORMAT>
          <SVFROMDATE>20240401</SVFROMDATE>
          <SVTODATE>20241231</SVTODATE>
          <VOUCHERTYPENAME>Purchase</VOUCHERTYPENAME>
        </STATICVARIABLES>
      </REQUESTDESC>
    </EXPORTDATA>
  </BODY>
</ENVELOPE>'


# ───────────────────────────────────────────────────────────────────────────────
# 15. SALES VOUCHERS
# ───────────────────────────────────────────────────────────────────────────────
curl -s -X POST "$TALLY" \
  -H "Content-Type: text/xml" \
  -d '<ENVELOPE>
  <HEADER><TALLYREQUEST>Export Data</TALLYREQUEST></HEADER>
  <BODY>
    <EXPORTDATA>
      <REQUESTDESC>
        <REPORTNAME>Day Book</REPORTNAME>
        <STATICVARIABLES>
          <SVEXPORTFORMAT>$$SysName:XML</SVEXPORTFORMAT>
          <SVFROMDATE>20240401</SVFROMDATE>
          <SVTODATE>20241231</SVTODATE>
          <VOUCHERTYPENAME>Sales</VOUCHERTYPENAME>
        </STATICVARIABLES>
      </REQUESTDESC>
    </EXPORTDATA>
  </BODY>
</ENVELOPE>'


# ───────────────────────────────────────────────────────────────────────────────
# 16. PAYMENT VOUCHERS
# ───────────────────────────────────────────────────────────────────────────────
curl -s -X POST "$TALLY" \
  -H "Content-Type: text/xml" \
  -d '<ENVELOPE>
  <HEADER><TALLYREQUEST>Export Data</TALLYREQUEST></HEADER>
  <BODY>
    <EXPORTDATA>
      <REQUESTDESC>
        <REPORTNAME>Day Book</REPORTNAME>
        <STATICVARIABLES>
          <SVEXPORTFORMAT>$$SysName:XML</SVEXPORTFORMAT>
          <SVFROMDATE>20240401</SVFROMDATE>
          <SVTODATE>20241231</SVTODATE>
          <VOUCHERTYPENAME>Payment</VOUCHERTYPENAME>
        </STATICVARIABLES>
      </REQUESTDESC>
    </EXPORTDATA>
  </BODY>
</ENVELOPE>'


# ───────────────────────────────────────────────────────────────────────────────
# 17. RECEIPT VOUCHERS
# ───────────────────────────────────────────────────────────────────────────────
curl -s -X POST "$TALLY" \
  -H "Content-Type: text/xml" \
  -d '<ENVELOPE>
  <HEADER><TALLYREQUEST>Export Data</TALLYREQUEST></HEADER>
  <BODY>
    <EXPORTDATA>
      <REQUESTDESC>
        <REPORTNAME>Day Book</REPORTNAME>
        <STATICVARIABLES>
          <SVEXPORTFORMAT>$$SysName:XML</SVEXPORTFORMAT>
          <SVFROMDATE>20240401</SVFROMDATE>
          <SVTODATE>20241231</SVTODATE>
          <VOUCHERTYPENAME>Receipt</VOUCHERTYPENAME>
        </STATICVARIABLES>
      </REQUESTDESC>
    </EXPORTDATA>
  </BODY>
</ENVELOPE>'


# ───────────────────────────────────────────────────────────────────────────────
# 18. STOCK SUMMARY — Inventory positions
# ───────────────────────────────────────────────────────────────────────────────
curl -s -X POST "$TALLY" \
  -H "Content-Type: text/xml" \
  -d '<ENVELOPE>
  <HEADER><TALLYREQUEST>Export Data</TALLYREQUEST></HEADER>
  <BODY>
    <EXPORTDATA>
      <REQUESTDESC>
        <REPORTNAME>Stock Summary</REPORTNAME>
        <STATICVARIABLES>
          <SVEXPORTFORMAT>$$SysName:XML</SVEXPORTFORMAT>
          <SVFROMDATE>20240401</SVFROMDATE>
          <SVTODATE>20241231</SVTODATE>
        </STATICVARIABLES>
      </REQUESTDESC>
    </EXPORTDATA>
  </BODY>
</ENVELOPE>'


# ───────────────────────────────────────────────────────────────────────────────
# 19. STOCK ITEMS — List of all inventory items
# ───────────────────────────────────────────────────────────────────────────────
curl -s -X POST "$TALLY" \
  -H "Content-Type: text/xml" \
  -d '<ENVELOPE>
  <HEADER><TALLYREQUEST>Export Data</TALLYREQUEST></HEADER>
  <BODY>
    <EXPORTDATA>
      <REQUESTDESC>
        <REPORTNAME>List of Accounts</REPORTNAME>
        <STATICVARIABLES>
          <SVEXPORTFORMAT>$$SysName:XML</SVEXPORTFORMAT>
          <ACCOUNTTYPE>Stock Items</ACCOUNTTYPE>
        </STATICVARIABLES>
      </REQUESTDESC>
    </EXPORTDATA>
  </BODY>
</ENVELOPE>'


# ───────────────────────────────────────────────────────────────────────────────
# 20. GODOWN SUMMARY — Stock by warehouse/godown
# ───────────────────────────────────────────────────────────────────────────────
curl -s -X POST "$TALLY" \
  -H "Content-Type: text/xml" \
  -d '<ENVELOPE>
  <HEADER><TALLYREQUEST>Export Data</TALLYREQUEST></HEADER>
  <BODY>
    <EXPORTDATA>
      <REQUESTDESC>
        <REPORTNAME>Godown Summary</REPORTNAME>
        <STATICVARIABLES>
          <SVEXPORTFORMAT>$$SysName:XML</SVEXPORTFORMAT>
          <SVFROMDATE>20240401</SVFROMDATE>
          <SVTODATE>20241231</SVTODATE>
        </STATICVARIABLES>
      </REQUESTDESC>
    </EXPORTDATA>
  </BODY>
</ENVELOPE>'


# ───────────────────────────────────────────────────────────────────────────────
# 21. ACCOUNTS RECEIVABLE AGEING — Customer dues (Debtors)
# ───────────────────────────────────────────────────────────────────────────────
curl -s -X POST "$TALLY" \
  -H "Content-Type: text/xml" \
  -d '<ENVELOPE>
  <HEADER><TALLYREQUEST>Export Data</TALLYREQUEST></HEADER>
  <BODY>
    <EXPORTDATA>
      <REQUESTDESC>
        <REPORTNAME>Bills Receivable</REPORTNAME>
        <STATICVARIABLES>
          <SVEXPORTFORMAT>$$SysName:XML</SVEXPORTFORMAT>
          <SVFROMDATE>20240401</SVFROMDATE>
          <SVTODATE>20241231</SVTODATE>
        </STATICVARIABLES>
      </REQUESTDESC>
    </EXPORTDATA>
  </BODY>
</ENVELOPE>'


# ───────────────────────────────────────────────────────────────────────────────
# 22. ACCOUNTS PAYABLE AGEING — Vendor dues (Creditors)
# ───────────────────────────────────────────────────────────────────────────────
curl -s -X POST "$TALLY" \
  -H "Content-Type: text/xml" \
  -d '<ENVELOPE>
  <HEADER><TALLYREQUEST>Export Data</TALLYREQUEST></HEADER>
  <BODY>
    <EXPORTDATA>
      <REQUESTDESC>
        <REPORTNAME>Bills Payable</REPORTNAME>
        <STATICVARIABLES>
          <SVEXPORTFORMAT>$$SysName:XML</SVEXPORTFORMAT>
          <SVFROMDATE>20240401</SVFROMDATE>
          <SVTODATE>20241231</SVTODATE>
        </STATICVARIABLES>
      </REQUESTDESC>
    </EXPORTDATA>
  </BODY>
</ENVELOPE>'


# ───────────────────────────────────────────────────────────────────────────────
# 23. GST SALES REGISTER
# ───────────────────────────────────────────────────────────────────────────────
curl -s -X POST "$TALLY" \
  -H "Content-Type: text/xml" \
  -d '<ENVELOPE>
  <HEADER><TALLYREQUEST>Export Data</TALLYREQUEST></HEADER>
  <BODY>
    <EXPORTDATA>
      <REQUESTDESC>
        <REPORTNAME>GST Sales Register</REPORTNAME>
        <STATICVARIABLES>
          <SVEXPORTFORMAT>$$SysName:XML</SVEXPORTFORMAT>
          <SVFROMDATE>20240401</SVFROMDATE>
          <SVTODATE>20241231</SVTODATE>
        </STATICVARIABLES>
      </REQUESTDESC>
    </EXPORTDATA>
  </BODY>
</ENVELOPE>'


# ───────────────────────────────────────────────────────────────────────────────
# 24. GST PURCHASE REGISTER
# ───────────────────────────────────────────────────────────────────────────────
curl -s -X POST "$TALLY" \
  -H "Content-Type: text/xml" \
  -d '<ENVELOPE>
  <HEADER><TALLYREQUEST>Export Data</TALLYREQUEST></HEADER>
  <BODY>
    <EXPORTDATA>
      <REQUESTDESC>
        <REPORTNAME>GST Purchase Register</REPORTNAME>
        <STATICVARIABLES>
          <SVEXPORTFORMAT>$$SysName:XML</SVEXPORTFORMAT>
          <SVFROMDATE>20240401</SVFROMDATE>
          <SVTODATE>20241231</SVTODATE>
        </STATICVARIABLES>
      </REQUESTDESC>
    </EXPORTDATA>
  </BODY>
</ENVELOPE>'


# ───────────────────────────────────────────────────────────────────────────────
# 25. GSTR-1 SUMMARY
# ───────────────────────────────────────────────────────────────────────────────
curl -s -X POST "$TALLY" \
  -H "Content-Type: text/xml" \
  -d '<ENVELOPE>
  <HEADER><TALLYREQUEST>Export Data</TALLYREQUEST></HEADER>
  <BODY>
    <EXPORTDATA>
      <REQUESTDESC>
        <REPORTNAME>GSTR-1</REPORTNAME>
        <STATICVARIABLES>
          <SVEXPORTFORMAT>$$SysName:XML</SVEXPORTFORMAT>
          <SVFROMDATE>20241101</SVFROMDATE>
          <SVTODATE>20241130</SVTODATE>
        </STATICVARIABLES>
      </REQUESTDESC>
    </EXPORTDATA>
  </BODY>
</ENVELOPE>'


# ───────────────────────────────────────────────────────────────────────────────
# 26. GSTR-2 / GSTR-3B SUMMARY
# ───────────────────────────────────────────────────────────────────────────────
curl -s -X POST "$TALLY" \
  -H "Content-Type: text/xml" \
  -d '<ENVELOPE>
  <HEADER><TALLYREQUEST>Export Data</TALLYREQUEST></HEADER>
  <BODY>
    <EXPORTDATA>
      <REQUESTDESC>
        <REPORTNAME>GSTR-3B</REPORTNAME>
        <STATICVARIABLES>
          <SVEXPORTFORMAT>$$SysName:XML</SVEXPORTFORMAT>
          <SVFROMDATE>20241101</SVFROMDATE>
          <SVTODATE>20241130</SVTODATE>
        </STATICVARIABLES>
      </REQUESTDESC>
    </EXPORTDATA>
  </BODY>
</ENVELOPE>'


# ───────────────────────────────────────────────────────────────────────────────
# 27. COST CENTRE SUMMARY
# ───────────────────────────────────────────────────────────────────────────────
curl -s -X POST "$TALLY" \
  -H "Content-Type: text/xml" \
  -d '<ENVELOPE>
  <HEADER><TALLYREQUEST>Export Data</TALLYREQUEST></HEADER>
  <BODY>
    <EXPORTDATA>
      <REQUESTDESC>
        <REPORTNAME>Cost Centre Summary</REPORTNAME>
        <STATICVARIABLES>
          <SVEXPORTFORMAT>$$SysName:XML</SVEXPORTFORMAT>
          <SVFROMDATE>20240401</SVFROMDATE>
          <SVTODATE>20241231</SVTODATE>
        </STATICVARIABLES>
      </REQUESTDESC>
    </EXPORTDATA>
  </BODY>
</ENVELOPE>'


# ───────────────────────────────────────────────────────────────────────────────
# 28. BUDGET VARIANCE
# ───────────────────────────────────────────────────────────────────────────────
curl -s -X POST "$TALLY" \
  -H "Content-Type: text/xml" \
  -d '<ENVELOPE>
  <HEADER><TALLYREQUEST>Export Data</TALLYREQUEST></HEADER>
  <BODY>
    <EXPORTDATA>
      <REQUESTDESC>
        <REPORTNAME>Budget Variance</REPORTNAME>
        <STATICVARIABLES>
          <SVEXPORTFORMAT>$$SysName:XML</SVEXPORTFORMAT>
          <SVFROMDATE>20240401</SVFROMDATE>
          <SVTODATE>20241231</SVTODATE>
        </STATICVARIABLES>
      </REQUESTDESC>
    </EXPORTDATA>
  </BODY>
</ENVELOPE>'


# ───────────────────────────────────────────────────────────────────────────────
# 29. CREATE / INSERT A VOUCHER — Payment voucher (POST data to Tally)
#    This writes data INTO Tally — use carefully
# ───────────────────────────────────────────────────────────────────────────────
curl -s -X POST "$TALLY" \
  -H "Content-Type: text/xml" \
  -d '<ENVELOPE>
  <HEADER>
    <TALLYREQUEST>Import Data</TALLYREQUEST>
  </HEADER>
  <BODY>
    <IMPORTDATA>
      <REQUESTDESC>
        <REPORTNAME>Vouchers</REPORTNAME>
        <STATICVARIABLES>
          <SVCURRENTCOMPANY>Your Company Name</SVCURRENTCOMPANY>
        </STATICVARIABLES>
      </REQUESTDESC>
      <REQUESTDATA>
        <TALLYMESSAGE xmlns:UDF="TallyUDF">
          <VOUCHER REMOTEID="PAY-001" VCHTYPE="Payment" ACTION="Create">
            <DATE>20241215</DATE>
            <VOUCHERTYPENAME>Payment</VOUCHERTYPENAME>
            <VOUCHERNUMBER>PAY-001</VOUCHERNUMBER>
            <PARTYLEDGERNAME>Vendor ABC</PARTYLEDGERNAME>
            <ALLLEDGERENTRIES.LIST>
              <LEDGERNAME>Vendor ABC</LEDGERNAME>
              <ISDEEMEDPOSITIVE>No</ISDEEMEDPOSITIVE>
              <AMOUNT>-50000</AMOUNT>
            </ALLLEDGERENTRIES.LIST>
            <ALLLEDGERENTRIES.LIST>
              <LEDGERNAME>Bank Account</LEDGERNAME>
              <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>
              <AMOUNT>50000</AMOUNT>
            </ALLLEDGERENTRIES.LIST>
          </VOUCHER>
        </TALLYMESSAGE>
      </REQUESTDATA>
    </IMPORTDATA>
  </BODY>
</ENVELOPE>'


# ───────────────────────────────────────────────────────────────────────────────
# 30. GET A SINGLE LEDGER — Detailed info for one specific ledger
#    Replace LEDGERNAME value with your ledger
# ───────────────────────────────────────────────────────────────────────────────
curl -s -X POST "$TALLY" \
  -H "Content-Type: text/xml" \
  -d '<ENVELOPE>
  <HEADER><TALLYREQUEST>Export Data</TALLYREQUEST></HEADER>
  <BODY>
    <EXPORTDATA>
      <REQUESTDESC>
        <REPORTNAME>Ledger Vouchers</REPORTNAME>
        <STATICVARIABLES>
          <SVEXPORTFORMAT>$$SysName:XML</SVEXPORTFORMAT>
          <SVFROMDATE>20240401</SVFROMDATE>
          <SVTODATE>20241231</SVTODATE>
          <LEDGERNAME>Vendor ABC</LEDGERNAME>
        </STATICVARIABLES>
      </REQUESTDESC>
    </EXPORTDATA>
  </BODY>
</ENVELOPE>'


# ───────────────────────────────────────────────────────────────────────────────
# 31. GROUP SUMMARY — Summary for a specific account group
# ───────────────────────────────────────────────────────────────────────────────
curl -s -X POST "$TALLY" \
  -H "Content-Type: text/xml" \
  -d '<ENVELOPE>
  <HEADER><TALLYREQUEST>Export Data</TALLYREQUEST></HEADER>
  <BODY>
    <EXPORTDATA>
      <REQUESTDESC>
        <REPORTNAME>Group Summary</REPORTNAME>
        <STATICVARIABLES>
          <SVEXPORTFORMAT>$$SysName:XML</SVEXPORTFORMAT>
          <SVFROMDATE>20240401</SVFROMDATE>
          <SVTODATE>20241231</SVTODATE>
          <GROUPNAME>Sundry Creditors</GROUPNAME>
        </STATICVARIABLES>
      </REQUESTDESC>
    </EXPORTDATA>
  </BODY>
</ENVELOPE>'


# ───────────────────────────────────────────────────────────────────────────────
# 32. BANK RECONCILIATION
# ───────────────────────────────────────────────────────────────────────────────
curl -s -X POST "$TALLY" \
  -H "Content-Type: text/xml" \
  -d '<ENVELOPE>
  <HEADER><TALLYREQUEST>Export Data</TALLYREQUEST></HEADER>
  <BODY>
    <EXPORTDATA>
      <REQUESTDESC>
        <REPORTNAME>Bank Reconciliation</REPORTNAME>
        <STATICVARIABLES>
          <SVEXPORTFORMAT>$$SysName:XML</SVEXPORTFORMAT>
          <SVFROMDATE>20241201</SVFROMDATE>
          <SVTODATE>20241231</SVTODATE>
          <LEDGERNAME>HDFC Bank</LEDGERNAME>
        </STATICVARIABLES>
      </REQUESTDESC>
    </EXPORTDATA>
  </BODY>
</ENVELOPE>'


# ═══════════════════════════════════════════════════════════════════════════════
#  TIPS
# ═══════════════════════════════════════════════════════════════════════════════
#
#  • Pipe to xmllint for pretty XML:
#      curl ... | xmllint --format -
#
#  • Save response to file:
#      curl ... -o response.xml
#
#  • Date format is always YYYYMMDD (no dashes, no slashes)
#
#  • SVEXPORTFORMAT options:
#      $$SysName:XML   → XML  (best for parsing)
#      $$SysName:ASCII → CSV-like text
#      $$SysName:HTML  → HTML table
#
#  • Windows (CMD) — replace single quotes with double quotes and escape inner:
#      curl -X POST http://localhost:9000 -H "Content-Type: text/xml" -d "<ENVELOPE>...</ENVELOPE>"
#
#  • Windows (PowerShell):
#      $body = Get-Content request.xml -Raw
#      Invoke-RestMethod -Uri http://localhost:9000 -Method POST -Body $body -ContentType "text/xml"
#
# ═══════════════════════════════════════════════════════════════════════════════