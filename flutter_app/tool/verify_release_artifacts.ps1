[CmdletBinding()]
param(
    [string]$FlutterRoot,
    [string]$ApkPath,
    [string]$WebRoot,
    [switch]$AllowDebugSigningForLocalVerification
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($FlutterRoot)) {
    $FlutterRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
}
else {
    $FlutterRoot = (Resolve-Path -LiteralPath $FlutterRoot).Path
}

$repoRoot = (Resolve-Path -LiteralPath (Join-Path $FlutterRoot '..')).Path
if ([string]::IsNullOrWhiteSpace($ApkPath)) {
    $ApkPath = Join-Path $FlutterRoot 'build\app\outputs\flutter-apk\app-release.apk'
}
if ([string]::IsNullOrWhiteSpace($WebRoot)) {
    $WebRoot = Join-Path $FlutterRoot 'build\web'
}

$ApkPath = (Resolve-Path -LiteralPath $ApkPath).Path
$WebRoot = (Resolve-Path -LiteralPath $WebRoot).Path

function Get-FileManifest {
    param([Parameter(Mandatory)][string]$Root)

    $resolved = (Resolve-Path -LiteralPath $Root).Path
    $manifest = @{}
    foreach ($file in Get-ChildItem -LiteralPath $resolved -Recurse -File) {
        $relative = $file.FullName.Substring($resolved.Length).TrimStart(
            [System.IO.Path]::DirectorySeparatorChar,
            [System.IO.Path]::AltDirectorySeparatorChar
        ).Replace('\', '/')
        $manifest[$relative] = [pscustomobject]@{
            Length = [int64]$file.Length
            Sha256 = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
        }
    }
    return $manifest
}

function Get-ZipManifest {
    param(
        [Parameter(Mandatory)][string]$ArchivePath,
        [Parameter(Mandatory)][string]$Prefix
    )

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [System.IO.Compression.ZipFile]::OpenRead($ArchivePath)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $manifest = @{}
    try {
        foreach ($entry in $archive.Entries) {
            if (-not $entry.FullName.StartsWith($Prefix, [System.StringComparison]::Ordinal)) {
                continue
            }
            if ($entry.FullName.EndsWith('/')) {
                continue
            }
            $relative = $entry.FullName.Substring($Prefix.Length)
            $stream = $entry.Open()
            try {
                $hashBytes = $sha.ComputeHash($stream)
            }
            finally {
                $stream.Dispose()
            }
            $manifest[$relative] = [pscustomobject]@{
                Length = [int64]$entry.Length
                Sha256 = ($hashBytes | ForEach-Object { $_.ToString('X2') }) -join ''
            }
        }
    }
    finally {
        $sha.Dispose()
        $archive.Dispose()
    }
    return $manifest
}

function Assert-ManifestEqual {
    param(
        [Parameter(Mandatory)][string]$Label,
        [Parameter(Mandatory)][hashtable]$Expected,
        [Parameter(Mandatory)][hashtable]$Actual
    )

    $differences = [System.Collections.Generic.List[string]]::new()
    foreach ($path in $Expected.Keys) {
        if (-not $Actual.ContainsKey($path)) {
            $differences.Add("missing:$path")
            continue
        }
        if ($Expected[$path].Length -ne $Actual[$path].Length) {
            $differences.Add("length:$path")
            continue
        }
        if ($Expected[$path].Sha256 -ne $Actual[$path].Sha256) {
            $differences.Add("sha256:$path")
        }
    }
    foreach ($path in $Actual.Keys) {
        if (-not $Expected.ContainsKey($path)) {
            $differences.Add("extra:$path")
        }
    }

    if ($differences.Count -gt 0) {
        $sample = ($differences | Select-Object -First 12) -join ', '
        throw "$Label failed with $($differences.Count) difference(s): $sample"
    }

    $bytes = ($Actual.Values | Measure-Object -Property Length -Sum).Sum
    [pscustomobject]@{
        Check = $Label
        Files = $Actual.Count
        Bytes = [int64]$bytes
        Status = 'PASS'
    }
}

function Find-BuildTool {
    param([Parameter(Mandatory)][string]$Name)

    $roots = @($env:ANDROID_HOME, $env:ANDROID_SDK_ROOT) |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and (Test-Path -LiteralPath $_) } |
        Select-Object -Unique
    foreach ($root in $roots) {
        $buildToolsRoot = Join-Path $root 'build-tools'
        if (-not (Test-Path -LiteralPath $buildToolsRoot)) {
            continue
        }
        foreach ($version in Get-ChildItem -LiteralPath $buildToolsRoot -Directory | Sort-Object Name -Descending) {
            $candidate = Join-Path $version.FullName $Name
            if (Test-Path -LiteralPath $candidate) {
                return $candidate
            }
        }
    }
    return $null
}

