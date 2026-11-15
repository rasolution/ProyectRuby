param([ValidateSet('build','test','run')][string]$Action = 'build', [string]$Distribution = 'Ubuntu')
$ErrorActionPreference = 'Stop'
$repoLinuxOutput = & wsl.exe -d $Distribution --exec wslpath -a ($PSScriptRoot.Replace('\', '/'))
if ($LASTEXITCODE -ne 0 -or -not $repoLinuxOutput) { throw 'No se pudo localizar el repositorio en WSL' }
$repoLinux = $repoLinuxOutput.Trim()
& wsl.exe -d $Distribution --exec sh ($repoLinux + '/scripts/run-local.sh') $Action
exit $LASTEXITCODE
