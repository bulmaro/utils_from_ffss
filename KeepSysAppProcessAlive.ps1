function Wait-A-Bit([string]$Activity, [string]$Status, [int]$SleepTime) {
    if ($SleepTime -eq 0) # When no SleepTime was specified, briefly show info with no progress bar
    {
        Write-Progress -Activity "$(Get-TimeStamp): ${Activity}" -Status $Status
        Start-Sleep -Seconds 1
    }
    else {
        for($Seconds = 1; $Seconds -lt $SleepTime + 1; $Seconds++) {
            Write-Progress -Activity "$(Get-TimeStamp): ${Activity}" -Status $Status -PercentComplete ($Seconds / $SleepTime * 100)
            Start-Sleep -Seconds 1
        }
    }
}

function Get-TimeStamp {
    return Get-Date -Format "MM/dd/yyyy HH:mm:ss"
}

$ProcessName = "SysApp"
$ExecutablePath = "C:\FFSS\debug\x64\Host\SysApp\SysApp.exe"
$MonitoringMessage = "Keeping '$ProcessName' alive."

$sig = '[DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);'
Add-Type -MemberDefinition $sig -name NativeMethods -namespace Win32

Write-Host "------------------------------------------"
Write-Host "Script to keep process '$ProcessName' alive by running '$ExecutablePath'."
Write-Host "Press Ctrl-C to stop."
Write-Host "------------------------------------------"

try
{
    while ($true)
    {
        Wait-A-Bit $MonitoringMessage "Checking if process is running..."
        $process = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue

        if ($null -eq $process)
        {
            Write-Host -NoNewLine "$( Get-TimeStamp ): Process '$ProcessName' is not running, starting it..."
            Start-Process $ExecutablePath
            Wait-A-Bit "Rebooting '$ProcessName'." "Waiting to stabilize, hopefully in 10 sec..." 10
            Write-Host " Started."
            $handle = @(Get-Process $ProcessName)[0].MainWindowHandle
            $null = [Win32.NativeMethods]::ShowWindowAsync($handle, 3)
            Continue
        }

        Wait-A-Bit $MonitoringMessage "Sleeping 20 sec..." 20
    }
}
finally {
    Write-Host "$( Get-TimeStamp ): Now killing '$ProcessName'."
    Stop-Process -Name $ProcessName -Force
}
