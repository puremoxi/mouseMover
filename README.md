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
- **Ctrl+C** → Stop script
- **Close terminal window** → Stop script

## Configuration (How to Edit)

Open `mouse-jiggler-f8.ps1` and change:

```powershell
$IntervalSeconds =20
```

How often the cursor moves.

```powershell
$MovePixels =1
```

How far the cursor moves.

```powershell
$HotkeyVk =0x77
```

Hotkey (F8).

F9 = 0x78

F10 = 0x79

```powershell
$StartEnabled =$true
```

Start enabled or disabled.

## How It Works

- Registers a global hotkey using Win32 `RegisterHotKey`
- Creates a hidden message window for `WM_HOTKEY`
- Moves cursor slightly then returns it
- Pumps Windows messages so hotkey stays responsive

---

## Troubleshooting

### Failed to register hotkey

Another app may already use F8.

Change `$HotkeyVk` to another function key.

### Hotkey slow to respond

Lower `$IntervalSeconds` or reduce 100ms sleep in the loop.

---

## Notes

This script is intended for benign use (e.g., keeping a screen awake during a long read or demo).