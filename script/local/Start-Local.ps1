<#
.SYNOPSIS
启动本项目的后端和前端，使用 .local 中的外置连接配置。
#>
[CmdletBinding()]
param(
    [ValidateSet('All', 'Backend', 'Frontend')]
    [string]$Service = 'All',
    [ValidateRange(1, 65535)]
    [int]$FrontendPort = 80
)

$ErrorActionPreference = 'Stop'
$taskProjectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$taskLocalRoot = Join-Path $taskProjectRoot '.local'
$taskLogRoot = Join-Path $taskLocalRoot 'logs'
$taskFrontendRoot = Join-Path $taskProjectRoot 'yudao-ui\yudao-ui-admin-vue3-master'
New-Item -ItemType Directory -Force -Path $taskLogRoot | Out-Null
. (Join-Path $PSScriptRoot 'Common-Local.ps1')

function Get-RecordedLocalProcess {
    param([string]$Name)
    $taskRecordPath = Join-Path $taskLocalRoot ($Name + '-process.json')
    if (-not (Test-Path -LiteralPath $taskRecordPath)) { return $null }
    $taskRecord = Get-Content -LiteralPath $taskRecordPath -Raw | ConvertFrom-Json
    $taskProcess = Get-Process -Id $taskRecord.ProcessId -ErrorAction SilentlyContinue
    if ($taskRecord.ProjectRoot -eq $taskProjectRoot -and (Test-LocalProcessIdentity -Process $taskProcess -Record $taskRecord)) {
        return $taskProcess
    }
    return $null
}

function Save-LocalProcess {
    param([string]$Name, [Diagnostics.Process]$Process, [int]$Port)
    [ordered]@{
        ProcessId = $Process.Id
        StartTimeUtc = $Process.StartTime.ToUniversalTime().ToString('o')
        StartTimeUtcTicks = [string]$Process.StartTime.ToUniversalTime().Ticks
        Port = $Port
        ProjectRoot = $taskProjectRoot
    } | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $taskLocalRoot ($Name + '-process.json')) -Encoding utf8
}

function Assert-LocalPortAvailable {
    param([string]$Name, [int]$Port)
    if (Get-RecordedLocalProcess -Name $Name) { return }
    $taskListener = Get-NetTCPConnection -State Listen -LocalPort $Port -ErrorAction SilentlyContinue
    if ($taskListener) { throw "端口 $Port 已被其它进程占用，请先确认占用情况。" }
}

function Wait-LocalHttp {
    param([string]$Url, [Diagnostics.Process]$Process, [int]$TimeoutSeconds = 120, [switch]$RequireApiSuccess)
    $taskDeadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
    while ([DateTime]::UtcNow -lt $taskDeadline) {
        $Process.Refresh()
        if ($Process.HasExited) { throw "服务进程已退出，请查看 $taskLogRoot 中的日志。" }
        try {
            $taskResponse = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 3
            if ($taskResponse.StatusCode -eq 200) {
                if (-not $RequireApiSuccess -or ($taskResponse.Content | ConvertFrom-Json).code -eq 0) { return }
            }
        } catch {
            # 服务启动期间继续等待。
        }
        Start-Sleep -Seconds 2
    }
    throw "等待服务就绪超时：$Url，请查看 $taskLogRoot 中的日志。"
}

if ($Service -in @('All', 'Backend')) {
    $taskJar = Join-Path $taskProjectRoot 'yudao-server\target\yudao-server.jar'
    if (-not (Test-Path -LiteralPath $taskJar)) { throw '尚未构建后端，请先执行 mvn -pl yudao-server -am package -DskipTests。' }
    if (-not (Test-Path -LiteralPath (Join-Path $taskLocalRoot 'application-my.yaml'))) { throw '缺少 .local/application-my.yaml 本机连接配置。' }
    Assert-LocalPortAvailable -Name 'backend' -Port 48080
}
if ($Service -in @('All', 'Frontend')) {
    $taskFrontendRoot = Get-LocalFrontendPath -ProjectRoot $taskProjectRoot
    $taskVite = Join-Path $taskFrontendRoot 'node_modules\vite\bin\vite.js'
    if (-not (Test-Path -LiteralPath $taskVite)) { throw '尚未安装前端依赖，请在前端目录执行 pnpm install --frozen-lockfile。' }
    Assert-LocalPortAvailable -Name 'frontend' -Port $FrontendPort
}

if ($Service -in @('All', 'Backend')) {
    $taskBackendProcess = Get-RecordedLocalProcess -Name 'backend'
    if (-not $taskBackendProcess) {
        $taskJava = (Get-Command java -CommandType Application | Select-Object -First 1).Source
        $taskArguments = @('-Xms256m', '-Xmx1024m', '-Dfile.encoding=UTF-8', '-jar', ('"' + $taskJar + '"'), '--spring.profiles.active=local,my', '--spring.config.additional-location=optional:file:./.local/')
        $taskBackendProcess = Start-Process -FilePath $taskJava -ArgumentList $taskArguments -WorkingDirectory $taskProjectRoot -WindowStyle Hidden -RedirectStandardOutput (Join-Path $taskLogRoot 'backend.stdout.log') -RedirectStandardError (Join-Path $taskLogRoot 'backend.stderr.log') -PassThru
        Save-LocalProcess -Name 'backend' -Process $taskBackendProcess -Port 48080
    }
    $taskReadyUrl = 'http://127.0.0.1:48080/admin-api/system/tenant/get-id-by-name?name=' + [Uri]::EscapeDataString('芋道源码')
    Wait-LocalHttp -Url $taskReadyUrl -Process $taskBackendProcess -RequireApiSuccess
    Write-Output '后端已就绪：http://127.0.0.1:48080'
}

if ($Service -in @('All', 'Frontend')) {
    $taskFrontendProcess = Get-RecordedLocalProcess -Name 'frontend'
    if (-not $taskFrontendProcess) {
        $taskNode = (Get-Command node -CommandType Application | Select-Object -First 1).Source
        $taskArguments = @(('"' + $taskVite + '"'), '--mode', 'env.local', '--host', '127.0.0.1', '--port', $FrontendPort, '--strictPort')
        $taskPreviousOpen = $env:VITE_OPEN
        try {
            $env:VITE_OPEN = 'false'
            $taskFrontendProcess = Start-Process -FilePath $taskNode -ArgumentList $taskArguments -WorkingDirectory $taskFrontendRoot -WindowStyle Hidden -RedirectStandardOutput (Join-Path $taskLogRoot 'frontend.stdout.log') -RedirectStandardError (Join-Path $taskLogRoot 'frontend.stderr.log') -PassThru
        } finally {
            $env:VITE_OPEN = $taskPreviousOpen
        }
        Save-LocalProcess -Name 'frontend' -Process $taskFrontendProcess -Port $FrontendPort
    }
    $taskFrontendRecord = Get-Content -LiteralPath (Join-Path $taskLocalRoot 'frontend-process.json') -Raw | ConvertFrom-Json
    Wait-LocalHttp -Url ('http://127.0.0.1:' + $taskFrontendRecord.Port) -Process $taskFrontendProcess
    Write-Output ('前端已就绪：http://127.0.0.1:' + $taskFrontendRecord.Port)
}
