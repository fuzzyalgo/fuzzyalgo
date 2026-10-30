@echo off
rem fa - single entry point of the fuzzyalgo workspace for cmd and VS Code tasks (in PowerShell "fa" runs fa.ps1 itself).
rem powershell.exe appends the arguments to the -Command code after #FA_ARGS#, where they are a comment;
rem fa.ps1 reads them unchanged from its command line.
setlocal DisableDelayedExpansion
set "FA_PS1=%~dp0fa.ps1"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$LASTEXITCODE = 1; & $env:FA_PS1; exit $LASTEXITCODE #FA_ARGS#" %*
exit /b %ERRORLEVEL%
