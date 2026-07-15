param()

$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..")

function Invoke-RgNoMatch {
    param(
        [string] $Pattern,
        [string[]] $Paths,
        [string] $Label
    )

    $output = & rg -n $Pattern @Paths 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Error "$Label failed:`n$output"
    }
    if ($LASTEXITCODE -ne 1) {
        Write-Error "$Label failed because ripgrep exited with code $LASTEXITCODE."
    }
}

function Assert-True {
    param(
        [bool] $Condition,
        [string] $Message
    )

    if (-not $Condition) {
        Write-Error $Message
    }
}

Push-Location $Root
try {
    $screenFile = "app/src/main/java/com/gauss/app/ui/screens/AdventureScreens.kt"
    $gamifyFiles = @(
        "app/src/main/java/com/gauss/app/gamify",
        "app/src/test/java/com/gauss/app/gamify",
        $screenFile
    )
    $forbiddenScaffold = 'ReferencePreviewScreen|PreviewHitBox|ReferenceArt|preview_(map|arena|reward|profile)_full|adventure_map_art|profile_tabs_panel|reward_vault_hero'

    Invoke-RgNoMatch -Pattern $forbiddenScaffold -Paths @($screenFile) -Label "Native AdventureScreens scaffold scan"
    Invoke-RgNoMatch -Pattern '\p{Arabic}' -Paths $gamifyFiles -Label "Adventure app chrome Arabic-script scan"
    Invoke-RgNoMatch -Pattern 'still use `ReferencePreviewScreen` scaffolds|visual scaffold are|visual scaffold هستند|full-screen reference assets and hitbox' -Paths @("docs") -Label "Adventure documentation stale-state scan"

    $manifest = Get-Content "docs/adventure-reference-manifest.json" -Raw | ConvertFrom-Json
    Assert-True ($manifest.reference.sha256 -eq "AB6A8E8DF435554FEE27F4A606D29583279666136A00425B44CF89424A872D2C") "Reference manifest hash does not match the accepted preview."
    Assert-True ($manifest.phoneFrames.Count -eq 4) "Reference manifest must keep exactly four target phone frames."

    & python "scripts/extract_adventure_reference_oracle.py" --check
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Adventure reference oracle check failed."
    }
    & python "scripts/compare_adventure_visual_oracle.py" --self-test
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Adventure visual comparison self-test failed."
    }

    $allowedDrawableNames = @("adventure_map_background.png", "gauss_mentor.webp", "ic_launcher_foreground.png")
    $drawableNames = @(Get-ChildItem "app/src/main/res/drawable-nodpi" -File | ForEach-Object { $_.Name })
    $unexpected = @($drawableNames | Where-Object { $_ -notin $allowedDrawableNames })
    Assert-True ($unexpected.Count -eq 0) "Unexpected drawable-nodpi scaffold assets remain: $($unexpected -join ', ')"

    Write-Host "Adventure native contracts passed."
}
finally {
    Pop-Location
}
