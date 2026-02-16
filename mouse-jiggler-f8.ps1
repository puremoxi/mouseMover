# Mouse Jiggler with F8 toggle (global hotkey) + Tray Icon (ON/OFF icons)
# - F8 toggles jiggling ON/OFF (global hotkey)
# - Tray icon: Double-click to toggle, Right-click for Toggle/Exit
# - Ctrl+C or closing the window stops it
# - Default: move every 20 seconds

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Win32 RegisterHotKey / UnregisterHotKey + message receiver window + DestroyIcon for cleanup
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

public static class IconNative
{
    [DllImport("user32.dll", SetLastError=true)]
    public static extern bool DestroyIcon(IntPtr hIcon);
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
            // Avoid C# null-conditional (?.) to support older compilers used by Add-Type on some systems
            var handler = HotKeyPressed;
            if (handler != null) handler(this, EventArgs.Empty);
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

# Human-readable hotkey label (update if you change $HotkeyVk)
$HotkeyLabel     = "F8"

# =========================
# Runtime state
# =========================
$enabled    = $StartEnabled
$shouldExit = $false

# -------------------------
# Icon generation (ON/OFF)
# -------------------------
function New-DotIcon {
    param(
        [System.Drawing.Color]$DotColor,
        [System.Drawing.Color]$RingColor
    )

    $bmp = New-Object System.Drawing.Bitmap 16, 16
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

    # Transparent background
    $g.Clear([System.Drawing.Color]::Transparent)

    # Outer ring
    $ringBrush = New-Object System.Drawing.SolidBrush $RingColor
    $g.FillEllipse($ringBrush, 1, 1, 14, 14)

    # Inner dot
    $dotBrush = New-Object System.Drawing.SolidBrush $DotColor
    $g.FillEllipse($dotBrush, 3, 3, 10, 10)

    $ringBrush.Dispose()
    $dotBrush.Dispose()
    $g.Dispose()

    # Convert bitmap to icon
    $hIcon = $bmp.GetHicon()
    $icon = [System.Drawing.Icon]::FromHandle($hIcon)

    # We can dispose bitmap now; icon uses the handle
    $bmp.Dispose()

    # Return both icon and handle for proper cleanup later
    return [PSCustomObject]@{
        Icon  = $icon
        HIcon = $hIcon
    }
}

# Create icons once
$iconOn  = New-DotIcon -DotColor ([System.Drawing.Color]::FromArgb(  0, 200,  70)) -RingColor ([System.Drawing.Color]::FromArgb( 20,  80,  30))
$iconOff = New-DotIcon -DotColor ([System.Drawing.Color]::FromArgb(160, 160, 160)) -RingColor ([System.Drawing.Color]::FromArgb( 70,  70,  70))

function Update-TrayUi {
    param(
        [System.Windows.Forms.NotifyIcon]$Tray,
        [System.Windows.Forms.ToolStripMenuItem]$ToggleItem
    )

    $stateText = if ($script:enabled) { "ON" } else { "OFF" }

    # Update tooltip (max length is limited; keep it short)
    $Tray.Text = ("Mouse Jiggler: {0} ({1})" -f $stateText, $HotkeyLabel)

    # Swap icon based on state
    $Tray.Icon = if ($script:enabled) { $script:iconOn.Icon } else { $script:iconOff.Icon }

    if ($ToggleItem) {
        $ToggleItem.Text = if ($script:enabled) { "Turn OFF" } else { "Turn ON" }
    }
}

function Toggle-Jiggler {
    $script:enabled = -not $script:enabled
    $state = if ($script:enabled) { "ON" } else { "OFF" }
    Write-Host ("[{0}] Mouse jiggler: {1} ({2} toggles)" -f (Get-Date -Format "HH:mm:ss"), $state, $HotkeyLabel)
}

# Hidden hotkey message window
$window = New-Object HotKeyWindow

# Hotkey event: F8 toggles
$sub = Register-ObjectEvent -InputObject $window -EventName HotKeyPressed -Action {
    Toggle-Jiggler
    Update-TrayUi -Tray $script:tray -ToggleItem $script:toggleItem
}

# -------------------------
# Tray Icon + Menu
# -------------------------
$tray = New-Object System.Windows.Forms.NotifyIcon
$tray.Visible = $true

$menu = New-Object System.Windows.Forms.ContextMenuStrip

$toggleItem = New-Object System.Windows.Forms.ToolStripMenuItem
$toggleItem.Add_Click({
    Toggle-Jiggler
    Update-TrayUi -Tray $tray -ToggleItem $toggleItem
})

$exitItem = New-Object System.Windows.Forms.ToolStripMenuItem
$exitItem.Text = "Exit"
$exitItem.Add_Click({
    $script:shouldExit = $true
})

$null = $menu.Items.Add($toggleItem)
$null = $menu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))
$null = $menu.Items.Add($exitItem)

