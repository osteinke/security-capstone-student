# install-mongodb-windows.ps1
# Installs MongoDB Community Server via winget and starts the MongoDB service.
# Run PowerShell as Administrator.

$ErrorActionPreference = "Stop"

function Assert-Admin {
  $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
  ).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
  if (-not $isAdmin) { throw "Run this script as Administrator." }
}

function Install-Winget {
  Write-Host "winget not found. Installing winget (App Installer)..."
  
  # Enable TLS 1.2 for downloads (required on older PowerShell versions)
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  
  # Create temp directory for downloads
  $tempDir = Join-Path $env:TEMP "winget-install"
  New-Item -ItemType Directory -Force -Path $tempDir | Out-Null
  
  # Helper function for robust downloads with retry
  function Download-File($url, $outPath, $description) {
    $maxRetries = 3
    for ($i = 1; $i -le $maxRetries; $i++) {
      try {
        Write-Host "Downloading $description (attempt $i of $maxRetries)..."
        # Use WebClient for more reliable large file downloads
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($url, $outPath)
        Write-Host "  Downloaded successfully." -ForegroundColor Green
        return
      }
      catch {
        Write-Host "  Download failed: $_" -ForegroundColor Yellow
        if ($i -eq $maxRetries) {
          throw "Failed to download $description after $maxRetries attempts."
        }
        Start-Sleep -Seconds 2
      }
      finally {
        if ($webClient) { $webClient.Dispose() }
      }
    }
  }
  
  try {
    # Download dependencies and winget
    $vcLibsUrl = "https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx"
    $uiXamlUrl = "https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.8.6/Microsoft.UI.Xaml.2.8.x64.appx"
    $wingetUrl = "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
    
    $vcLibsPath = Join-Path $tempDir "Microsoft.VCLibs.x64.14.00.Desktop.appx"
    $uiXamlPath = Join-Path $tempDir "Microsoft.UI.Xaml.2.8.x64.appx"
    $wingetPath = Join-Path $tempDir "Microsoft.DesktopAppInstaller.msixbundle"
    
    Download-File $vcLibsUrl $vcLibsPath "VCLibs dependency"
    Download-File $uiXamlUrl $uiXamlPath "UI.Xaml dependency"
    Download-File $wingetUrl $wingetPath "winget"
    
    Write-Host "Installing dependencies..."
    Add-AppxPackage -Path $vcLibsPath
    Add-AppxPackage -Path $uiXamlPath
    
    Write-Host "Installing winget..."
    Add-AppxPackage -Path $wingetPath
    
    # Refresh PATH so winget is available
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    
    # Give it a moment to register
    Start-Sleep -Seconds 3
    
    # Verify installation
    if (-not (Get-Command "winget" -ErrorAction SilentlyContinue)) {
      # Try to find winget in the WindowsApps folder
      $wingetExe = Get-ChildItem -Path "$env:ProgramFiles\WindowsApps" -Filter "winget.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
      if ($wingetExe) {
        $env:Path += ";" + $wingetExe.DirectoryName
      } else {
        throw "winget installation completed but winget command not found. Please restart your terminal or computer and try again."
      }
    }
    
    Write-Host "winget installed successfully!" -ForegroundColor Green
  }
  finally {
    # Cleanup temp files
    Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
  }
}

function Ensure-Winget {
  if (-not (Get-Command "winget" -ErrorAction SilentlyContinue)) {
    Install-Winget
  } else {
    Write-Host "winget is already installed."
  }
}

Assert-Admin
Ensure-Winget

Write-Host "Installing MongoDB Community Server..."
winget install --id MongoDB.Server -e --accept-package-agreements --accept-source-agreements

Write-Host "Starting MongoDB service..."
$svc = Get-Service -Name "MongoDB" -ErrorAction SilentlyContinue
if (-not $svc) {
  Write-Host "MongoDB service not found. Listing possible services:"
  Get-Service | Where-Object { $_.Name -like "*mongo*" -or $_.DisplayName -like "*mongo*" } |
    Format-Table Name, DisplayName, Status -AutoSize
  throw "MongoDB service not found."
}

if ($svc.Status -ne "Running") { Start-Service -Name "MongoDB" }
Write-Host "MongoDB is running."
Write-Host "Test with: mongosh mongodb://localhost:27017"
