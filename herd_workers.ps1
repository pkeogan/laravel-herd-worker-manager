# Ensure worker_*.log and worker_pids.txt are in .gitignore
$gitignorePath = Join-Path (Get-Location) ".gitignore"
$entriesToAdd = @("worker_*.log", "worker_pids.txt")

if (Test-Path $gitignorePath) {
    $gitignoreContent = Get-Content $gitignorePath -Raw
    foreach ($entry in $entriesToAdd) {
        if ($gitignoreContent -notmatch [regex]::Escape($entry)) {
            Add-Content $gitignorePath "`n$entry"
        }
    }
} else {
    $entriesToAdd | Out-File $gitignorePath
}

# Original script starts here
$phpPath = (Get-Command php -ErrorAction Stop).Source
$artisanPath = Join-Path (Get-Location) "artisan"
$pidFile = "worker_pids.txt"
$processIds = @()

# Function to start workers
function Start-Workers {
    param ([int]$workerCount)
    $script:processIds = @()
    for ($i = 1; $i -le $workerCount; $i++) {
        $logFile = "worker_$i.log"
        $proc = Start-Process -FilePath $phpPath -ArgumentList $artisanPath, "queue:work" -RedirectStandardOutput $logFile -NoNewWindow -PassThru
        $script:processIds += $proc.Id
    }
    $script:processIds | Out-File $pidFile
    Write-Host "$workerCount workers started. Process IDs saved to $pidFile"
}

# Function to check if workers are running
function Get-ActiveWorkers {
    $phpWorkers = Get-WmiObject Win32_Process -Filter "Name = 'php.exe'" -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like "*queue:work*" }
    if ($phpWorkers) {
        return @($phpWorkers).Count
    } else {
        return 0
    }
}

# Main logic
if (Test-Path $pidFile) {
    $runningPids = Get-Content $pidFile
    $activeWorkers = Get-ActiveWorkers
    if ($activeWorkers -gt 0) {
        Write-Host "$activeWorkers worker(s) are currently running."
    } else {
        Write-Host "worker_pids.txt exists but no PHP workers detected."
    }
    $stopChoice = Read-Host "Do you want to stop all workers and delete logs? (y/n)"
    if ($stopChoice -eq 'y' -or $stopChoice -eq 'Y') {
        # Stop cmd.exe processes from worker_pids.txt
        foreach ($workerPid in $runningPids) {
            try {
                Stop-Process -Id $workerPid -Force -ErrorAction Stop
                Write-Host "Stopped cmd.exe process ID: $workerPid"
            } catch {
                Write-Host "cmd.exe process ID $workerPid already stopped or not found."
            }
        }

        # Stop all php.exe processes running queue:work
        $phpWorkers = Get-WmiObject Win32_Process -Filter "Name = 'php.exe'" -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like "*queue:work*" }
        foreach ($worker in $phpWorkers) {
            try {
                Stop-Process -Id $worker.ProcessId -Force -ErrorAction Stop
                Write-Host "Stopped PHP process ID: $($worker.ProcessId)"
            } catch {
                Write-Host "PHP process ID $($worker.ProcessId) already stopped or not found."
            }
        }

        # Wait briefly to release file handles
        Start-Sleep -Seconds 2

        # Delete PID file
        Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
        Write-Host "Deleted $pidFile"

        # Delete log files with retry mechanism
        for ($i = 1; $i -le 32; $i++) {
            $logFile = "worker_$i.log"
            if (Test-Path $logFile) {
                $retryCount = 0
                $maxRetries = 5
                while ($retryCount -lt $maxRetries) {
                    try {
                        Remove-Item $logFile -Force -ErrorAction Stop
                        Write-Host "Deleted $logFile"
                        break
                    } catch {
                        $retryCount++
                        if ($retryCount -eq $maxRetries) {
                            Write-Host "Failed to delete $logFile after $maxRetries attempts: $($_.Exception.Message)"
                        } else {
                            Start-Sleep -Seconds 1
                            Write-Host "Retrying deletion of $logFile ($retryCount/$maxRetries)..."
                        }
                    }
                }
            }
        }
        Write-Host "All workers stopped and logs deleted."
    } else {
        Write-Host "No changes made. Exiting."
    }
} else {
    $activeWorkers = Get-ActiveWorkers
    if ($activeWorkers -gt 0) {
        Write-Host "$activeWorkers worker(s) are running but no worker_pids.txt found."
        $stopChoice = Read-Host "Do you want to stop them? (y/n)"
        if ($stopChoice -eq 'y' -or $stopChoice -eq 'Y') {
            $phpWorkers = Get-WmiObject Win32_Process -Filter "Name = 'php.exe'" -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like "*queue:work*" }
            foreach ($worker in $phpWorkers) {
                try {
                    Stop-Process -Id $worker.ProcessId -Force -ErrorAction Stop
                    Write-Host "Stopped PHP process ID: $($worker.ProcessId)"
                } catch {
                    Write-Host "PHP process ID $($worker.ProcessId) already stopped or not found."
                }
            }
            Write-Host "All workers stopped."
        } else {
            Write-Host "No changes made. Exiting."
        }
    } else {
        $startChoice = Read-Host "No workers are running. Do you want to start some? (y/n)"
        if ($startChoice -eq 'y' -or $startChoice -eq 'Y') {
            $workerCount = Read-Host "How many workers do you want to start? (1-32)"
            if ($workerCount -match '^\d+$' -and [int]$workerCount -ge 1 -and [int]$workerCount -le 32) {
                Start-Workers -workerCount $workerCount
            } else {
                Write-Host "Invalid input. Please enter a number between 1 and 32."
            }
        } else {
            Write-Host "No workers started. Exiting."
        }
    }
}
