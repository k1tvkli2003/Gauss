param(
    [Parameter(Mandatory = $true)]
    [string]$DeviceId,

    [ValidateRange(1, 20)]
    [int]$Runs = 5,

    [string]$OutputDirectory = "../docs/codex/2026-08-21-gauss-android-ui-ux-perfection-and-performance/logs/performance-baseline"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$appRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$outputRoot = [System.IO.Path]::GetFullPath((Join-Path $appRoot $OutputDirectory))
$driverPath = "test_driver/performance_driver.dart"
$targetPath = "tool/perf_main.dart"
$originalGradleOptions = $env:GRADLE_OPTS
$originalPerformanceOutput = $env:GAUSS_PERF_OUTPUT

function Invoke-AdbText {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)

    $output = & adb -s $DeviceId @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "adb failed: $($Arguments -join ' ')`n$($output -join "`n")"
    }
    return ($output -join "`n").Trim()
}

function Get-PackageSnapshot {
    param([string]$PackageName)

    $dump = Invoke-AdbText shell dumpsys package $PackageName
    if ([string]::IsNullOrWhiteSpace($dump) -or $dump -match "Unable to find package") {
        return [ordered]@{
            installed = $false
            package = $PackageName
        }
    }

    $selected = $dump -split "`r?`n" | Where-Object {
        $_ -match "versionCode=|versionName=|firstInstallTime=|lastUpdateTime=|dataDir="
    } | ForEach-Object { $_.Trim() }
    $canonical = ($selected | Sort-Object) -join "`n"
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($canonical)
    $hash = [System.Security.Cryptography.SHA256]::HashData($bytes)

    return [ordered]@{
        installed = $true
        package = $PackageName
        metadata = $selected
        metadata_sha256 = [Convert]::ToHexString($hash).ToLowerInvariant()
    }
}

if (-not (Get-Command adb -ErrorAction SilentlyContinue)) {
    throw "adb is not available on PATH."
}
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw "flutter is not available on PATH."
}

$deviceState = Invoke-AdbText get-state
if ($deviceState -ne "device") {
    throw "Android target '$DeviceId' is not ready (state: '$deviceState')."
}

New-Item -ItemType Directory -Force -Path $outputRoot | Out-Null

# Gradle does not consistently honor HTTP(S)_PROXY on Windows. Forward only
# the non-secret host and port as JVM properties for this process; credentials,
# if any, are intentionally neither copied nor logged.
$proxyValue = if ($env:HTTPS_PROXY) { $env:HTTPS_PROXY } else { $env:HTTP_PROXY }
if ($proxyValue) {
    $proxyUri = [Uri]$proxyValue
    $proxyFlags = @(
        "-Dhttp.proxyHost=$($proxyUri.Host)",
        "-Dhttp.proxyPort=$($proxyUri.Port)",
        "-Dhttps.proxyHost=$($proxyUri.Host)",
        "-Dhttps.proxyPort=$($proxyUri.Port)"
    ) -join " "
    $env:GRADLE_OPTS = @($originalGradleOptions, $proxyFlags) |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        Join-String -Separator " "
}

$deviceProperties = [ordered]@{
    serial = $DeviceId
    state = $deviceState
    manufacturer = Invoke-AdbText shell getprop ro.product.manufacturer
    model = Invoke-AdbText shell getprop ro.product.model
    device = Invoke-AdbText shell getprop ro.product.device
    sdk = Invoke-AdbText shell getprop ro.build.version.sdk
    release = Invoke-AdbText shell getprop ro.build.version.release
    build_fingerprint = Invoke-AdbText shell getprop ro.build.fingerprint
    wm_size = Invoke-AdbText shell wm size
    wm_density = Invoke-AdbText shell wm density
    surface_flinger_refresh = Invoke-AdbText shell dumpsys SurfaceFlinger --display-id
}
$signedPackageBefore = Get-PackageSnapshot "com.gauss.app"

[ordered]@{
    captured_at_utc = [DateTime]::UtcNow.ToString("o")
    flutter = (& flutter --version --machine | ConvertFrom-Json)
    device = $deviceProperties
    signed_package_before = $signedPackageBefore
    requested_runs = $Runs
} | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $outputRoot "environment.json") -Encoding utf8

Push-Location $appRoot
try {
    for ($run = 1; $run -le $Runs; $run++) {
        $runLabel = "run-{0:d2}" -f $run
        $logPath = Join-Path $outputRoot "$runLabel.log"
        $runDirectory = Join-Path $outputRoot $runLabel
        $journeyPath = Join-Path $runDirectory "journeys.json"
        if (Test-Path -LiteralPath $journeyPath) {
            throw "$runLabel already contains performance evidence; choose a fresh output directory."
        }
        New-Item -ItemType Directory -Force -Path $runDirectory | Out-Null
        $env:GAUSS_PERF_OUTPUT = $runDirectory

        $arguments = @(
            "drive",
            "--profile",
            "--no-pub",
            "--device-id", $DeviceId,
            "--driver", $driverPath,
            "--target", $targetPath,
            "--no-keep-app-running"
        )
        & flutter @arguments 2>&1 | Tee-Object -FilePath $logPath
        if ($LASTEXITCODE -ne 0) {
            throw "Performance journey failed during $runLabel. See $logPath."
        }
        if (-not (Test-Path -LiteralPath $journeyPath)) {
            throw "Performance journey did not emit $journeyPath during $runLabel."
        }
    }
}
finally {
    Pop-Location
    $env:GRADLE_OPTS = $originalGradleOptions
    $env:GAUSS_PERF_OUTPUT = $originalPerformanceOutput
}

$signedPackageAfter = Get-PackageSnapshot "com.gauss.app"
$preserved = ($signedPackageBefore | ConvertTo-Json -Depth 6 -Compress) -eq
    ($signedPackageAfter | ConvertTo-Json -Depth 6 -Compress)

[ordered]@{
    captured_at_utc = [DateTime]::UtcNow.ToString("o")
    requested_runs = $Runs
    completed_runs = @(
        Get-ChildItem -LiteralPath $outputRoot -Directory -Filter "run-*" |
            Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName "journeys.json") }
    ).Count
    signed_package_before = $signedPackageBefore
    signed_package_after = $signedPackageAfter
    signed_package_preserved = $preserved
} | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $outputRoot "run-summary.json") -Encoding utf8

if (-not $preserved) {
    throw "The signed com.gauss.app package metadata changed during the isolated profile run."
}

Write-Host "Completed $Runs isolated profile runs. Evidence: $outputRoot"