$tray.ContextMenuStrip = $menu

# Double-click tray icon to toggle
$tray.Add_DoubleClick({
    Toggle-Jiggler
    Update-TrayUi -Tray $tray -ToggleItem $toggleItem
})

Update-TrayUi -Tray $tray -ToggleItem $toggleItem

Write-Host "Mouse jiggler running. F8 toggles ON/OFF. Ctrl+C or close this window to stop."
Write-Host ("Initial state: {0}. Interval: {1}s. Move: {2}px." -f ($(if($enabled){"ON"}else{"OFF"})), $IntervalSeconds, $MovePixels)

# Register global hotkey (no modifiers)
if (-not [HotKeyNative]::RegisterHotKey($window.Handle, $HotkeyId, 0, $HotkeyVk)) {
    $err = [Runtime.InteropServices.Marshal]::GetLastWin32Error()
    throw "Failed to register hotkey (VK 0x{0:X}). Win32Error={1} (Is another app already using this as a global hotkey?)" -f $HotkeyVk, $err
}
Write-Host ("Hotkey registered: {0}" -f $HotkeyLabel)

try {
    while (-not $shouldExit) {
        # Pump messages so WM_HOTKEY + tray events are received
        [System.Windows.Forms.Application]::DoEvents()

        if ($enabled) {
            # Jiggle: move N px and back
            $pos = [System.Windows.Forms.Cursor]::Position
            [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point(($pos.X + $MovePixels), $pos.Y)
            Start-Sleep -Milliseconds 60
            [System.Windows.Forms.Cursor]::Position = $pos

            # Wait for interval, but keep pumping events frequently so F8/tray stays responsive
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            while (-not $shouldExit -and $sw.Elapsed.TotalSeconds -lt $IntervalSeconds) {
                [System.Windows.Forms.Application]::DoEvents()
                Start-Sleep -Milliseconds 100
            }
        }
        else {
            # When OFF, keep CPU low but remain responsive
            Start-Sleep -Milliseconds 120
        }
    }
}
finally {
    # Always clean up hotkey + event subscription + tray icon + icon handles
    try { [void][HotKeyNative]::UnregisterHotKey($window.Handle, $HotkeyId) } catch {}
    try { if ($sub) { Unregister-Event -SubscriptionId $sub.Id -ErrorAction SilentlyContinue } } catch {}
    try { $window.DestroyHandle() } catch {}

    try {
        if ($tray) {
            $tray.Visible = $false
            $tray.Dispose()
        }
    } catch {}

    # Dispose icons and destroy underlying handles
    try {
        if ($iconOn)  { $iconOn.Icon.Dispose()  | Out-Null; [void][IconNative]::DestroyIcon($iconOn.HIcon) }
        if ($iconOff) { $iconOff.Icon.Dispose() | Out-Null; [void][IconNative]::DestroyIcon($iconOff.HIcon) }
    } catch {}

    Write-Host "Stopped. Hotkey unregistered. Tray icon removed."
}
