# Run using Windows PowerShell 5.1 or PowerShell 7. No SDK/Python is required.
[CmdletBinding()]
param(
    [string]$Kit = "",
    [string]$OutputDirectory = "",
    [string]$RunLabel = "unspecified host"
)
$ErrorActionPreference = "Stop"
if (!$Kit) { $Kit = Split-Path -Parent $MyInvocation.MyCommand.Path }
$kitRoot = (Resolve-Path -LiteralPath $Kit).Path
if (!$OutputDirectory) {
    $OutputDirectory = Join-Path $env:TEMP ("dasSDL3 verification " + [guid]::NewGuid().ToString("N"))
}
if (Test-Path -LiteralPath $OutputDirectory) {
    throw "Choose a new output directory: $OutputDirectory"
}
$reportRoot = (New-Item -ItemType Directory -Path $OutputDirectory).FullName
$report = [ordered]@{
    label = $RunLabel
    utc = [DateTime]::UtcNow.ToString("o")
    computer = $env:COMPUTERNAME
    os = [Environment]::OSVersion.VersionString
    process64 = [Environment]::Is64BitProcess
    kit = $kitRoot
    note = "This report records execution, not proof that the host is a clean VM."
    hashCheck = $false
    runs = @()
    success = $false
    error = $null
}
try {
    if (![Environment]::Is64BitProcess) { throw "Run 64-bit PowerShell on Windows x64." }
    $inventory = Get-Content -LiteralPath (Join-Path $kitRoot "files.json") -Raw | ConvertFrom-Json
    foreach ($file in $inventory) {
        if ([IO.Path]::IsPathRooted($file.path) -or $file.path -match '(^|[\\/])\.\.([\\/]|$)') {
            throw "Invalid inventory path: $($file.path)"
        }
        $path = Join-Path $kitRoot $file.path
        if (!(Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing file: $($file.path)" }
        $hasher = [Security.Cryptography.SHA256]::Create()
        $stream = [IO.File]::OpenRead($path)
        try { $actualHash = [BitConverter]::ToString($hasher.ComputeHash($stream)).Replace("-", "") }
        finally { $stream.Dispose(); $hasher.Dispose() }
        if ($actualHash -ne $file.sha256) {
            throw "Hash mismatch: $($file.path)"
        }
    }
    $report.hashCheck = $true
    # Prevent missing-runtime loader dialogs from blocking unattended checks.
    Add-Type -TypeDefinition @"
using System.Runtime.InteropServices;
public static class DasSdlReleaseErrorMode {
    [DllImport("kernel32.dll")]
    public static extern uint SetErrorMode(uint mode);
}
"@
    $oldMode = [DasSdlReleaseErrorMode]::SetErrorMode(0x8001)
    try {
        foreach ($caseName in @("core", "imgui")) {
            $executable = if ($caseName -eq "core") { "sdl3_package_demo.exe" } else { "sdl3_imgui_demo.exe" }
            $receipt = if ($caseName -eq "core") { "daspkg SDL core: rendered; resources released." } else { "ImGui backends, context and SDL resources released." }
            $working = (New-Item -ItemType Directory -Path (Join-Path $reportRoot $caseName)).FullName
            $info = New-Object System.Diagnostics.ProcessStartInfo
            $info.FileName = Join-Path (Join-Path $kitRoot $caseName) $executable
            $info.Arguments = if ($caseName -eq "imgui") { "--smoke" } else { "" }
            $info.WorkingDirectory = $working
            $info.UseShellExecute = $false
            $info.CreateNoWindow = $true
            $info.RedirectStandardOutput = $true
            $info.RedirectStandardError = $true
            $info.EnvironmentVariables.Clear()
            foreach ($key in @("SystemRoot", "WINDIR", "TEMP", "TMP", "USERPROFILE", "APPDATA", "LOCALAPPDATA", "COMSPEC")) {
                $value = [Environment]::GetEnvironmentVariable($key)
                if ($value) { $info.EnvironmentVariables[$key] = $value }
            }
            $info.EnvironmentVariables["PATH"] = Join-Path $env:SystemRoot "System32"
            $info.EnvironmentVariables["SDL_VIDEODRIVER"] = "dummy"
            $info.EnvironmentVariables["SDL_AUDIODRIVER"] = "dummy"
            $process = New-Object System.Diagnostics.Process
            $process.StartInfo = $info
            $run = [ordered]@{ profile = $caseName; exitCode = $null; timedOut = $false; success = $false; error = $null }
            try {
                [void]$process.Start()
                $stdout = $process.StandardOutput.ReadToEndAsync()
                $stderr = $process.StandardError.ReadToEndAsync()
                if (!$process.WaitForExit(30000)) {
                    $run.timedOut = $true
                    $process.Kill()
                    $process.WaitForExit()
                }
                $run.exitCode = $process.ExitCode
                $text = $stdout.Result + $stderr.Result
                [IO.File]::WriteAllText((Join-Path $reportRoot "$caseName.log"), $text)
                $run.success = !$run.timedOut -and $run.exitCode -eq 0 -and $text.Contains($receipt)
                if ($caseName -eq "imgui") { $run.success = $run.success -and $text.Contains("bright pixels verified.") }
            } catch {
                $run.error = $_.Exception.Message
            } finally {
                $process.Dispose()
            }
            $report.runs += $run
            Write-Host "$caseName : success=$($run.success), exit=$($run.exitCode), timeout=$($run.timedOut)"
        }
    } finally {
        [void][DasSdlReleaseErrorMode]::SetErrorMode($oldMode)
    }
    $report.success = @($report.runs | Where-Object { !$_.success }).Count -eq 0 -and $report.runs.Count -eq 2
} catch {
    $report.error = $_.Exception.Message
} finally {
    $report | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $reportRoot "report.json") -Encoding UTF8
    Write-Host "Report: $reportRoot"
}
if (!$report.success) {
    if ($report.error) { Write-Host $report.error }
    Write-Host "FAIL: inspect report.json and profile logs. Windows x64, AVX2 and the Microsoft VC runtime are required."
    exit 1
}
Write-Host "PASS: file hashes, core rendering, GUI pixels and resource cleanup."
exit 0
