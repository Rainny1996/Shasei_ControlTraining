# 归档清单 — v2.1 训练计划增强设计草案

> 归档日期：2026-07-12
> 归档原因：需求 10/11/12 的设计决策（open-questions Q1–Q6）已全部确认冻结；其核心设计已沉淀至 `docs/specs/design.md` §5（v2.1 训练计划增强设计）。本目录保留原始工作流草案，供追溯逐字段/逐方法签名细节，不再作为活跃实现依据。

## 里程碑

- **迭代**：v2.1 训练计划增强（需求 10 自定义计划 / 需求 11 当前计划逐条编辑 / 需求 12 今日训练动作直达陪练）
- **状态**：✅ 设计冻结（决策 Q1–Q6 全部确认），实现参考依据已迁移至 `docs/specs/design.md` §5
- **关联审查**：实现结论以 `docs/reviews/` 最新报告为准

## 文件清单

| 文件 | 类型 | 说明 |
|------|------|------|
| `01-需求设计.md` | 分工 Prompt | 需求/设计负责人下游执行 prompt（需求 10/11/12 拆解要点） |
| `02-数据层.md` | 分工 Prompt | 数据层负责人 prompt（UserPlanTemplate / 全量保存 / PlanService 扩展） |
| `03-SwiftUI前端.md` | 分工 Prompt | 前端负责人 prompt（PlanBuilderView / PlanEditView / PlanItemDetailView） |
| `04-测试验收.md` | 分工 Prompt | 测试负责人 prompt（AC 覆盖矩阵 / 验收结论） |
| `design-需求10-自定义计划.md` | 设计规格 | 需求 10 完整设计（交互流 / 数据模型 / 服务契约）— 核心已并入 `design.md` §5.1 |
| `design-需求11-逐条编辑.md` | 设计规格 | 需求 11 完整设计（编辑状态机 / 校验 / 契约）— 核心已并入 `design.md` §5.2 |
| `design-需求12-直达陪练.md` | 设计规格 | 需求 12 完整设计（数据流 / CoachView 契约 / 详情页）— 核心已并入 `design.md` §5.3 |

## 保留在外的相关文件

- `docs/ai-workflow/plan-v2.1/open-questions.md` — 决策记录（Q1–Q6 已确认），按文档整理决策**保留原位**，作为设计冻结的权威依据。
- `docs/BUG-TASK-ASSIGNMENT.md` — v0.0.2 Bug 修复任务（✅ 4/4 已修复），保留原位。
- `docs/specs/design.md` §5 — 本里程碑的**活跃设计依据**（取代上述三个 `design-需求*` 文件）。

## 使用说明

- 新功能实现 / 代码审查：以 `docs/specs/design.md` §5 为准，本目录仅作历史追溯。
- 如需查看某需求的逐字段定义或完整 mermaid 图，查阅对应的 `design-需求*.md` 原文。
