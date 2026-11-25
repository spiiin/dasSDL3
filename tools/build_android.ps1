[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$AotTool,
    [string]$SdlSource,
    [string]$AndroidSdk = $env:ANDROID_HOME,
    [string]$JavaHome = $env:JAVA_HOME,
    [switch]$Run,
    [string]$Serial
)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path "$PSScriptRoot/..").Path
$native = "$root/build/android-native"
$stage = "$root/build/android-stage"
if (!$AndroidSdk) { $AndroidSdk = "$env:LOCALAPPDATA/Android/Sdk" }
if (!$JavaHome) { $JavaHome = "$env:ProgramFiles/Android/Android Studio/jbr" }
$env:ANDROID_HOME = (Resolve-Path $AndroidSdk).Path
$env:JAVA_HOME = (Resolve-Path $JavaHome).Path
$ndk = "$env:ANDROID_HOME/ndk/28.2.13676358"
$bin = "$env:ANDROID_HOME/cmake/3.31.6/bin"
$tool = (Resolve-Path $AotTool).Path

function Invoke-Checked([string]$Program, [string[]]$Arguments) {
    & $Program @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$Program exited with code $LASTEXITCODE" }
}

$sourceOverride = ''
if ($SdlSource) { $sourceOverride = (Resolve-Path $SdlSource).Path }
Invoke-Checked "$bin/cmake.exe" @('-S', "$root/android", '-B', $native, '-G', 'Ninja',
    "-DCMAKE_MAKE_PROGRAM=$bin/ninja.exe", "-DCMAKE_TOOLCHAIN_FILE=$ndk/build/cmake/android.toolchain.cmake",
    '-DANDROID_ABI=arm64-v8a', '-DANDROID_PLATFORM=android-28', '-DANDROID_STL=c++_shared',
    '-DCMAKE_BUILD_TYPE=Release', "-DDASSDL3_HOST_AOT_TOOL=$tool", "-DFETCHCONTENT_SOURCE_DIR_SDL3=$sourceOverride")
Invoke-Checked "$bin/cmake.exe" @('--build', $native, '--target', 'main', '--parallel', '6')
Invoke-Checked "$bin/cmake.exe" @('--install', $native, '--strip', '--component', 'android-apk', '--prefix', $stage)
if (!$SdlSource) { $SdlSource = "$native/_deps/sdl3-src" }
Invoke-Checked "$SdlSource/android-project/gradlew.bat" @('-p', "$root/android", 'assembleDebug')
$apk = (Get-Item "$root/build/android-apk/outputs/apk/debug/*.apk").FullName
Write-Host "Android smoke APK: $apk"
if (!$Run) { return }

$adb = "$env:ANDROID_HOME/platform-tools/adb.exe"
$device = if ($Serial) { @('-s', $Serial) } else { @('-d') }
function Invoke-Device([string[]]$Arguments) {
    Invoke-Checked $adb (@($device) + $Arguments)
}
Invoke-Device @('install', '-r', $apk)
Invoke-Device @('shell', 'am', 'force-stop', 'org.dassdl3.smoke')
# Delimit this launch without clearing any existing device logs.
$marker = [guid]::NewGuid().ToString()
Invoke-Device @('shell', 'log', '-t', 'dasSDL3Launch', $marker)
Invoke-Device @('shell', 'am', 'start', '-W', '-n', 'org.dassdl3.smoke/org.libsdl.app.SDLActivity')
$deadline = (Get-Date).AddSeconds(60)
do {
    $logs = (Invoke-Device @('logcat', '-d', '-s', 'dasSDL3Launch:I', 'SDL/APP:I', 'AndroidRuntime:E')) -join "`n"
    $start = $logs.LastIndexOf($marker)
    if ($start -ge 0) {
        $runLogs = $logs.Substring($start)
        if ($runLogs.Contains('dasSDL3 Android smoke FAIL')) { throw $runLogs }
        if ($runLogs.Contains('dasSDL3 Android smoke PASS')) {
            $runLogs -split "`n" | Select-String 'dasSDL3 Android'
            return
        }
    }
    Start-Sleep -Seconds 1
} while ((Get-Date) -lt $deadline)
throw "No Android smoke PASS within 60 seconds. Launch log:`n$runLogs"
