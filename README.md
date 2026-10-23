# AI Spam, Message & News Detector

> **Privacy-First, Local Pattern & Heuristic Detector for Messages, Advertisements, News Claims, and Windows Notifications.**

---

## 1. Project Overview

The **AI Spam, Message & News Detector** is a transparent, privacy-first web application and companion service designed to analyze messages, advertisements, news claims, and desktop notifications.

Unlike cloud-based security products that transmit personal communications over the internet, this detector operates **100% locally on your machine**. It applies deterministic natural language heuristics, structural pattern recognition, and credential risk scoring to evaluate untrusted text.

### Key Capabilities
- **Manual Text & Message Analysis**: Paste or type any email, SMS, promotional text, social post, or news headline for instant evaluation.
- **Four Distinct Classifications**:
  - `Safe`: Standard communications with no detected manipulative, promotional, or high-risk triggers.
  - `Spam`: Unsolicited advertisements, exaggerated product claims, fake sweepstakes, and aggressive sales lures.
  - `Potentially Harmful`: High-risk phishing attempts, password/credential harvesting, two-factor code interception, financial fraud, and extortion.
  - `Needs Verification`: Sensational news, unverified health or political claims, vague attributions, and notifications where text was withheld for privacy.
- **Explainable Trust & Risk Metrics**:
  - **Trust Score (0–100)**: Transparent indicator based on detected risk penalties (explicitly documented as an informational heuristic, not a guarantee of safety).
  - **Risk Level**: `Low`, `Medium`, or `High`.
  - **Warning Flags**: Specific granular tags identifying detected threats.
  - **Snippet Evidence**: Extracts and quotes exact phrases from the message that triggered the flags.
- **Balanced News & Claim Analysis**:
  - Highlights sensational wording, clickbait phrasing, and missing source attributions.
  - **Never labels claims as "False"** without authoritative evidence. Operates honestly by classifying unverified claims as `Needs Verification` and providing actionable steps for independent confirmation.
- **Automatic Windows Notification Monitoring**:
  - Connects to Windows 10/11 `UserNotificationListener` WinRT API via a lightweight local companion.
  - Explains the purpose of notification access before requesting permissions.
  - Offers granular controls: enable/disable at any time, pause/resume monitoring, and filter which apps to monitor.
  - Handles privacy-masked notifications honestly (`[Content Unavailable]`).
  - Built-in **Notification Simulator** to test real-world scenarios even without granting OS permissions.
- **Zero-Telemetry Privacy Model**:
  - No external cloud AI APIs, no tracking scripts, and no external network calls.
  - Zero persistent logging of message or notification contents by default.

---

## 2. Architecture & Technology Stack

```
┌────────────────────────────────────────────────────────┐
│                   Web Browser (UI)                     │
│  - index.html (Responsive Dashboard)                   │
│  - css/styles.css (Modern CSS, Desktop & Mobile)       │
│  - js/analyzer.js (Core Heuristic Detection Engine)    │
│  - js/notifications.js (Companion Client & Simulator)  │
│  - js/app.js (UI State & Event Controller)             │
└──────────────────────────▲─────────────────────────────┘
                           │ Loopback HTTP (127.0.0.1:8765)
┌──────────────────────────▼─────────────────────────────┐
│          Local Windows Companion (Zero Cloud)          │
│  - companion/WindowsNotificationCompanion.ps1          │
│    (Native PowerShell + Windows 10/11 WinRT Listener)  │
│  - Optional alternatives: server.py / server.js        │
└──────────────────────────▲─────────────────────────────┘
                           │ WinRT UserNotificationListener
┌──────────────────────────▼─────────────────────────────┐
│               Windows 10/11 Toast System               │
└────────────────────────────────────────────────────────┘
```

- **Frontend**: Vanilla HTML5, CSS3, and JavaScript (ES6+). Zero external library or CDN dependencies. Works completely offline.
- **Windows Companion**: Native PowerShell script (`companion/WindowsNotificationCompanion.ps1`) using .NET `System.Net.Sockets.TcpListener` and Windows Runtime (`Windows.UI.Notifications.Management.UserNotificationListener`).
- **Alternative Companions**: `companion/server.py` (Python 3) and `companion/server.js` (Node.js).

