function Test-PreflightResult {
    param([string]$ProjectRoot, [string]$LogText, [int]$MavenExit, [datetime]$StartedUtc)
    $reason = '构建未完成预期验证。请查看日志末尾的失败阶段。'
    try {
        if ($MavenExit -eq 0) { throw '起始候选本应被静态门禁拒绝，却返回成功；请重新解压原始起始工程。' }
        $failedGoals = [regex]::Matches($LogText, '(?m)^.*\[ERROR\] Failed to execute goal (.+)$')
        if ($failedGoals.Count -ne 1 -or $failedGoals[0].Value -notmatch 'spotbugs-maven-plugin:[^ :]+:check.*calculator-static-gate.*1 bugs and 0 errors') {
            throw '失败原因不是唯一预期的SpotBugs check告警；可能是下载、编译、测试、覆盖率或分析器故障。'
        }
        if ($LogText -notmatch 'All coverage checks have been met' -or $LogText -notmatch 'ES_COMPARING_STRINGS_WITH_EQ') {
            throw '没有同时确认覆盖率门禁通过和预期字符串告警。'
        }
        $reports = @(Get-ChildItem -LiteralPath (Join-Path $ProjectRoot 'target/surefire-reports') -Filter 'TEST-*.xml' -ErrorAction Stop)
        if ($reports.Count -eq 0) { throw '没有新的JUnit执行结果。' }
        $counts = @{tests=0; failures=0; errors=0; skipped=0}
        foreach ($file in $reports) {
            if ($file.LastWriteTimeUtc -lt $StartedUtc) { throw '检测到旧测试报告，不能用作本次预检证据。' }
            [xml]$xml = Get-Content -LiteralPath $file.FullName -Raw
            foreach ($key in @('tests','failures','errors','skipped')) { $counts[$key] += [int]$xml.testsuite.GetAttribute($key) }
        }
        if ($counts.tests -ne 3 -or $counts.failures -ne 0 -or $counts.errors -ne 0 -or $counts.skipped -ne 0) { throw '起始工程应恰好3次测试执行，且无失败、错误或跳过。' }
        foreach ($relative in @('target/checkstyle-result.xml','target/jacoco.exec','target/site/jacoco/jacoco.xml','target/spotbugsXml.xml')) {
            $file = Get-Item -LiteralPath (Join-Path $ProjectRoot $relative) -ErrorAction Stop
            if ($file.Length -eq 0 -or $file.LastWriteTimeUtc -lt $StartedUtc) { throw "报告缺失、为空或过期：$relative" }
        }
        $style = New-Object System.Xml.XmlDocument
        $style.XmlResolver = $null
        $style.Load((Join-Path $ProjectRoot 'target/checkstyle-result.xml'))
        if ($style.SelectNodes('/checkstyle/file/error').Count -ne 0 -or $LogText -notmatch '--- checkstyle:.*:check \(java-style-gate\)') { throw '未确认默认Checkstyle门禁执行且零违规。' }
        # Read XML without resolving external DTDs or downloading resources.
        $coverage = New-Object System.Xml.XmlDocument
        $coverage.XmlResolver = $null
        $coverage.Load((Join-Path $ProjectRoot 'target/site/jacoco/jacoco.xml'))
        $calculator = $coverage.SelectSingleNode("//class[@name='edu/course/shipping/ShippingCalculator']")
        foreach ($pair in @(@('LINE',0.90),@('BRANCH',0.80))) {
            $counter = $calculator.SelectSingleNode("counter[@type='$($pair[0])']")
            $total = [double]$counter.covered + [double]$counter.missed
            if ($total -le 0 -or ([double]$counter.covered / $total) -lt $pair[1]) { throw "计算器$($pair[0])覆盖率未达到预置门槛。" }
        }
        $bugs = New-Object System.Xml.XmlDocument
        $bugs.XmlResolver = $null
        $bugs.Load((Join-Path $ProjectRoot 'target/spotbugsXml.xml'))
        $instances = @($bugs.SelectNodes('/BugCollection/BugInstance'))
        if ($instances.Count -ne 1 -or $instances[0].GetAttribute('type') -ne 'ES_COMPARING_STRINGS_WITH_EQ' -or $instances[0].SelectSingleNode('Class').GetAttribute('classname') -ne 'edu.course.shipping.ShippingCalculator') { throw '静态结果不是唯一预期的计算器字符串比较告警。' }
        $errorsNode = $bugs.SelectSingleNode('/BugCollection/Errors')
        if ($null -eq $errorsNode -or [int]$errorsNode.errors -ne 0 -or [int]$errorsNode.missingClasses -ne 0 -or $bugs.SelectNodes('//AnalysisError|//MissingClass').Count -gt 0) { throw 'SpotBugs分析不完整或缺少类，不能当成预期失败。' }
        return [pscustomobject]@{Ready=$true; Message='3次测试通过，Checkstyle与覆盖门禁通过，仅预期SpotBugs告警拒绝候选。'}
    } catch { $reason = $_.Exception.Message }
    return [pscustomobject]@{Ready=$false; Message=$reason}
}
