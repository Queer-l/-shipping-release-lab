[CmdletBinding()]
param([switch]$Offline)
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$code = 1
$status = 'ENVIRONMENT_PROBLEM'
$message = ''
$logLines = New-Object 'System.Collections.Generic.List[string]'
$tempLog = Join-Path ([IO.Path]::GetTempPath()) ('L08-preflight-' + [guid]::NewGuid().ToString('N') + '.log')
$writer = New-Object IO.StreamWriter($tempLog, $false, (New-Object Text.UTF8Encoding($true)))
function Say([string]$Text) { Write-Host $Text; $logLines.Add($Text); $writer.WriteLine($Text); $writer.Flush() }
function NativeText([string]$Command, [string[]]$Arguments) {
    $ErrorActionPreference = 'Continue'
    $lines = & $Command @Arguments 2>&1
    $resultCode = $LASTEXITCODE
    return [pscustomobject]@{Text=(($lines | ForEach-Object { [string]$_ }) -join "`n"); Code=$resultCode}
}
Push-Location -LiteralPath $root
try {
    Say 'L08 preflight / 第8次课一键环境预检（无需管理员权限）'
    Say '首次运行会下载Maven依赖，请保持联网；请勿提前修改起始工程。'
    $commands = @{}
    foreach ($name in @('java','javac','mvn','git')) {
        $command = Get-Command $name -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($null -eq $command) { throw "找不到$name。请安装/配置对应工具的PATH，重新打开窗口后重试。" }
        $commands[$name] = $command.Source
    }
    $java = NativeText $commands.java @('-version')
    $javac = NativeText $commands.javac @('-version')
    $maven = NativeText $commands.mvn @('-version')
    $git = NativeText $commands.git @('--version')
    foreach ($item in @($java,$javac,$maven,$git)) { Say $item.Text.Trim(); if ($item.Code -ne 0) { throw '工具版本命令执行失败，检查安装与JAVA_HOME。' } }
    if ($java.Text -notmatch 'version "21[.\"]' -or $javac.Text -notmatch 'javac 21(?:\.|\s|$)') { throw '请使用JDK 21：java和javac都必须为21。' }
    if ($maven.Text -notmatch 'Java version: 21(?:\.|,|\s)') { throw 'Maven实际使用的Java不是21；请检查JAVA_HOME与mvn -version。' }
    if ($maven.Text -notmatch 'Apache Maven (\d+\.\d+(?:\.\d+)?)') { throw '无法识别Maven版本。' }
    if ([version]$Matches[1] -lt [version]'3.9') { throw '请使用Maven 3.9或更高版本。' }
    if ($git.Text -notmatch 'git version (\d+\.\d+(?:\.\d+)?)' -or [version]$Matches[1] -lt [version]'2.23') { throw '请使用Git 2.23或更高版本，课堂需要git switch。' }
    $status = 'PROJECT_STATE_PROBLEM'; $code = 2
    $branch = NativeText $commands.git @('branch','--show-current')
    $state = NativeText $commands.git @('status','--porcelain')
    if (-not (Test-Path -LiteralPath '.git') -or $branch.Code -ne 0 -or $state.Code -ne 0 -or $branch.Text.Trim() -ne 'feature/vip-shipping' -or $state.Text.Trim()) { throw '请使用未修改、保留.git的起始包，默认feature/vip-shipping分支；无需git init。本脚本不适用于已完成的答案工程。' }
    $manifest = Get-Content -LiteralPath 'tools/preflight-baseline.json' -Raw | ConvertFrom-Json
    foreach ($property in $manifest.PSObject.Properties) {
        $sha = [Security.Cryptography.SHA256]::Create()
        try { $actualHash = [BitConverter]::ToString($sha.ComputeHash([IO.File]::ReadAllBytes((Join-Path $root $property.Name)))).Replace('-','') } finally { $sha.Dispose() }
        if ($actualHash -ne $property.Value) { throw "起始文件已变更：$($property.Name)。请在新目录重新解压起始包预检，勿覆盖课堂成果。" }
    }
    $status = 'ENVIRONMENT_PROBLEM'; $code = 1
    . (Join-Path $root 'tools/Test-PreflightResult.ps1')
    $started = [datetime]::UtcNow
    Say '正在运行完整默认门禁。看到BUILD FAILURE时，请等待本脚本的最终结论。'
    $arguments = @('-B','-Dstyle.color=never','clean','verify')
    if ($Offline) { $arguments = @('-o') + $arguments }
    $ErrorActionPreference = 'Continue'
    & $commands.mvn @arguments 2>&1 | ForEach-Object { Say ([string]$_) }
    $mavenExit = $LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    $writer.Flush()
    $result = Test-PreflightResult -ProjectRoot $root -LogText ($logLines -join "`n") -MavenExit $mavenExit -StartedUtc $started
    if (-not $result.Ready) { throw $result.Message }
    $code = 0; $status = 'READY_EXPECTED_SPOTBUGS'; $message = $result.Message
} catch { $message = $_.Exception.Message }
finally {
    Say ''
    Say "[$status] $message"
    if ($code -eq 0) {
        Say '课前准备完成。保留当前工程上课；不用提前修代码，不用提交预检日志。'
    } else {
        Say '尚未通过。按上述提示处理后重跑；不要禁用检查或修改门槛。'
        Say '下载/网络问题：联网重试；JDK问题：核对JAVA_HOME；其他失败请将日志交教师定位。'
    }
    $writer.Dispose()
    try {
        $outDir = Join-Path $root 'target/preflight'
        New-Item -ItemType Directory -Force -Path $outDir | Out-Null
        Copy-Item -LiteralPath $tempLog -Destination (Join-Path $outDir 'preflight.log') -Force
        [pscustomobject]@{status=$status; exitCode=$code; message=$message; checkedAt=[datetime]::UtcNow.ToString('o')} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $outDir 'result.json') -Encoding UTF8
        Write-Host "诊断日志：$outDir\preflight.log（无需提交）"
        Remove-Item -LiteralPath $tempLog -Force
    } catch { Write-Host "日志保留在：$tempLog" }
    Pop-Location
}
exit $code