---

## 3. Prerequisites

- **Standalone Mode (Direct Browser Usage)**:
  - Any modern web browser: Microsoft Edge, Google Chrome, Mozilla Firefox, or Apple Safari.
  - No installation, package manager, or runtime required!
- **Windows Notification Companion (Native WinRT Integration)**:
  - Windows 10 (Version 1607 or newer) or Windows 11.
  - PowerShell 5.1 or newer (pre-installed on all Windows 10/11 installations).

---

## 4. Installation & Quick Start

### Option A: One-Click Launch (Recommended for Windows)
1. Download and extract the project ZIP file.
2. Double-click `run.bat` in the project root folder.
3. This will launch the local companion server and automatically open the application at `http://127.0.0.1:8765/` in your default browser.

### Option B: PowerShell Companion Launch
Open PowerShell in the project directory and run:
```powershell
powershell -ExecutionPolicy Bypass -File companion\WindowsNotificationCompanion.ps1
```
Then visit `http://127.0.0.1:8765/` in your browser.

### Option C: Standalone Offline Mode (Zero Setup)
Simply double-click `index.html` or drag it into any web browser.
- The entire Text & News Analyzer runs immediately in client-side JavaScript.
- In the Notifications tab, you can use the built-in **Notification Simulator** to test all flows and edge cases.

### Option D: Alternative Companions (Python or Node.js)
- **Python**: `python companion/server.py`
- **Node.js**: `node companion/server.js`

---

## 5. How to Use Manual Message & News Analysis

1. Open the application and ensure the **Message & News Analyzer** tab is selected.
2. Enter or paste text into the text area.
   - Or click **Load Sample** to choose one of the pre-loaded scenarios:
     - 🎣 *Phishing / Credential Scam*
     - 📢 *Urgent Promotional Spam*
     - 📰 *Sensational News Claim*
     - ⚡ *Extortion & Legal Threat*
     - ✅ *Safe Legitimate Message*
     - 🔒 *Masked / Unavailable Text*
3. Click **Analyze Text**.
4. Review the results:
   - **Classification Badge**: `Safe`, `Spam`, `Potentially Harmful`, or `Needs Verification`.
   - **Trust Score**: Evaluated from 0 to 100.
   - **Risk Level**: `Low`, `Medium`, or `High`.
   - **Summary Explanation**: Plain-language assessment referencing phrases discovered in the text.
   - **Warning Flags**: Specific indicator badges.
   - **Phrases Detected**: Specific matched substrings extracted directly from the input.
   - **News Verification Notice**: Appears when sensationalism or unverified claims are present, detailing recommended primary source checks.
5. Click **Clear** to reset the input and results.

---

## 6. Windows Notification Monitoring

### Why Notification Access is Needed
Under Windows security guidelines, desktop web browsers run in isolated sandboxes and cannot access operating system notifications. The local Windows Companion operates as a bridge:
1. It requests permission through Windows System settings to read incoming toast notifications using the official `UserNotificationListener` API.
2. It relays notification payloads strictly across local loopback (`127.0.0.1`) to the web dashboard.
3. **No notification text is ever sent over the network or saved to remote databases.**

### Permission Process
1. Start the Windows Companion using `run.bat`.
2. In the web dashboard, open the **Windows Notifications** tab.
3. Under *Companion Server Status*, click **Open Windows Settings** (or navigate to *Windows Settings > System > Notifications* / *Privacy & security > Notifications*).
4. Ensure the master toggle **"Let apps access your notifications"** is set to **On**.
5. Once granted, the Companion Status indicator will switch to **Windows Companion Connected** with permission status **Allowed**.

### Controlling Monitoring & App Filters
- **Start / Stop**: Click **Start Monitoring** to begin listening for incoming notifications.
- **Pause / Resume**: Click **Pause** to temporarily halt processing without disconnecting.
- **App Filtering**: Under *Monitored Applications Filter*, select or uncheck individual apps (e.g., Mail, Outlook, WhatsApp, Teams, Chrome, Edge, Slack, System). Unchecked apps will be ignored.

