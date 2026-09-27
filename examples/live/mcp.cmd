@echo off
setlocal
for %%I in ("%~dp0..\..") do set "SDL_ROOT=%%~fI"
"%SDL_ROOT%\third_party\daScript\bin\daslang.exe" -dasroot "%SDL_ROOT%\third_party\daScript" -load_module "%SDL_ROOT%\build\live-http\dasHV" -ignore-manifest "%SDL_ROOT%\third_party\daScript\utils\mcp\main.das"
exit /b %errorlevel%
