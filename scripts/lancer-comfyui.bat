@echo off
rem Lance ComfyUI portable sur le port 8189 et ouvre l'interface.
rem Garde cette fenêtre ouverte pendant que tu utilises ComfyUI.
set COMFY=C:\ComfyUI\ComfyUI_windows_portable
set PORT=8189

if not exist "%COMFY%\python_embeded\python.exe" (
  echo ComfyUI introuvable dans %COMFY%
  pause
  exit /b 1
)

cd /d "%COMFY%"
start "" cmd /c "timeout /t 20 /nobreak >nul & start http://127.0.0.1:%PORT%"
.\python_embeded\python.exe -s ComfyUI\main.py --windows-standalone-build --port %PORT%
pause
