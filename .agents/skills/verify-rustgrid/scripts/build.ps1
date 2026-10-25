[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../..'))
$compilerBin = Join-Path $repo 'target/verification/toolchains/mingw64/bin'
if (Test-Path -LiteralPath (Join-Path $compilerBin 'gcc.exe')) {
    $env:PATH = "$compilerBin;$env:PATH"
}
$gccTarget = & gcc -dumpmachine
if ($LASTEXITCODE -ne 0 -or $gccTarget -notmatch '^x86_64.*mingw32') {
    throw "Need 64-bit MinGW-w64 GCC; found '$gccTarget'. See references/windows-build.md."
}
$env:RUSTUP_TOOLCHAIN = 'stable-x86_64-pc-windows-gnu'
$env:CARGO_TARGET_X86_64_PC_WINDOWS_GNU_LINKER = 'gcc'
$env:CC = 'gcc'
$env:CXX = 'g++'
$env:CARGO_BUILD_JOBS = '4'
$logRoot = Join-Path $repo 'target/verification'
New-Item -ItemType Directory -Path $logRoot -Force | Out-Null
Push-Location $repo
try {
    & cargo fmt --all
    if ($LASTEXITCODE -ne 0) { throw 'cargo fmt failed' }
    & cargo build 2>&1 | Tee-Object -FilePath (Join-Path $logRoot 'build.log')
    if ($LASTEXITCODE -ne 0) { throw "cargo build failed ($LASTEXITCODE). See target/verification/build.log." }
} finally {
    Pop-Location
}
