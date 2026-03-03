# Lab7 Task 2 - Serial Terminal
# Reads ASCII characters sent from FPGA via UART
# 9600 baud, 8 data bits, no parity, 1 stop bit (8N1)

# --- CONFIG ---
$portName = "COM3"   # Change this to your COM port
$baudRate = 9600
# --------------

Write-Host "=== Lab7 Task 2 - FPGA Keyboard Serial Terminal ===" -ForegroundColor Cyan
Write-Host "Port: $portName  Baud: $baudRate" -ForegroundColor Cyan
Write-Host "Press Ctrl+C to exit" -ForegroundColor Yellow
Write-Host "---------------------------------------------------"
Write-Host ""

# Find available COM ports to help user pick the right one
Write-Host "Available COM ports:" -ForegroundColor Green
[System.IO.Ports.SerialPort]::GetPortNames() | ForEach-Object { Write-Host "  $_" }
Write-Host ""

try {
    $port = New-Object System.IO.Ports.SerialPort
    $port.PortName     = $portName
    $port.BaudRate     = $baudRate
    $port.DataBits     = 8
    $port.Parity       = [System.IO.Ports.Parity]::None
    $port.StopBits     = [System.IO.Ports.StopBits]::One
    $port.ReadTimeout  = 500

    $port.Open()
    Write-Host "Port $portName opened successfully. Type on your keyboard..." -ForegroundColor Green
    Write-Host ""

    while ($true) {
        try {
            $byte = $port.ReadByte()
            $char = [char]$byte

            # Print the character
            if ($byte -eq 0x0D) {
                # Enter key - print newline
                Write-Host ""
            } elseif ($byte -eq 0x08) {
                # Backspace
                Write-Host "<BS>" -NoNewline -ForegroundColor DarkGray
            } elseif ($byte -ge 0x20 -and $byte -le 0x7E) {
                # Normal printable ASCII
                Write-Host $char -NoNewline
            } else {
                # Non-printable - show hex value
                Write-Host ("[0x{0:X2}]" -f $byte) -NoNewline -ForegroundColor DarkYellow
            }
        } catch [System.TimeoutException] {
            # Timeout is normal when no key is being pressed, just continue
        }
    }
} catch {
    Write-Host "ERROR: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Tips:" -ForegroundColor Yellow
    Write-Host "  - Check Device Manager for the correct COM port number" -ForegroundColor Yellow
    Write-Host "  - Make sure the Basys3 is plugged in and programmed" -ForegroundColor Yellow
    Write-Host "  - Edit the portName variable at the top of this script" -ForegroundColor Yellow
} finally {
    if ($port -and $port.IsOpen) {
        $port.Close()
        Write-Host ""
        Write-Host "Port closed." -ForegroundColor Cyan
    }
}