$sourceBank = Get-FileManifest (Join-Path $repoRoot 'app\src\main\assets\question_bank')
$sourceMedia = Get-FileManifest (Join-Path $repoRoot 'app\src\main\assets\question_media')
$flutterBank = Get-FileManifest (Join-Path $FlutterRoot 'assets\question_bank')
$flutterMedia = Get-FileManifest (Join-Path $FlutterRoot 'assets\question_media')
$webBank = Get-FileManifest (Join-Path $WebRoot 'assets\assets\question_bank')
$webMedia = Get-FileManifest (Join-Path $WebRoot 'assets\assets\question_media')
$apkBank = Get-ZipManifest $ApkPath 'assets/flutter_assets/assets/question_bank/'
$apkMedia = Get-ZipManifest $ApkPath 'assets/flutter_assets/assets/question_media/'

$results = @(
    Assert-ManifestEqual 'source -> Flutter question bank' $sourceBank $flutterBank
    Assert-ManifestEqual 'source -> web question bank' $sourceBank $webBank
    Assert-ManifestEqual 'source -> APK question bank' $sourceBank $apkBank
    Assert-ManifestEqual 'source -> Flutter question media' $sourceMedia $flutterMedia
    Assert-ManifestEqual 'source -> web question media' $sourceMedia $webMedia
    Assert-ManifestEqual 'source -> APK question media' $sourceMedia $apkMedia
)

foreach ($requiredWebFile in @('main.dart.js', 'sqlite3.wasm', 'drift_worker.dart.js', 'manifest.json')) {
    $path = Join-Path $WebRoot $requiredWebFile
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Web release is missing $requiredWebFile"
    }
}

$aapt = Find-BuildTool 'aapt.exe'
if ($null -ne $aapt) {
    $badging = (& $aapt dump badging $ApkPath) -join "`n"
    if ($LASTEXITCODE -ne 0 -or $badging -notmatch "package: name='com\.gauss\.app'") {
        throw 'APK package metadata did not verify as com.gauss.app.'
    }
    $packageLine = ($badging -split "`n" | Select-Object -First 1)
}
else {
    $packageLine = 'aapt unavailable; package metadata not inspected by this script.'
}

$apksigner = Find-BuildTool 'apksigner.bat'
if ($null -ne $apksigner) {
    $signatureOutput = (& $apksigner verify --verbose --print-certs $ApkPath) -join "`n"
    if ($LASTEXITCODE -ne 0 -or $signatureOutput -notmatch 'Verified using v2 scheme.*true') {
        throw 'APK signature verification failed.'
    }
    if ($signatureOutput -match 'CN=Android Debug') {
        if (-not $AllowDebugSigningForLocalVerification) {
            throw 'APK is signed with the Android debug certificate and must not be treated as a release artifact.'
        }
        $signingStatus = 'DEBUG (local verification only; not publishable)'
    }
    else {
        $signingStatus = 'PASS (cryptographic signature valid and non-debug certificate detected)'
    }
}
else {
    $signingStatus = 'SKIPPED (apksigner unavailable)'
}

$results | Format-Table -AutoSize
[pscustomobject]@{
    Apk = $ApkPath
    ApkSha256 = (Get-FileHash -LiteralPath $ApkPath -Algorithm SHA256).Hash
    ApkBytes = (Get-Item -LiteralPath $ApkPath).Length
    Package = $packageLine
    Signature = $signingStatus
    WebMainBytes = (Get-Item -LiteralPath (Join-Path $WebRoot 'main.dart.js')).Length
    WebSqliteBytes = (Get-Item -LiteralPath (Join-Path $WebRoot 'sqlite3.wasm')).Length
    WebWorkerBytes = (Get-Item -LiteralPath (Join-Path $WebRoot 'drift_worker.dart.js')).Length
} | Format-List
