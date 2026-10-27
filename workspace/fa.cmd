@echo off
rem fa - single entry point of the fuzzyalgo workspace. Overview: fa help
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0fa.ps1" %*
exit /b %ERRORLEVEL%
