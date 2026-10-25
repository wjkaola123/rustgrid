# Windows build environment

`scripts/build.ps1` prefers a project-local compiler at `target/verification/toolchains/mingw64/bin`, then falls back to PATH. It requires `gcc -dumpmachine` to report x86_64 MinGW, sets the GNU Rust toolchain and four build jobs for the current process, runs formatting and the full debug build, and writes `target/verification/build.log`. It changes no system PATH or registry setting. `session.ps1` adds the same compiler directory to the launched application's environment for runtime DLL lookup.

The verification target is launched with `WindowStyle Normal`. `WindowStyle Hidden` also hides GPUI's main window on this host, leaving a live process without a targetable app window. This is the interactive application being verified, so it must be shown. Process identity is matched using startup ticks stored as a numeric string: PowerShell converts ISO timestamps read from JSON into `DateTime` objects, making direct timestamp-string comparisons unreliable.

If only the old `C:\MinGW\bin\gcc.exe` reporting `mingw32` is installed, provision a portable 64-bit compiler into the ignored directory. The initial verified source is the upstream [mingw-builds-binaries release](https://github.com/niXman/mingw-builds-binaries/releases/tag/16.2.0-rt_v14-rev1):

```powershell
$toolRoot = Join-Path (Get-Location) 'target/verification/toolchains'
New-Item -ItemType Directory -Path $toolRoot -Force | Out-Null
$archive = Join-Path $toolRoot 'x86_64-16.2.0-release-posix-seh-msvcrt-rt_v14-rev1.7z'
$url = 'https://github.com/niXman/mingw-builds-binaries/releases/download/16.2.0-rt_v14-rev1/x86_64-16.2.0-release-posix-seh-msvcrt-rt_v14-rev1.7z'
curl.exe -L --fail --retry 2 --output $archive $url
if ($LASTEXITCODE -ne 0) { throw 'Compiler download failed' }
$expected = 'a3cfb25037981ea1cd2f4e5452fa45c700b20fffc311e5d78de90dedd142b73a'
if ((Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant() -ne $expected) {
    throw 'Compiler archive checksum mismatch'
}
tar -xf $archive -C $toolRoot
if ($LASTEXITCODE -ne 0) { throw 'Compiler extraction failed' }
& (Join-Path $toolRoot 'mingw64/bin/gcc.exe') -dumpmachine
```

This is a 108 MB download, extracted with Windows' bundled bsdtar. Keep it outside the tracked source tree. Install the Rust toolchain with `rustup toolchain install stable-x86_64-pc-windows-gnu --profile minimal --component rustfmt` when absent. A machine-local mirror may be needed for Rust downloads; choose it through process environment rather than editing repository dependencies.
