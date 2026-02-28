@echo off
setlocal

:: Get the drive letter and path of the directory where this script resides (the USB root)
set "ORION_ROOT=%~dp0"

:: Remove the trailing backslash so it's clean, e.g., "E:\ORION_USB"
if "%ORION_ROOT:~-1%"=="\" set "ORION_ROOT=%ORION_ROOT:~0,-1%"

echo ==================================================
echo [ORION] Booting from USB Drive: %ORION_ROOT%
echo ==================================================

:: Pre-flight Integrity Checks
if not exist "%ORION_ROOT%\models\Meta-Llama-3-8B-Instruct.Q4_K_S.gguf" (
    echo [ERROR] Required Llama GGUF model not found in \models.
    echo Please ensure the USB drive contains the full ORION release.
    pause
    exit /b 1
)

:: Activate Portable Virtual Environment if present
if exist "%ORION_ROOT%\venv\Scripts\activate.bat" (
    echo [ORION] Activating Portable Python Environment...
    call "%ORION_ROOT%\venv\Scripts\activate.bat"
) else if exist "%ORION_ROOT%\env\ORION-env\Scripts\activate.bat" (
    echo [ORION] Activating Portable Python Environment...
    call "%ORION_ROOT%\env\ORION-env\Scripts\activate.bat"
) else if exist "%ORION_ROOT%\env\Scripts\activate.bat" (
    echo [ORION] Activating Portable Python Environment...
    call "%ORION_ROOT%\env\Scripts\activate.bat"
) else (
    echo [WARNING] No portable virtual environment found. Assuming Host Python is configured.
)

:: Ensure the persistent memory and outputs directories exist on the USB
if not exist "%ORION_ROOT%\brain\outputs" (
    echo [ORION] Creating persistent brain/outputs directory on USB...
    mkdir "%ORION_ROOT%\brain\outputs"
)

if not exist "%ORION_ROOT%\brain\jobs" (
    echo [ORION] Creating persistent brain/jobs directory on USB...
    mkdir "%ORION_ROOT%\brain\jobs"
)

:: Start the Python Backend
echo [ORION] Starting Core Backend...
start "ORION Core" cmd /c "cd /d "%ORION_ROOT%\core" && python server.py"

:: Delay momentarily to ensure the server reserves port 3000
ping 127.0.0.1 -n 4 >nul

:: Start the React Frontend
echo [ORION] Starting Frontend UI...
:: We use call to prevent npm from exiting the script
start "ORION UI" cmd /c "cd /d "%ORION_ROOT%\orion_ui" && npm run dev"

echo [ORION] Boot sequence complete. Do not close this window if you want to see boot logs.
echo ==================================================
