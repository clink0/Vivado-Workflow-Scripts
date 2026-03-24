# Serial Monitor for UART Testing
# Usage: Run this script in PowerShell
# Adjust $portName and $baudRate as needed

$portName = "COM13"   # Change this to your COM port (check Device Manager)
$baudRate = 19200
$parity   = [System.IO.Ports.Parity]::None
$dataBits = 8
$stopBits = [System.IO.Ports.StopBits]::One

$port = New-Object System.IO.Ports.SerialPort $portName, $baudRate, $parity, $dataBits, $stopBits
$port.ReadTimeout  = 500
$port.WriteTimeout = 500

try {
    $port.Open()
    Write-Host "Connected to $portName at $baudRate baud (Even Parity)" -ForegroundColor Green
    Write-Host "Press Ctrl+C to exit" -ForegroundColor Yellow
    Write-Host "----------------------------------------"

    while ($true) {
        # Read and display any incoming data
        try {
            $byte = $port.ReadByte()
            $char = [char]$byte
            Write-Host "RX: $char  (dec=$byte  hex=0x$($byte.ToString('X2')))" -ForegroundColor Cyan
        } catch [System.TimeoutException] {
            # No data yet, keep waiting
        }
    }
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
} finally {
    if ($port.IsOpen) {
        $port.Close()
        Write-Host "Port closed." -ForegroundColor Yellow
    }
}
