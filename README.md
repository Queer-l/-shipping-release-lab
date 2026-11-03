# Shipping Release Lab：第8次课

## 规则与版本
v1.2.0/main为已发布基线，只支持STANDARD满199.00免运费，否则15.00，VIP不受支持。
feature/vip-shipping增加VIP满99.00免运费，STANDARD保持199.00，等于门槛也免运费。支持非负金额及STANDARD/VIP两种类型。

## 准备与实践
JDK 21、Maven 3.9+、Git，保留.git，不重新初始化。个人操作、个人复核、各自提交，教师抽查。无需平台账号、远程仓库、在线CI或同伴审批。
学生起始包课前只需双击preflight.cmd。首次联网下载依赖，看到READY_EXPECTED_SPOTBUGS表示3次测试、Checkstyle与覆盖门禁通过，唯一失败为预期字符串比较告警。环境问题看target/preflight/preflight.log。不要提前修代码。开始课堂修改后不再运行预检。

按学生任务书补7个测试，先观察失败，再修复计算器；保留原有3个测试及辅助方法。需求见review/CHANGE_REQUEST.md，个人检查单见review/SELF_CHECK.md。

## 默认本地质量检查
```powershell
mvn -B test
mvn -B checkstyle:check
mvn -B clean verify
```
JUnit验证断言；Checkstyle检查main/test Java文件中的Tab及行尾空白；JaCoCo要求ShippingCalculator行覆盖率≥90%、分支覆盖率≥80%；SpotBugs分析计算器，纳入Low优先级。Checkstyle不需要profile，所有检查均已绑定默认verify，不能跳过检查、降低阈值或删除原测试。

课堂临时在Main.java打印行末尾加入空格，运行checkstyle:check定位失败，删除后复查通过；IDE清理行尾空格时可输入真实Tab。不要把字符“\t”当作Tab。Main.java恢复后无需提交临时错误。报告：target/checkstyle-result.xml、target/site/jacoco/index.html、target/spotbugsXml.xml。前项失败时后项可能未执行，未执行不算通过。

本地运行属于自动化质量检查，CI仅作概念介绍，不提供在线工作流或远程任务。

## 合并、发布与提交
个人复核修复后完整Commit及三项检查单，通过后Squash合并到main。将POM的1.3.0-SNAPSHOT准备为1.3.0，整理CHANGELOG，更新下面JAR运行命令并提交。干净main执行完整verify与三条CLI验证后打v1.3.0，再复制同一JAR到../release，核对SHA-256和副本运行，不重新构建替换交付文件。
```powershell
java -cp target/shipping-release-lab-1.3.0.jar edu.course.shipping.Main 99.00 VIP
```
只交一个学号_L08.zip：完整shipping-release-lab（含.git）与并列release目录（JAR、RELEASE_RECORD.md）。记录模板复制到仓库外填写。不另交报告、截图、日志或在线CI证据。具体步骤以学生任务书为准。
