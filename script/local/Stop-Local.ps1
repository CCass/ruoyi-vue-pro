<#
.SYNOPSIS
停止由 Start-Local.ps1 启动的本项目前后端进程。
#>
[CmdletBinding()]
param(
    [ValidateSet('All', 'Backend', 'Frontend')]
    [string]$Service = 'All'
)

$ErrorActionPreference = 'Stop'
$taskProjectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$taskLocalRoot = Join-Path $taskProjectRoot '.local'
. (Join-Path $PSScriptRoot 'Common-Local.ps1')
$taskNames = if ($Service -eq 'All') { @('frontend', 'backend') } else { @($Service.ToLowerInvariant()) }

foreach ($taskName in $taskNames) {
    $taskRecordPath = Join-Path $taskLocalRoot ($taskName + '-process.json')
    if (-not (Test-Path -LiteralPath $taskRecordPath)) {
        Write-Output "$taskName 没有本项目的启动记录。"
        continue
    }
    $taskRecord = Get-Content -LiteralPath $taskRecordPath -Raw | ConvertFrom-Json
    if ($taskRecord.ProjectRoot -ne $taskProjectRoot) { throw '进程记录不属于当前项目，停止操作。' }
    $taskProcess = Get-Process -Id $taskRecord.ProcessId -ErrorAction SilentlyContinue
    if (Test-LocalProcessIdentity -Process $taskProcess -Record $taskRecord) {
        Stop-Process -Id $taskProcess.Id
        if (-not $taskProcess.WaitForExit(10000)) { throw "$taskName 进程尚未退出，保留启动记录。" }
        Write-Output "$taskName 已停止。"
    } else {
        Write-Output "$taskName 原进程已退出，未操作其它进程。"
    }
    Remove-Item -LiteralPath $taskRecordPath
}
