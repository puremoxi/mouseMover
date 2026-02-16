# Mouse Mover (PowerShell) — F8 Toggle

A lightweight PowerShell script for Windows 11 that nudges your mouse cursor on an interval.
It includes a global hotkey so you can toggle the behavior without stopping the script.

## Features
- Moves the mouse every **20 seconds** (configurable)
- Global hotkey: **F8** toggles jiggling **ON/OFF**
- Stops immediately with **Ctrl+C** or by closing the terminal window
- Cleans up after itself by **unregistering the hotkey** on exit
- No external installs required (uses built-in .NET + user32.dll)

## Requirements
- Windows 11 (works on Windows 10+ as well)
- PowerShell 5.1 or PowerShell 7+
- An interactive desktop session (not intended to run as a Windows service)

## Install
1. Create a file named: `mouse-jiggler-f8.ps1`
2. Paste the script contents into the file

## Run

From PowerShell in the same folder:

```powershell
.\mouse-jiggler-f8.ps1
```

If scripts are blocked:

```powershell
Set-ExecutionPolicy-ScopeProcess-ExecutionPolicy Bypass
.\mouse-jiggler-f8.ps1
```
## Controls

- **F8** → Toggle mouse jiggling ON/OFF
- **Tray icon double-click** → Toggle ON/OFF
- **Tray icon right-click → Toggle**
- **Tray icon right-click → Exit**
- **Ctrl+C** → Stop script
- **Close terminal window** → Stop script

---

## Configuration (How to Edit)

Open `mouse-jiggler-f8.ps1` and modify these variables near the top:

```powershell
$IntervalSeconds =20
```

How often the cursor moves.

```powershell
$MovePixels =1
```

How far the cursor moves (pixels).

Moves right by this amount, then back.

```powershell
$HotkeyVk =0x77
```

Virtual-key code for the hotkey.

Common values:

```
F8  =0x77F9  =0x78F10 =0x79F11 =0x7AF12 =0x7B
```

```powershell
$HotkeyLabel ="F8"
```

Human-readable label shown in logs and tray tooltip.

(Keep in sync with `$HotkeyVk`.)

```powershell
$StartEnabled =$true
```

Whether the script starts in ON mode.

---

## How It Works

- Registers a global hotkey via Win32 `RegisterHotKey`
- Creates a hidden message window to receive `WM_HOTKEY`
- Generates small in-memory tray icons (green/gray)
- When enabled:
    - Stores current cursor position
    - Moves cursor by `MovePixels`
    - Waits briefly
    - Restores original position
- Uses frequent message pumping so hotkey and tray remain responsive

---

## Changelog

### v1.1.0 — Tray Icon Release

- Added system tray icon with ON/OFF visual state
- Green dot (ON) and gray dot (OFF) icons
- Double-click tray icon to toggle
- Right-click menu with Toggle / Exit
- Hotkey registration confirmation message
- Human-readable hotkey label in logs and tooltip
- Improved cleanup (hotkey, tray icon, event subscription, icon handles)

### v1.0.0 — Initial Release

- Global hotkey (F8) toggle
- Configurable interval and move distance
- Clean shutdown with hotkey unregistration
- No external dependencies

---

## Troubleshooting

### Failed to register hotkey

Another application may already be using that key.

Change:

```powershell
$HotkeyVk$HotkeyLabel
```

to another function key (F9, F10, etc.)

---

### Tray icon does not appear

Windows may be hiding inactive tray icons.

Click the **^** arrow in the system tray and drag the icon into the visible area.

---

### Hotkey feels slow

Reduce:

```powershell
$IntervalSeconds
```

or (advanced) reduce the 100ms sleep inside the inner loop.

---

## Notes

This script is intended for benign use such as:

- Preventing screen lock during reading
- Long demos or presentations
- Keeping collaboration tools active

Not intended to bypass organizational security policies.

---

## License

Use freely at your own risk.