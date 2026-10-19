# 比较实际进程与启动记录；JSON 读取可能把 ISO 字符串转换成 DateTime。
function Test-LocalProcessIdentity {
    param([Diagnostics.Process]$Process, [psobject]$Record)
    if (-not $Process -or -not $Record) { return $false }
    $taskRecordedTicks = if ($Record.StartTimeUtcTicks) {
        [long]$Record.StartTimeUtcTicks
    } else {
        ([DateTime]$Record.StartTimeUtc).ToUniversalTime().Ticks
    }
    return $Process.StartTime.ToUniversalTime().Ticks -eq $taskRecordedTicks
}

# 为 Vite 提供不含 #、? 的稳定工作路径，源码仍保留在原目录。
function Get-LocalFrontendPath {
    param([Parameter(Mandatory)][string]$ProjectRoot)

    $taskFrontendRelative = 'yudao-ui\yudao-ui-admin-vue3-master'
    if ($ProjectRoot -notmatch '[#?]') { return Join-Path $ProjectRoot $taskFrontendRelative }

    $taskLocalRoot = Join-Path $ProjectRoot '.local'
    New-Item -ItemType Directory -Force -Path $taskLocalRoot | Out-Null
    $taskRecordPath = Join-Path $taskLocalRoot 'frontend-path.json'
    $taskPreferredDrive = $null
    if (Test-Path -LiteralPath $taskRecordPath) {
        $taskRecord = Get-Content -LiteralPath $taskRecordPath -Raw | ConvertFrom-Json
        if ($taskRecord.Target -eq $ProjectRoot -and $taskRecord.Drive -match '^[A-Z]:$') {
            $taskPreferredDrive = $taskRecord.Drive
        }
    }

    $taskMappings = @{}
    foreach ($taskLine in (& subst)) {
        if ($taskLine -match '^([A-Za-z]):\\: => (.+)$') {
            $taskMappings[$Matches[1].ToUpperInvariant() + ':'] = $Matches[2].TrimEnd('\')
        }
    }
    $taskDrive = $null
    foreach ($taskCandidate in $taskMappings.Keys) {
        if ($taskMappings[$taskCandidate] -eq $ProjectRoot.TrimEnd('\')) { $taskDrive = $taskCandidate; break }
    }
    if (-not $taskDrive) {
        $taskCandidates = if ($taskPreferredDrive) { @($taskPreferredDrive) } else { @('Y:', 'X:', 'W:', 'V:', 'U:') }
        $taskUsedDrives = [IO.Directory]::GetLogicalDrives()
        foreach ($taskCandidate in $taskCandidates) {
            if ($taskUsedDrives -notcontains ($taskCandidate + '\')) { $taskDrive = $taskCandidate; break }
        }
        if (-not $taskDrive) { throw '前端专用盘符已被其它位置占用，未覆盖现有映射。请释放原盘符后重试。' }
        & subst $taskDrive $ProjectRoot
        if ($LASTEXITCODE -ne 0) { throw '创建前端路径映射失败。' }
    }
    $taskFrontendPath = Join-Path ($taskDrive + '\') $taskFrontendRelative
    if (-not (Test-Path -LiteralPath (Join-Path $taskFrontendPath 'package.json'))) { throw '前端路径映射校验失败。' }
    [ordered]@{ Drive = $taskDrive; Target = $ProjectRoot; Frontend = $taskFrontendPath } | ConvertTo-Json | Set-Content -LiteralPath $taskRecordPath -Encoding utf8
    return $taskFrontendPath
}
