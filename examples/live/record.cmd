@echo off
setlocal
python "%~dp0..\..\tools\record_live.py" %*
exit /b %errorlevel%
