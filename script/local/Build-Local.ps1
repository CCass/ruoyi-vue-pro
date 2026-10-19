<#
.SYNOPSIS
构建本项目前后端，自动处理原目录中 # 字符对 Vite 的影响。
#>
[CmdletBinding()]
param(
    [ValidateSet('All', 'Backend', 'Frontend')]
    [string]$Service = 'All',
    [switch]$Install,
    [switch]$CheckTypes
)

$ErrorActionPreference = 'Stop'
$taskProjectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
. (Join-Path $PSScriptRoot 'Common-Local.ps1')

if ($Service -in @('All', 'Backend')) {
    Push-Location -LiteralPath $taskProjectRoot
    $taskPreviousMavenOpts = $env:MAVEN_OPTS
    try {
        $env:MAVEN_OPTS = (($env:MAVEN_OPTS + ' -Dfile.encoding=UTF-8').Trim())
        & mvn -B -ntp -pl yudao-server -am package '-DskipTests'
        if ($LASTEXITCODE -ne 0) { throw '后端构建失败。' }
    } finally {
        $env:MAVEN_OPTS = $taskPreviousMavenOpts
        Pop-Location
    }
}

if ($Service -in @('All', 'Frontend')) {
    $taskFrontendPath = Get-LocalFrontendPath -ProjectRoot $taskProjectRoot
    Push-Location -LiteralPath $taskFrontendPath
    try {
        if ($Install) {
            # 重建链接，确保依赖也使用映射路径，避免旧的绝对路径包含 #。
            & pnpm install --force --frozen-lockfile
            if ($LASTEXITCODE -ne 0) { throw '前端依赖安装失败。' }
        }
        & pnpm build:local
        if ($LASTEXITCODE -ne 0) { throw '前端构建失败。' }
        if ($CheckTypes) {
            & pnpm ts:check
            if ($LASTEXITCODE -ne 0) { throw '前端类型检查失败；首次检查前需启动开发服务生成全局声明。' }
        }
    } finally {
        Pop-Location
    }
}