### Testing with the Notification Simulator
If you are running on a non-Windows machine, testing without OS permissions, or verifying behavior:
- Click any of the simulator buttons:
  - `🎣 Test Phishing Toast`
  - `📢 Test Promo Spam Toast`
  - `📰 Test Sensational News Toast`
  - `✅ Test Safe Toast`
  - `🔒 Test Unavailable Content Toast`
The simulator will automatically activate monitoring and demonstrate live processing, scoring, and feed rendering.

---

## 7. Handling Unavailable & Masked Content

Certain privacy-focused apps (such as Signal or WhatsApp) or Windows security policies (such as lock screen content hiding) suppress the body of notifications.

**Our Transparency Guarantee:**
- If notification text is withheld or empty, the application **never fabricates or guesses hidden content**.
- The detector explicitly flags the item:
  > `[Content Unavailable: The source app or Windows privacy settings withheld the notification text. No text could be analyzed.]`
- It is classified as `Needs Verification` with a neutral trust score and a clear explanation that privacy settings prevented automated inspection.

---

## 8. Data Storage & Privacy Policy

- **Untrusted Input**: All incoming messages, notification text, and links are treated as untrusted data. HTML entities are strictly escaped to prevent cross-site scripting (XSS).
- **No External Telemetry**: The application contains **zero calls to third-party cloud AI APIs, remote trackers, or analytics**.
- **No Persistent Storage by Default**:
  - Message analysis text is held only in transient page memory during your session.
  - Notification monitoring does **not** write notification text to disk.
- **Optional Local History**:
  - If you switch on **"Save Notification History"**, records are saved **solely in your local browser's `localStorage`**.
  - A dedicated **Clear Notification History** button allows you to delete all saved history with a single click.

---

## 9. Limitations & Ethical Disclosures

1. **Heuristic & Pattern Detection**:
   This tool is powered by a transparent, rule-based natural language heuristic engine. It is **not** an enterprise antivirus engine, an endpoint detection and response (EDR) agent, or a generative AI model.
2. **Not an Authoritative Fact-Checker**:
   The news analysis feature identifies linguistic patterns commonly found in unverified or sensational viral posts. It **does not verify real-world facts** and **never labels a news claim as "False"** without primary documentation.
3. **No Automatic Actions**:
   The application never automatically opens links, responds to messages, or deletes files. All decisions remain in user hands.

---

## 10. Troubleshooting

| Issue | Cause | Solution |
| :--- | :--- | :--- |
| **"Companion Offline (Standalone Mode)"** | `companion/WindowsNotificationCompanion.ps1` is not running. | Run `run.bat` or run `powershell -ExecutionPolicy Bypass -File companion\WindowsNotificationCompanion.ps1`. |
| **WinRT Permission: "Denied"** | Windows has not granted notification listener rights to PowerShell. | Go to *Windows Settings > Privacy & security > Notifications* and enable notification access for apps. |
| **Notifications Not Appearing** | The sending app is unchecked in the *Monitored Applications Filter*, or monitoring is stopped/paused. | Check that the app is selected and monitoring status shows **Active (Listening)**. |
| **Port 8765 Already in Use** | Another process is using port 8765. | Pass a custom port: `powershell -File companion\WindowsNotificationCompanion.ps1 -Port 8766`. |

---

## 11. Configuration (`config.sample.json`)

The project includes `config.sample.json` documenting configurable options:
```json
{
  "companion": {
    "host": "127.0.0.1",
    "port": 8765,
    "autoLaunchBrowser": true,
    "allowExternalConnections": false
  },
  "detection": {
    "engine": "heuristic_pattern_matcher",
    "version": "1.0.0"
  },
  "notifications": {
    "saveHistoryByDefault": false,
    "maxHistoryEntries": 50
  },
  "privacy": {
    "localProcessingOnly": true,
    "telemetryEnabled": false
  }
}
```
*Note: This project does not require any credentials, secrets, or API keys.*

---

## 12. Running Automated Tests

To execute the automated verification test suite:
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests\test-detector.ps1
```
All 60 automated test assertions covering file structure, HTML semantics, classification, risk scoring, empty input validation, unavailable text honesty, and privacy compliance will run and report status.
