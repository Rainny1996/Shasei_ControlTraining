---
name: xcdatamodeld-debugging
description: IDEDataModelCodeGenerator崩溃问题的排查记录和XcodeGen源码分析
type: project
---

## IDEDataModelCodeGenerator崩溃排查

**问题**: CI构建(macos-15/Xcode 16)中IDEDataModelCodeGenerator崩溃，错误堆栈: CDMModel initWithXMLElement → CDMModelManager modelForURL → IDEDataModelCodeGenerator

**XcodeGen源码分析结果**:
- SourceGenerator.swift正确处理xcdatamodeld: 检测.xcdatamodeld扩展名→创建XCVersionGroup→读取.xccurrentversion→设置currentVersion
- FileType.swift确认xcdatamodeld默认buildPhase=.sources（正确）
- 如果.xccurrentversion无法读取，回退到字母顺序最后一个版本

**已排除的原因**: CRLF换行符（Git仓库已是LF，已添加.gitattributes强制LF）

**待验证的原因**:
1. XcodeGen生成的project.pbxproj中XCVersionGroup引用是否正确
2. Xcode 16已知bug（Apple Forums thread 779939）- xcdatamodeld当前版本被重置
3. 模型文件编码问题（BOM等）

**CI诊断步骤已添加**: 检查XCVersionGroup、hex dump、XcodeGen版本、构建阶段验证
**Why**: 需要CI输出确认根本原因后才能针对性修复
**How to apply**: 分析下次构建的诊断输出，根据结果决定修复方案