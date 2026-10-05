@echo off
rem Glisse-dépose une vidéo sur ce fichier : la première image est enregistrée à côté.
set COMFY=C:\ComfyUI\ComfyUI_windows_portable
if "%~1"=="" (
  echo Glisse une video sur ce fichier.
  pause
  exit /b 1
)
"%COMFY%\python_embeded\python.exe" "%~dp0extraire-image.py" "%~1" %2
pause
