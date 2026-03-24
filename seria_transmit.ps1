# Serial Transmitter for UART Testing (Tasks 3 and 4)
# Usage: Run this script in PowerShell
# Adjust $portName as needed

$portName = "COM13"   # Change this to your COM port (check Device Manager)
$baudRate = 19200
$parity   = [System.IO.Ports.Parity]::Even
$dataBits = 8
$stopBits = [System.IO.Ports.StopBits]::One

$port = New-Object System.IO.Ports.SerialPort $portName, $baudRate, $parity, $dataBits, $stopBits
$port.ReadTimeout  = 500
$port.WriteTimeout = 500

try {
    $port.Open()
    Write-Host "Connected to $portName at $baudRate baud (Even Parity)" -ForegroundColor Green
    Write-Host "Type a character and press Enter to send it to the FPGA" -ForegroundColor Yellow
    Write-Host "Type 'exit' to quit" -ForegroundColor Yellow
    Write-Host "----------------------------------------"

    while ($true) {
        $input = Read-Host "Send"
        if ($input -eq "exit") { break }
        if ($input.Length -gt 0) {
            $char = $input[0]
            $byte = [byte][char]$char
            $port.Write([byte[]]@($byte), 0, 1)
            Write-Host "TX: $char  (dec=$byte  hex=0x$($byte.ToString('X2')))" -ForegroundColor Magenta
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
