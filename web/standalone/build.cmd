@echo off
setlocal
if not defined EMSDK_NODE (
    echo Activate Emscripten 5.0.3 with emsdk_env.bat first.
    exit /b 1
)
set "CACHE=%~dp0..\..\build\web\CMakeCache.txt"
if not exist "%CACHE%" (
    echo Build web/build.cmd first: its wasm libraries are required.
    exit /b 1
)
for /f "tokens=1,* delims==" %%A in ('findstr /b "CMAKE_MAKE_PROGRAM:" "%CACHE%"') do set "NINJA=%%B"
call emcmake cmake -S "%~dp0." -B "%~dp0..\..\build\web-standalone" -G Ninja -DCMAKE_BUILD_TYPE=Release "-DCMAKE_MAKE_PROGRAM=%NINJA%" "-DNODE_EXECUTABLE=%EMSDK_NODE%" %*
if errorlevel 1 exit /b 1
cmake --build "%~dp0..\..\build\web-standalone" --parallel 6
