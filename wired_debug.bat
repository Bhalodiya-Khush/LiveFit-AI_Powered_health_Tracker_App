@echo off
echo ========================================================
echo   LiveFit - Wired USB Debug Port Forwarding
echo ========================================================
echo.

where adb >nul 2>nul
if %errorlevel% neq 0 (
  set ADB="%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe"
) else (
  set ADB=adb
)

echo Running: adb reverse tcp:5050 tcp:5050 ...
%ADB% reverse tcp:5050 tcp:5050
if %errorlevel% equ 0 (
  echo.
  echo [SUCCESS] Port 5050 forwarded!
  echo Your Android phone can now connect to http://127.0.0.1:5050/api over USB.
  echo.
) else (
  echo.
  echo [FAILED] Make sure:
  echo   1. Your phone is connected via USB cable
  echo   2. USB Debugging is ENABLED in Developer Options
  echo   3. You tapped 'Allow' on your phone's screen
  echo.
)
pause
