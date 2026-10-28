# Multi-Device Architecture: AI Spam & News Detector

This document outlines the smallest, safest, and 100% free cross-device architecture supporting the existing website, multiple Windows laptops, Android mobile notification monitoring, and Gmail inbox scanning.

---

## 1. Architectural Philosophy: Edge Computing & Zero-Cost Privacy

Rather than introducing an expensive, privacy-invasive central cloud server with paid AI API keys (which would require routing users' private WhatsApp messages and emails over external networks), the system operates on a **Decentralized Edge Architecture**:

- **Zero Cloud Hosting Costs**: All classification heuristics execute on the local device (in-browser JavaScript or on-device Kotlin).
- **Zero Third-Party AI API Fees**: Uses the rule-based pattern engine (`analyzer.js` / `LocalSpamAnalyzer.kt`), eliminating recurring monthly OpenAI/Gemini/Anthropic API bills.
- **Complete Privacy**: Private message contents and email bodies never leave the physical device that received them.

---

## 2. Multi-Device Topology

```
+-----------------------------------------------------------------------------------------+
|                                    DEPLOYED FRONTEND                                    |
|                   Vercel Static Hosting (Free Tier, 100% Client-Side)                   |
|                   URL: https://ai-spam-message-news-detector.vercel.app/                |
+-----------------------------------------------------------------------------------------+
                                    |                      |
            +-----------------------+                      +-----------------------+
            | (HTTP Loopback 8765)                         | (HTTP Loopback 8765/8766)
            v                                              v
+-----------------------------+                +-----------------------------+
|   PRIMARY WINDOWS LAPTOP    |                |    SECOND WINDOWS LAPTOP    |
| - Companion:                |                | - Companion:                |
|   WindowsNotification-      |                |   Companion-Laptop2.ps1     |
|   Companion.ps1 (Port 8765) |                |   (Port 8765 / Custom)      |
| - WinRT UserNotification-   |                | - WinRT UserNotification-   |
|   Listener: [Allowed]       |                |   Listener: [Allowed via    |
| - WhatsApp Desktop / Web    |                |   Settings > Privacy]       |
+-----------------------------+                +-----------------------------+

                                 +-----------------------------+
                                 |   ANDROID MOBILE DEVICE     |
                                 |     (Vivo Y300 5G / Any)    |
                                 |                             |
                                 | [SpamShield Native App]     |
                                 | 1. WhatsAppNotification-    |
                                 |    ListenerService          |
                                 |    (Local Android Toast     |
                                 |     Interception)           |
                                 | 2. GmailApiClient           |
                                 |    (Official Google OAuth,  |
                                 |     Read-Only Token)        |
                                 | 3. LocalSpamAnalyzer.kt     |
                                 |    (100% On-Device CPU      |
                                 |     Heuristic Engine)       |
                                 | 4. Floating Instant Alert   |
                                 |    Notifications            |
                                 +-----------------------------+
```

---

## 3. Component Breakdown & Responsibilities

| Device / Channel | Technology | Role | Network / Cloud Dependency | Privacy Model |
| :--- | :--- | :--- | :--- | :--- |
| **Website (Vercel)** | HTML5, Vanilla JS, CSS3 | Interactive UI for manual text & screenshot OCR scanning | Static Vercel CDN | 100% in-browser RAM; zero telemetry |
| **Primary Laptop** | PowerShell 5.1 + WinRT (`WindowsNotificationCompanion.ps1`) | Local bridge for Windows toast notifications on port 8765 | Localhost loopback (127.0.0.1) | Zero external logging; loopback only |
| **Second Laptop** | PowerShell 5.1 + WinRT (`Companion-Laptop2.ps1`) | Standalone companion with diagnostic health checks and configurable ports | Localhost loopback (127.0.0.1) | Redacted logging (app name & length only) |
| **Android Mobile** | Native Kotlin (`SpamShield-Android`) | Listens to incoming WhatsApp notifications via OS service | 100% Offline (No Internet needed for WhatsApp) | Processed in-app; zero external transit |
| **Gmail Inbox** | Google Play Services Auth + Gmail REST API | Bounded batch scanning and incremental sync of inbox emails | Official Google APIs (`gmail.googleapis.com`) | Read-only OAuth scope; local body analysis |

---

## 4. Cost & Trade-Off Analysis

| Approach | Setup Cost | Monthly Operating Cost | Privacy Risk | Resilience |
| :--- | :--- | :--- | :--- | :--- |
| **Proposed Edge Architecture (Antigravity)** | **\$0.00** | **\$0.00 / month** | **Zero Risk** (Messages never leave local device) | **Extremely High** (Works offline; no server outages) |
| *Alternative: Central Cloud Server + Cloud LLM* | \$100 - \$500 setup | \$30 - \$200 / month (Server hosting + LLM tokens) | **High** (Personal WhatsApp messages & emails sent to cloud server) | Medium (Breaks if server is down or API quota exhausted) |

---

## 5. Security & Credential Protection

1. **No Hardcoded Secrets**: Zero API keys or client secrets exist in any repository file.
2. **Android OAuth Architecture**: Android uses cryptographic SHA-1 keystore validation and application ID matching directly with Google Play Services; no client secret is stored or exposed.
3. **No Password Interception**: The user authenticates directly via Google's secure system account dialog.
4. **Isolated Sandboxing**: Each component operates independently. If the second laptop or mobile is turned off, the primary laptop and website continue to work with zero disruption.
