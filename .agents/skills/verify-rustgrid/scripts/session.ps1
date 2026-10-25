[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('Start', 'Doctor', 'Cleanup')][string]$Action,
    [Parameter(Mandatory)][string]$RunId
)
$ErrorActionPreference = 'Stop'
if ($env:OS -ne 'Windows_NT') { throw 'This helper supports Windows only.' }
if ($RunId -notmatch '^[a-zA-Z0-9][a-zA-Z0-9_-]{0,63}$') { throw 'Use a short alphanumeric RunId.' }
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../..'))
$runRoot = Join-Path $repo "target/verification/$RunId"
$manifest = Join-Path $runRoot 'session.json'
$config = Join-Path ([Environment]::GetFolderPath('ApplicationData')) 'rustgrid/config'
$original = "$config.verify-original"
$marker = Join-Path $config '.verification-owner'
$binary = Join-Path $repo 'target/debug/RustGrid.exe'
$compilerBin = Join-Path $repo 'target/verification/toolchains/mingw64/bin'
if (Test-Path -LiteralPath (Join-Path $compilerBin 'gcc.exe')) {
    $env:PATH = "$compilerBin;$env:PATH"
}

function Save-State($state) {
    $state | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $manifest -Encoding utf8
}
function Read-State {
    $state = Get-Content -LiteralPath $manifest -Raw | ConvertFrom-Json
    if ($state.runRoot -ne $runRoot -or $state.config -ne $config -or $state.original -ne $original -or $state.binary -ne $binary) {
        throw 'Manifest paths do not match this checkout and user.'
    }
    return $state
}
function Owned-Process($state) {
    if (-not $state.processId) { return $null }
    $process = Get-Process -Id $state.processId -ErrorAction SilentlyContinue
    if ($process) {
        if ($process.Path -ne $binary -or $process.StartTime.ToUniversalTime().Ticks.ToString() -ne $state.startedTicks) {
            throw 'Process identity changed; refusing to control a reused PID.'
        }
    }
    return $process
}
function Restore-Session($state) {
    if ($state.phase -eq 'cleaned') { return }
    $process = Owned-Process $state
    if ($process) {
        # Only the exact PID + start time + executable recorded by Start may be stopped.
        Stop-Process -Id $process.Id
        $process.WaitForExit()
    }
    if (Get-Process RustGrid -ErrorAction SilentlyContinue) { throw 'Another RustGrid is running; restore postponed.' }
    if (Test-Path -LiteralPath $config) {
        $isOwned = (Test-Path -LiteralPath $marker) -and ((Get-Content -LiteralPath $marker -Raw).Trim() -eq $runRoot)
        if (-not $isOwned) {
            if ($state.phase -eq 'prepared' -and -not (Test-Path -LiteralPath $original)) {
                $state.phase = 'cleaned'
                Save-State $state
                return
            }
            throw 'Config ownership marker is missing; preserve both directories for manual recovery.'
        }
        $archive = Join-Path $runRoot 'scratch-config'
        if (Test-Path -LiteralPath $archive) { throw 'Scratch archive already exists; refusing to overwrite it.' }
        # Exact directories were resolved above. No recursive deletion is used.
        Move-Item -LiteralPath $config -Destination $archive
    }
    if ($state.hadOriginal) {
        if (-not (Test-Path -LiteralPath $original)) { throw 'Original config backup is missing.' }
        Move-Item -LiteralPath $original -Destination $config
    }
    $state.phase = 'cleaned'
    Save-State $state
    [pscustomobject]@{ phase = 'cleaned'; evidence = $runRoot; originalRestored = [bool]$state.hadOriginal } | ConvertTo-Json
}

switch ($Action) {
    'Start' {
        if (Get-Process RustGrid -ErrorAction SilentlyContinue) { throw 'verifier-blocked: close the existing RustGrid instance before verification.' }
        if (-not (Test-Path -LiteralPath $binary)) { throw 'Build the debug binary first; target/debug/RustGrid.exe is missing.' }
        if ((Test-Path -LiteralPath $original) -or (Test-Path -LiteralPath $marker)) { throw 'Unfinished verification session exists; recover it before starting another.' }
        if (Test-Path -LiteralPath $runRoot) { throw 'RunId already exists; use a new ID to preserve evidence.' }
        New-Item -ItemType Directory -Path $runRoot -Force | Out-Null
        $state = [pscustomobject]@{
            runRoot = $runRoot; config = $config; original = $original; binary = $binary
            hadOriginal = (Test-Path -LiteralPath $config); phase = 'prepared'
            processId = 0; startedUtc = ''; startedTicks = ''; binarySha256 = (Get-FileHash -LiteralPath $binary).Hash
            database = (Join-Path $runRoot 'fixture.sqlite')
        }
        Save-State $state
        try {
            if ($state.hadOriginal) { Move-Item -LiteralPath $config -Destination $original }
            New-Item -ItemType Directory -Path $config -Force | Out-Null
            Set-Content -LiteralPath $marker -Value $runRoot -Encoding utf8
            $state.phase = 'isolated'
            Save-State $state
            # SQLite opens an existing file; schema/data are created later through the real UI.
            New-Item -ItemType File -Path $state.database | Out-Null
            # This is the interactive verification target: GPUI inherits the startup show state.
            $process = Start-Process -FilePath $binary -WorkingDirectory $repo -WindowStyle Normal -PassThru -RedirectStandardOutput (Join-Path $runRoot 'stdout.log') -RedirectStandardError (Join-Path $runRoot 'stderr.log')
            $state.processId = $process.Id
            $state.startedUtc = $process.StartTime.ToUniversalTime().ToString('o')
            $state.startedTicks = $process.StartTime.ToUniversalTime().Ticks.ToString()
            $state.phase = 'running'
            Save-State $state
            $state | ConvertTo-Json
        } catch {
            $failure = $_
            Restore-Session $state
            throw $failure
        }
    }
    'Doctor' {
        $state = Read-State
        if ($state.phase -ne 'running') { throw "Session is $($state.phase), not running." }
        $process = Owned-Process $state
        if (-not $process) { throw 'Recorded process has exited. Inspect logs, then Cleanup.' }
        if ((Get-Content -LiteralPath $marker -Raw).Trim() -ne $runRoot) { throw 'Wrong config owner.' }
        if ((Get-FileHash -LiteralPath $binary).Hash -ne $state.binarySha256) { throw 'Binary changed during verification.' }
        $process.Refresh()
        if ($process.MainWindowHandle -eq 0) { throw 'No main window yet. Inspect logs and desktop window inventory.' }
        [pscustomobject]@{ healthy = $true; processId = $process.Id; title = $process.MainWindowTitle; binarySha256 = $state.binarySha256; database = $state.database; config = $config } | ConvertTo-Json
    }
    'Cleanup' { Restore-Session (Read-State) }
}
