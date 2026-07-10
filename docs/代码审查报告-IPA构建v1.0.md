代码审查报告 — IPA 构建 / Core Data 模型（复审 v1.0）
审查对象：ControlTraining/Core/Data/Models/ControlTrainingModel.xcdatamodeld/ControlTrainingModel.xcdatamodel/contents
审查背景：GitHub Actions 构建 IPA 时 momc 崩溃（Unexpected code generation type in xml: category/extension），产出 14KB 空壳 IPA。本应已修复，现复审实际修复效果。
审查结论：⚠️ 修复不完整 — 重新构建仍会失败（新的编译错误）
一、已确认的部分
contents 中原有的 8 处 codeGenerationType="category/extension"（非法 UI 显示值）已被完全移除，不再触发 momc 的 assertion failure 解析崩溃。

✅ 搜索 "category/extension" → 0 处残留
✅ momc 模型解析阶段不再崩溃
二、遗留的致命问题（新引入的回归）
现象预判
删除 codeGenerationType 属性后，Xcode/momc 在缺少该属性时默认回退为 "class"（Class Definition）自动生成模式。而本项目在 ControlTraining/Core/Data/Models/CoreDataEntities/ 目录下提供了 8 个手写且包含完整 @NSManaged 属性的 NSManagedObject 子类：

手写文件	内容
CDUser+CoreDataClass.swift	class CDUser: NSManagedObject { @NSManaged var id: UUID ... }
CDTrainingRecord+CoreDataClass.swift	同上，含完整属性
CDTrainingMethod+CoreDataClass.swift	同上
CDTrainingPlan+CoreDataClass.swift	同上
CDPlanItem+CoreDataClass.swift	同上
CDCheckInRecord+CoreDataClass.swift	同上
CDAbilityProfile+CoreDataClass.swift	同上
CDReviewNote+CoreDataClass.swift	同上
这些文件不是空的类壳，而是连 @NSManaged 属性都手写的完整定义（另含 convenience init、领域模型转换等扩展方法）。

后果推导
删除 codeGenerationType（默认 = "class" 自动生成）
   ↓
Xcode 经 momc 自动生成 CDUser 类 + @NSManaged 属性扩展（DerivedData）
   ↓
与手写 CDUser+CoreDataClass.swift 冲突
   ↓
编译报错：Invalid redeclaration of 'CDUser' / 'id' ...（重复符号）
   ↓
.app 无法生成 → 14KB 空 IPA 再次出现 → LiveContainer "Bad file descriptor"
注意：项目源码树中不存在任何 +CoreDataProperties.swift 自动生成文件（搜索确认 0 个），说明生成责任完全由手写子类承担，进一步印证应使用 manual/none。

三、三种 codegen 取值对项目的可行性矩阵
codeGenerationType 取值	Xcode 行为	与本项目的冲突
class（删除属性后的默认）	自动生成完整类 + 属性	❌ 与手写完整类重复 → 重复符号
category（上一轮建议值）	自动生成属性扩展	❌ 与手写 @NSManaged 重复 → 重复属性
manual/none（正确值）	不生成任何代码	✅ 仅使用手写子类，无冲突
说明：本项目手写子类已同时提供类与属性，因此唯一正确值是 manual/none。上一轮报告建议的 category 经本次深查也属于错误方案，特此更正。

四、正确修复方案
将 8 个 <entity> 标签补回属性 codeGenerationType="manual/none"（与手写完整子类模式匹配）。

修改前（当前）
<entity name="CDUser" representedClassName="CDUser" syncable="YES">
修改后（正确）
<entity name="CDUser" representedClassName="CDUser" syncable="YES" codeGenerationType="manual/none">
一键修复（PowerShell）
$contents = 'ControlTraining\Core\Data\Models\ControlTrainingModel.xcdatamodeld\ControlTrainingModel.xcdatamodel\contents'
(Get-Content $contents -Raw) -replace '(<entity name="[^"]+" representedClassName="[^"]+" syncable="YES")>', '$1 codeGenerationType="manual/none">' | Set-Content $contents -NoNewline
需替换的 8 个实体：CDUser、CDTrainingMethod、CDTrainingRecord、CDTrainingPlan、CDPlanItem、CDCheckInRecord、CDAbilityProfile、CDReviewNote。

五、额外建议（次要）
构建脚本健壮性：.github/workflows/build-ipa.yml 的 Create IPA 步骤在 APP_PATH 缺失时 exit 1，逻辑正确；但 Build App 步骤 xcodebuild ... | tee build.log 未加 set -o pipefail，若 xcodebuild 失败但 tee 成功，GitHub 可能误判步骤成功。建议改为：
set -o pipefail
xcodebuild build ... 2>&1 | tee build.log
修复后请在本地用 xcodebuild build 验证无 "Invalid redeclaration" 报错，再触发 GitHub Actions。
六、复测清单（供下一轮验证）
验证项	预期
contents 中 8 个 entity 含 codeGenerationType="manual/none"	无 category/extension、无缺省
本地 xcodebuild build 无重复符号错误	通过
GitHub Actions IPA 大小	恢复正常（约 30–80MB，非 14KB）
LiveContainer 安装	成功
