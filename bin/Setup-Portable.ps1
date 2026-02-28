param($UsbRoot)
$ErrorActionPreference = "Stop"

$OrionDir = "$UsbRoot\ORION_USB"
$PythonDir = "$OrionDir\python"
$PythonZip = "$OrionDir\python-embed.zip"
$PythonUrl = "https://www.python.org/ftp/python/3.11.9/python-3.11.9-embed-amd64.zip"

Write-Host "==============================="
Write-Host " SETUP PORTABLE PYTHON AND NODE"
Write-Host "==============================="

if (-not (Test-Path $PythonDir)) {
    Write-Host "Creating $PythonDir..."
    New-Item -ItemType Directory -Force -Path $PythonDir | Out-Null

    Write-Host "Downloading Python 3.11 Embedded..."
    Invoke-WebRequest -Uri $PythonUrl -OutFile $PythonZip

    Write-Host "Extracting Python..."
    Expand-Archive -Path $PythonZip -DestinationPath $PythonDir -Force
    Remove-Item $PythonZip

    Write-Host "Configuring Python for pip (uncommenting import site)..."
    $PthFile = Get-ChildItem -Path $PythonDir -Filter "python*._pth" | Select-Object -First 1
    $PthContent = Get-Content $PthFile.FullName
    $PthContent = $PthContent -replace "#import site", "import site"
    Set-Content -Path $PthFile.FullName -Value $PthContent

    Write-Host "Downloading get-pip.py..."
    Invoke-WebRequest -Uri "https://bootstrap.pypa.io/get-pip.py" -OutFile "$PythonDir\get-pip.py"

    Write-Host "Installing pip..."
    & "$PythonDir\python.exe" "$PythonDir\get-pip.py"

    Write-Host "Installing Core Dependencies..."
    $Env:PIP_CACHE_DIR = "$OrionDir\.cache\pip"
    & "$PythonDir\Scripts\pip.exe" install -r "$OrionDir\core\requirements.txt"
}
else {
    Write-Host "Portable Python already configured."
}



Write-Host "==============================="
Write-Host " PORTABLE ENVIRONMENT READY!"
Write-Host "==============================="
