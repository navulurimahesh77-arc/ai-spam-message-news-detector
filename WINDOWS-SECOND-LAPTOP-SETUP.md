# Setup & Troubleshooting Guide: Second Windows Laptop

This guide explains how to get automatic notification monitoring working on a second Windows laptop without modifying or interfering with the working primary laptop.

---

## 1. Why Automatic Monitoring Works on Laptop 1 but Not on Laptop 2

| Factor | Primary Laptop (Working) | Second Laptop (Failing) | Technical Reason |
| :--- | :--- | :--- | :--- |
| **WinRT Access Status** | `Allowed` | `Denied` or `Unspecified` | Windows 10/11 requires per-device user consent for apps to read notifications. If not enabled in Settings, the OS returns an empty list or denies access. |
| **Notification Banners** | Enabled for WhatsApp / Chrome | "Show only in notification center" or Disabled | WinRT `UserNotificationListener` triggers on *Toast* notifications. If banners are turned off, no toast event is emitted. |
| **Focus Assist / Do Not Disturb** | OFF | ON (Alarms only / Priority) | When Do Not Disturb is active, Windows suppresses live toast broadcasts to background listeners. |
| **PowerShell Execution Policy** | Bypass / RemoteSigned | `Restricted` (Default) | Default Windows PowerShell security blocks double-clicking `.ps1` scripts unless launched via `run.bat` / `-ExecutionPolicy Bypass`. |
| **Port Conflicts** | Port 8765 Free | Port 8765 Occupied | Another local service may already be bound to port 8765 on Laptop 2. |

---

## 2. Quick Repeatable Setup for Laptop 2 (2 Minutes)

### Step 1: Copy the `windows-second-laptop` Folder
Copy the `windows-second-laptop` folder (along with `index.html`, `js/`, `css/` if running offline) to Laptop 2 using a USB drive or local Wi-Fi share.

### Step 2: Run the Diagnostic Tool
Right-click `Diagnose-Laptop2.ps1` and select **Run with PowerShell**, or double-click:
```cmd
start-laptop2.bat
```
The tool will automatically run 6 system checks:
1. Windows OS Build (requires Build 14393+ / Windows 10 Version 1607+).
2. WinRT Assembly loading (`System.Runtime.WindowsRuntime`).
3. UserNotificationListener Access Status (`Allowed` vs `Denied`).
4. Port 8765 Availability.
5. Windows Toast Banner Settings.
6. Privacy redaction verification.

### Step 3: Grant Windows Notification Permission (If Status is Denied)
1. Press `Win + I` to open **Windows Settings**.
2. Navigate to:
   - **Windows 11**: `Privacy & security` > `Notifications`
   - **Windows 10**: `Privacy` > `Notifications`
3. Toggle **ON**: *"Let apps access your notifications"*.
4. Scroll down and verify that **PowerShell**, **Windows Terminal**, and your messaging apps are set to **Allow**.

### Step 4: Verify WhatsApp Notification Settings
1. Open Windows Settings > **System** > **Notifications**.
2. Find **WhatsApp** (or **Google Chrome** / **Microsoft Edge** if using WhatsApp Web).
3. Ensure:
   - [x] **Notifications**: ON
   - [x] **Show notification banners**: ON
   - [x] **Show notifications in notification center**: ON
4. In WhatsApp Desktop: Settings > Notifications > Ensure "Show Previews" is checked.

---

## 3. Running with a Custom Port or Host

If port 8765 is in use by another app on Laptop 2:
```powershell
powershell -ExecutionPolicy Bypass -File .\Companion-Laptop2.ps1 -Port 8766
```
Then, open the web app, click **Settings**, and set the Companion URL to:
`http://127.0.0.1:8766`

---

## 4. Privacy & Security Assurance

- **Zero Cloud Leakage**: All notification text stays in local laptop memory.
- **Redacted Console Logs**: The companion console outputs only app name and text length (`[TOAST DETECTED] App: WhatsApp | Title: [Length: 14 chars]`). Raw messages are never printed to console logs or written to disk.
