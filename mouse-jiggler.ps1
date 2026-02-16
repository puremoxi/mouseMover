# Mouse Jiggler with F8 toggle (global hotkey)
# - F8 toggles jiggling ON/OFF
# - Ctrl+C or closing the window stops it
# - Default: move every 20 seconds

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Win32 RegisterHotKey / UnregisterHotKey + message receiver window
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Windows.Forms;

public static class HotKeyNative
{
    [DllImport("user32.dll", SetLastError=true)]
    public static extern bool RegisterHotKey(IntPtr hWnd, int id, uint fsModifiers, uint vk);

    [DllImport("user32.dll", SetLastError=true)]
    public static extern bool UnregisterHotKey(IntPtr hWnd, int id);
}

public class HotKeyWindow : NativeWindow
{
    public event EventHandler HotKeyPressed;

    public HotKeyWindow()
    {
        CreateHandle(new CreateParams());
    }

    protected override void WndProc(ref Message m)
    {
        const int WM_HOTKEY = 0x0312;
        if (m.Msg == WM_HOTKEY)
        {
            HotKeyPressed?.Invoke(this, EventArgs.Empty);
        }
        base.WndProc(ref m);
    }
}
"@ -ReferencedAssemblies "System.Windows.Forms"

# =========================
# Config (edit these)
# =========================
$IntervalSeconds = 20   # how often to jiggle
$MovePixels      = 1    # how far to move (px)
$HotkeyVk        = 0x77 # F8 virtual-key code
$HotkeyId        = 1    # arbitrary id for RegisterHotKey
$StartEnabled    = $true

# =========================
# Runtime state
# =========================
$enabled = $StartEnabled
$window  = New-Object HotKeyWindow

$null = Register-ObjectEvent -InputObject $window -EventName HotKeyPressed -Action {
    # Toggle state
    $script:enabled = -not $script:enabled
    $state = if ($script:enabled) { "ON" } else { "OFF" }
    Write-Host ("[{0}] Mouse jiggler: {1} (F8 toggles)" -f (Get-Date -Format "HH:mm:ss"), $state)
}

Write-Host "Mouse jiggler running. F8 toggles ON/OFF. Ctrl+C or close this window to stop."
Write-Host ("Initial state: {0}. Interval: {1}s. Move: {2}px." -f ($(if($enabled){"ON"}else{"OFF"})), $IntervalSeconds, $MovePixels)

# Register global hotkey (no modifiers)
if (-not [HotKeyNative]::RegisterHotKey($window.Handle, $HotkeyId, 0, $HotkeyVk)) {
    $err = [Runtime.InteropServices.Marshal]::GetLastWin32Error()
    throw "Failed to register hotkey F8. Win32Error=$err (Is another app already using F8 as a global hotkey?)"
}

try {
    while ($true) {
        # Pump messages so WM_HOTKEY is received
        [System.Windows.Forms.Application]::DoEvents()

        if ($enabled) {
            # Jiggle: move 1px and back
            $pos = [System.Windows.Forms.Cursor]::Position
            [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($pos.X + $MovePixels, $pos.Y)
            Start-Sleep -Milliseconds 60
            [System.Windows.Forms.Cursor]::Position = $pos

            # Wait for interval, but keep pumping events frequently so F8 is responsive
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            while ($sw.Elapsed.TotalSeconds -lt $IntervalSeconds) {
                [System.Windows.Forms.Application]::DoEvents()
                Start-Sleep -Milliseconds 100
            }
        }
        else {
            # When OFF, keep CPU low but remain responsive to F8
            Start-Sleep -Milliseconds 120
        }
    }
}
finally {
    # Always clean up hotkey + event subscription
    [void][HotKeyNative]::UnregisterHotKey($window.Handle, $HotkeyId)
    Unregister-Event -SourceIdentifier ($window.GetHashCode().ToString()) -ErrorAction SilentlyContinue | Out-Null
    Get-EventSubscriber | Where-Object { $_.SourceObject -eq $window } | Unregister-Event -ErrorAction SilentlyContinue
    Write-Host "Stopped. Hotkey unregistered."
}
