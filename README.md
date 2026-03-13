# Tally Due Payments Dashboard

A lightweight **Node.js dashboard** that connects to **TallyPrime / Tally ERP 9** and visualizes supplier payment insights in a simple web interface.

Designed for **finance teams and business owners** to quickly understand vendor dues and payment aging.

---

# Features

* 📊 **Total outstanding amount** per vendor
* ⏳ **Payment aging buckets**

  * 0–30 days
  * 30–60 days
  * 60–90 days
  * 90+ days
* ⚠️ **Overdue payments summary**
* 🏆 **Top 10 vendors** by outstanding balance
* 📄 **Export data to CSV**
* 🌐 **LAN access** for team usage
* ⚡ **Direct Tally integration via HTTP**

---

# Prerequisites

| Requirement | Notes                               |
| ----------- | ----------------------------------- |
| Node.js     | v18 or newer                        |
| Tally       | Must be running                     |
| Network     | Same machine as Tally (recommended) |

Download Node.js
[https://nodejs.org](https://nodejs.org)

---

# Setup Guide

## 1. Enable Tally HTTP Server

Open **TallyPrime**:

```
Gateway of Tally
 → F12 (Configure)
 → Advanced Configuration
```

Enable:

```
Enable ODBC Server : Yes
Port               : 9000
```

Restart **Tally** after saving.

---

## 2. Install & Run the Dashboard

Navigate to the project folder:

Install dependencies:

```
npm install
```

Start the server:

```
node server.js
```

Open the dashboard:

```
http://localhost:3000
```

---

# Share Dashboard on LAN

If multiple team members need access:

Find your machine IP.

Windows

```
ipconfig
```

Mac / Linux

```
ifconfig
```

Open dashboard using:

```
http://YOUR-IP:3000
```

Example:

```
http://192.168.1.10:3000
```

Now anyone on the same **Wi-Fi / LAN** can access it.

---

# Project Structure

```
tally-dashboard
│
├── server.js
├── package.json
├── web.config
│
└── public
     └── index.html
```

---

# Deploy on IIS (Optional)

This allows running the dashboard as a **Windows server application**.

---

## 1. Enable IIS

Open Windows Features:

```
Control Panel
 → Programs
 → Turn Windows features on or off
```

Enable:

```
Internet Information Services
  → Application Development Features
     ✓ CGI
     ✓ ISAPI Extensions
     ✓ ISAPI Filters
```

---

## 2. Install Required Components

Install:

Node.js
[https://nodejs.org](https://nodejs.org)

URL Rewrite Module
[https://www.iis.net/downloads/microsoft/url-rewrite](https://www.iis.net/downloads/microsoft/url-rewrite)

iisnode
[https://github.com/Azure/iisnode](https://github.com/Azure/iisnode)

---

## 3. Create IIS Website

Open **IIS Manager**

Create a new site:

```
Site name     : tally-dashboard
Physical path : D:\apps\tally-dashboard
Port          : 5000
```

---

## 4. Add web.config

Create `web.config` in the project root.

```xml
<configuration>
  <system.webServer>

    <handlers>
      <add name="iisnode" path="server.js" verb="*" modules="iisnode"/>
    </handlers>

    <rewrite>
      <rules>
        <rule name="NodeJS">
          <match url="(.*)" />
          <conditions>
            <add input="{REQUEST_FILENAME}" matchType="IsFile" negate="true"/>
          </conditions>
          <action type="Rewrite" url="/server.js"/>
        </rule>
      </rules>
    </rewrite>

  </system.webServer>
</configuration>
```

---

## 5. Fix Handler Lock Error

If IIS shows:

```
Error Code: 0x80070021
handlers section is locked
```

Run **Command Prompt as Administrator**:

```
%windir%\system32\inetsrv\appcmd unlock config -section:system.webServer/handlers
```

Restart IIS:

```
iisreset
```

---

## 6. Access Dashboard

Open:

```
http://SERVER-IP:PORT
```

Example:

```
http://192.168.65.1:5000
```

---

# Troubleshooting

| Issue                   | Solution                                     |
| ----------------------- | -------------------------------------------- |
| Cannot connect to Tally | Ensure Tally is open and HTTP server enabled |
| Empty vendor list       | Verify vendors are in **Sundry Creditors**   |
| Incorrect balances      | Check Dr/Cr configuration                    |
| Port already used       | Change Node or IIS port                      |

---

# Security Notes

This dashboard:

* **Reads only outstanding ledger data**
* **Does not modify Tally data**
* Works best **inside local network**

For production environments consider:

* IIS Authentication
* VPN access
* Reverse proxy

---

# Debugging with curl

You can query **TallyPrime** directly using `curl` to verify raw data.

---

## 1. Get Current Company

```bash
curl -X POST http://localhost:9000 \
-H "Content-Type: application/xml" \
-d '<?xml version="1.0" encoding="UTF-8"?>
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

Expected response:

```xml
<COMPANY NAME="ABC Traders"/>
```

---

## 2. Fetch Vendor Payables

```bash
curl -X POST http://localhost:9000 \
-H "Content-Type: application/xml" \
-d '<?xml version="1.0" encoding="UTF-8"?>
<ENVELOPE>
 <HEADER>
  <TALLYREQUEST>Export</TALLYREQUEST>
 </HEADER>
 <BODY>
  <EXPORTDATA>
   <REQUESTDESC>
    <REPORTNAME>Bill-wise Outstandings</REPORTNAME>
    <STATICVARIABLES>
      <SVEXPORTFORMAT>$$SysName:XML</SVEXPORTFORMAT>
      <SVFROMDATE>20240401</SVFROMDATE>
      <SVTODATE>20260331</SVTODATE>
    </STATICVARIABLES>
   </REQUESTDESC>
  </EXPORTDATA>
 </BODY>
</ENVELOPE>'
```

Example response:

```xml
<LEDGER NAME="ABC Suppliers">
 <BILLALLOCATIONS.LIST>
  <NAME>INV-101</NAME>
  <BILLDATE>20240210</BILLDATE>
  <AMOUNT>-25000</AMOUNT>
 </BILLALLOCATIONS.LIST>
</LEDGER>
```

Negative amount = **payable**

---

## 3. Fetch All Ledgers

```bash
curl -X POST http://localhost:9000 \
-H "Content-Type: application/xml" \
-d '<?xml version="1.0" encoding="UTF-8"?>
<ENVELOPE>
 <HEADER>
  <TALLYREQUEST>Export</TALLYREQUEST>
 </HEADER>
 <BODY>
  <EXPORTDATA>
   <REQUESTDESC>
    <REPORTNAME>List of Ledgers</REPORTNAME>
    <STATICVARIABLES>
      <SVEXPORTFORMAT>$$SysName:XML</SVEXPORTFORMAT>
    </STATICVARIABLES>
   </REQUESTDESC>
  </EXPORTDATA>
 </BODY>
</ENVELOPE>'
```

---

## Pretty-Print XML (Optional)

If `xmllint` is installed:

```
curl ... | xmllint --format -
```

---

## Quick Test

```
curl http://localhost:9000
```

Expected response:

```
Tally Server Running
```

---

# License

MIT License

