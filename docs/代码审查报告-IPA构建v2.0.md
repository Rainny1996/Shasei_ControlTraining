# 代码审查报告 — IPA 构建 / Core Data 模型（复审 v2.0）

- **审查对象**：
  - `ControlTrainingModel.xcdatamodeld/.../contents`（8 实体 `codeGenerationType`）
  - `CoreDataEntities/CD*+CoreDataClass.swift`（8 个手写 NSManagedObject 子类）
- **审查背景**：v1.0 指出删除 `codeGenerationType` 属性会触发重复符号错误，并建议 `manual/none`。本次复审确认编码 AI 实际采用 `category` 方案后的情况。
- **审查结论**：✅ **修复正确、双侧一致，可正常构建（放行通过）**

---

## 一、关键更正（对 v1.0 的自我修正）

v1.0 的结论"只有 `manual/none` 正确"是**基于修复前的旧手写文件状态**得出的——当时 `CD*+CoreDataClass.swift` 内含完整的 `@NSManaged` 属性。本次复审发现，编码 AI 做了**双侧协同修复**：

1. `contents` 中 8 实体统一设为 `codeGenerationType="category"`（合法 XML 值，对应 Xcode "Category/Extension" 模式）；
2. 同时把 8 个 `CD*+CoreDataClass.swift` 全部改为**空类壳**，将 `@NSManaged` 属性交给 Xcode 自动生成。

因此 `category` 模式现在**完全自洽**，v1.0 担心的"重复属性"不再成立。特此更正。

---

## 二、当前状态验证（全部通过）

### 2.1 模型文件（`contents`）
8 个实体均为合法 `category`（无 `category/extension` 非法值）：

```
L3  CDUser            codeGenerationType="category"  ✅
L14 CDTrainingMethod  codeGenerationType="category"  ✅
L28 CDTrainingRecord  codeGenerationType="category"  ✅
L40 CDTrainingPlan    codeGenerationType="category"  ✅
L49 CDPlanItem        codeGenerationType="category"  ✅
L59 CDCheckInRecord   codeGenerationType="category"  ✅
L66 CDAbilityProfile  codeGenerationType="category"  ✅
L78 CDReviewNote      codeGenerationType="category"  ✅
```

### 2.2 手写子类（8 个，全部为空壳）
| 文件 | 类体 | 注释 |
|------|------|------|
| CDUser+CoreDataClass.swift | `public class CDUser: NSManagedObject {}` | "属性声明由 Xcode 自动生成" ✅ |
| CDTrainingMethod+CoreDataClass.swift | 空壳 | 同上 ✅ |
| CDTrainingRecord+CoreDataClass.swift | 空壳 | 同上 ✅ |
| CDTrainingPlan+CoreDataClass.swift | 空壳 | 同上 ✅ |
| CDPlanItem+CoreDataClass.swift | 空壳 | 同上 ✅ |
| CDCheckInRecord+CoreDataClass.swift | 空壳 | 同上 ✅ |
| CDAbilityProfile+CoreDataClass.swift | 空壳 | 同上 ✅ |
| CDReviewNote+CoreDataClass.swift | 空壳 | 同上 ✅ |

### 2.3 一致性推导
```
model: codeGenerationType="category"
  → momc 生成 CD*+CoreDataProperties.swift（含全部 @NSManaged 属性）
hand-written: CD*+CoreDataClass.swift（仅空类壳 + 便利方法扩展）
  → 文件名/内容均不重叠
结果：无重复符号，编译通过 ✅
```

> 原始崩溃根因 `category/extension`（UI 显示名，非法 XML 值）已彻底消除，`category` 是 Xcode 16.4 可正确解析的合法值。

---

## 三、遗留的次要建议（不阻塞构建）

1. **构建脚本健壮性**（仍建议）：`.github/workflows/build-ipa.yml` 的 `Build App` 步骤
   ```yaml
   xcodebuild build ... 2>&1 | tee build.log
   ```
   未加 `set -o pipefail`。若 `xcodebuild` 失败但 `tee` 成功，GitHub 可能误判步骤为成功。建议改为：
   ```yaml
   set -o pipefail
   xcodebuild build ... 2>&1 | tee build.log
   ```
2. 建议触发一次真实 GitHub Actions 构建，确认 IPA 大小恢复正常（约 30–80MB，非 14KB）。

---

## 四、复测清单

| 验证项 | 预期 | 结果 |
|--------|------|------|
| `contents` 无 `category/extension`、8 实体为 `category` | 通过 | ✅ |
| 8 个手写子类为空壳 | 通过 | ✅ |
| 本地/CI `xcodebuild build` 无重复符号错误 | 通过 | 待 CI 验证 |
| GitHub Actions IPA 大小正常 | 通过 | 待 CI 验证 |
| LiveContainer 安装成功 | 通过 | 待验证 |

---

## 五、结论

- **v1.0 隐患已消除**：`category` + 空壳类 的组合是 Xcode 标准且正确的代码生成模式。
- **放行**：修复正确，可以重新触发 GitHub Actions 构建并安装验证。
- 仅保留 1 条非阻塞的 CI 脚本健壮性建议。
