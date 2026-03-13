# Tally Due Payments Dashboard

A lightweight **Node.js dashboard** that connects to **Tally ERP** and displays supplier payment insights in a simple web interface.

## Features

* 📊 Total due amount per vendor / supplier
* ⏳ Aging buckets (0–30 / 30–60 / 60–90 / 90+ days)
* ⚠️ Overdue payments summary
* 🏆 Top 10 vendors by outstanding amount
* 📄 Export data as CSV
* 🌐 Accessible on LAN for team use

---

# Prerequisites

| Requirement | Version / Notes                     |
| ----------- | ----------------------------------- |
| Node.js     | v18+                                |
| Tally ERP   | Must be running                     |
| Network     | Same machine as Tally (recommended) |

Download Node.js: https://nodejs.org

---

# Step 1 — Enable Tally HTTP Server

Open **Tally ERP**:

```
Gateway of Tally
 → F12 (Configure)
 → Advanced Configuration
```

Set:

```
Enable ODBC Server: Yes
Port: 9000
```

Restart **Tally** after saving.

---

# Step 2 — Install & Run

Navigate to the project folder.

Install dependencies (one time):

```
npm install
```

Start the server:

```
node server.js
```

Open browser:

```
http://localhost:3000
```

---

# Step 3 — Share on LAN (Optional)

Find your local IP address:

Windows

```
ipconfig
```

Mac / Linux

```
ifconfig
```

Share the dashboard:

```
http://YOUR-IP:3000
```

Example:

```
http://192.168.1.10:3000
```

Anyone on the same Wi-Fi / LAN can access it.

---

# Project Structure

```
tally-dashboard/
│
├── server.js
├── package.json
├── web.config
│
└── public/
     └── index.html
```

---

# Deploy on IIS

## 1 Enable IIS

Open Windows Features:

```
Control Panel → Programs → Turn Windows features on or off
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

## 2 Install Required Components

Install:

Node.js
https://nodejs.org

URL Rewrite Module
https://www.iis.net/downloads/microsoft/url-rewrite

iisnode
https://github.com/Azure/iisnode

---

## 3 Create IIS Website

Open **IIS Manager**

Create a new site:

```
Site name: tally-dashboard
Physical path: D:\apps\tally-dashboard
Port: 5000 (or any free port)
```

---

## 4 Add web.config

Create `web.config` in the project root:

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

## 5 Fix Handler Lock Error (Important)

If you see:

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

## 6 Access Dashboard

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

| Problem            | Solution                                     |
| ------------------ | -------------------------------------------- |
| Cannot reach Tally | Ensure Tally is open and ODBC server enabled |
| Empty vendor list  | Verify ledger group is "Sundry Creditors"    |
| Wrong balances     | Check Dr/Cr configuration in Tally           |
| Port already used  | Change Node or IIS port                      |

---

# Security Notes

This dashboard:

* Reads **only outstanding ledger data**
* Does **not modify Tally data**
* Should ideally run **inside local network**

For production usage consider:

* IIS Authentication
* VPN access
* Reverse proxy

---
