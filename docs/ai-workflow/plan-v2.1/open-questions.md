# 待拍板问题 — 需求 10 / 11 / 12（v2.1 设计阶段）

> **状态：✅ 已完结 · 设计冻结（Q1–Q6 全部确认）**
> 以下问题已在实现启动前由用户一次性确认。设计文档已据此冻结，可进入实现分工。
> 本文件为 v2.1 计划的**权威决策依据**，按文档整理决策保留于原位（未随 `design-需求10/11/12` 一并归档）；核心决策记录已同步沉淀至 `docs/specs/design.md` §5.4。

## Q1（需求 12）「结束」按钮语义 — ✅ 已确认（推荐方案）
- 将中途「结束」改为保存 **partial** 记录（与后台强制退出 AC-2.10 一致），且**不**触发 `onPlanItemComplete`；仅 `tickTraining()` 自然计时结束（非 partial）触发 `markPlanItemCompleted(planItemId)`。
- 影响：改变既有「结束即记完整录」行为（历史统计口径变化），已获用户接受。

## Q2（需求 10）周期长度固定 — ✅ 已确认（推荐方案）
- 固定 **7 天**周计划，`trainingDayOffsets` 仅在该周内挑星期；更长周期留待后续迭代。

## Q3（需求 10）每日方法数量 — ✅ 已确认（**否决「每日 1 方法」**）
- 自定义阶段支持**同一天多方法**。数据模型改为按日分组：`PlanDraft.dayDrafts: [DayDraft]`、`UserPlanTemplate.days: [UserPlanTemplateDay]`；`buildCustomPlan(dayDrafts:)` 对每个 (日,方法) 生成一条 `PlanItem`。
- 既有的 `frequency`/`methodIds`/`trainingDayOffsets` 仍以计算属性保留，满足需求 10 字段命名。

## Q4（需求 10）模板就地编辑 — ✅ 已确认（推荐方案）
- v2.1 **不做**模板就地编辑；「编辑模板」=「选我的模板再改」后另存为新模板（旧模板可删）。

## Q5（需求 10）模板 description — ✅ 已确认（推荐方案）
- `UserPlanTemplate` 含可选 `description: String?`。

## Q6（需求 11）单条粒度 Repository 方法 — ✅ 已确认（仅全量保存）
- v2.1 仅实现 `updatePlanItems(planId:items:)` 全量保存；不提供 `upsertPlanItem`/`addPlanItem`/`removePlanItem` 单条方法（编辑态增删在内存草稿完成，保存时整体落库）。

---
*全部问题已确认，设计冻结。代码层（PlanModels/PlanService/PlanRepository/CDUserPlanTemplate/PlanBuilderView/PlanViewModel）已同步本次决策。后续改动请以本文件结论为准。*
