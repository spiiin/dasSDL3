@echo off
where emcmake >nul 2>nul
if errorlevel 1 (
    echo Activate Emscripten 5.0.3 with emsdk_env.bat first.
    exit /b 1
)
call emcmake cmake -S "%~dp0." -B "%~dp0..\build\web" -G Ninja -DCMAKE_BUILD_TYPE=Release %*
if errorlevel 1 exit /b 1
cmake --build "%~dp0..\build\web" --target dassdl3_web --parallel 6
