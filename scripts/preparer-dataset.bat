@echo off
rem Glisse-dépose le dossier d'images de l'avatar sur ce fichier.
set COMFY=C:\ComfyUI\ComfyUI_windows_portable
if "%~1"=="" (
  echo Glisse le dossier des images de l'avatar sur ce fichier.
  pause
  exit /b 1
)
"%COMFY%\python_embeded\python.exe" "%~dp0preparer-dataset.py" "%~1" "C:\ComfyUI\dataset_avatar" avtr_ia
pause
