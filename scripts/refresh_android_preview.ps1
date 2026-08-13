[CmdletBinding()]
param(
    [string]$Device = 'emulator-5554',
    [ValidateSet('debug', 'profile')]
    [string]$Mode = 'debug',
    [switch]$SkipBuild
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$flutterRoot = Join-Path $projectRoot 'flutter_app'
$packageName = if ($Mode -eq 'debug') {
    'com.gauss.app.debug'
} else {
    'com.gauss.app.profile'
}
$apkPath = Join-Path $flutterRoot "build\app\outputs\flutter-apk\app-$Mode.apk"

$connected = (& adb devices | Out-String)
if ($LASTEXITCODE -ne 0 -or $connected -notmatch "(?m)^$([regex]::Escape($Device))\s+device\b") {
    throw "Android preview device '$Device' is not connected and ready."
}

function Get-ProjectVersionCode {
    $versionLine = Select-String -Path (Join-Path $flutterRoot 'pubspec.yaml') -Pattern '^\s*version:\s*[^+]+\+(\d+)\s*$' | Select-Object -First 1
    if ($null -eq $versionLine) {
        throw 'Could not read a numeric Flutter version code from pubspec.yaml.'
    }
    return [int]$versionLine.Matches[0].Groups[1].Value
}

function Get-InstalledVersionCode {
    param([string]$PackageName)

    $packageDump = (& adb -s $Device shell dumpsys package $PackageName 2>$null | Out-String)
    $match = [regex]::Match($packageDump, 'versionCode=(\d+)')
    if ($match.Success) {
        return [int]$match.Groups[1].Value
    }
    return 0
}

# Android refuses an APK whose versionCode is not newer than the already
# installed preview. Give each debug/profile refresh an ephemeral monotonic
# code without modifying pubspec or the signed com.gauss.app package.
$installedPreviewVersionCode = Get-InstalledVersionCode -PackageName $packageName
$configuredVersionCode = if ($env:GAUSS_VERSION_CODE -match '^\d+$') {
    [int]$env:GAUSS_VERSION_CODE
} else {
    Get-ProjectVersionCode
}
$previewVersionCode = [Math]::Max(
    $configuredVersionCode,
    $installedPreviewVersionCode + 1
)

Push-Location $flutterRoot
try {
    if (-not $SkipBuild) {
        # Flutter forwards --build-number as a Gradle property on every build;
        # unlike a process environment mutation it remains reliable when a
        # warm Gradle daemon is serving repeated live-refresh builds.
        & flutter build apk "--$Mode" --no-pub "--build-number=$previewVersionCode"
        if ($LASTEXITCODE -ne 0) {
            throw "Flutter $Mode APK build failed."
        }
    }

    if (-not (Test-Path -LiteralPath $apkPath -PathType Leaf)) {
        throw "Preview APK is missing: $apkPath"
    }

    # `install -r` preserves the preview variant's local state. Debug/profile
    # use dedicated application IDs, so the signed personal package and its
    # data are never uninstalled, replaced, or cleared by this workflow.
    & adb -s $Device install -r $apkPath
    if ($LASTEXITCODE -ne 0) {
        throw "Installing the $Mode preview APK failed."
    }

    & adb -s $Device shell am force-stop $packageName
    if ($LASTEXITCODE -ne 0) {
        throw "Stopping the prior $Mode preview failed."
    }
    & adb -s $Device shell monkey -p $packageName -c android.intent.category.LAUNCHER 1
    if ($LASTEXITCODE -ne 0) {
        throw "Launching the $Mode preview failed."
    }

    Write-Output "Gauss $Mode preview refreshed on $Device as $packageName (versionCode $previewVersionCode)."
} finally {
    Pop-Location
}
