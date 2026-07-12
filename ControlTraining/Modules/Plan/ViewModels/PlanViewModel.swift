import Foundation
import SwiftUI

/// 计划视图模型 - 管理训练计划的状态和业务逻辑
class PlanViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var currentPlan: TrainingPlan?
    @Published var todayItems: [PlanItem] = []
    @Published var weekItems: [PlanItem] = []
    @Published var selectedPeriod: PlanPeriod = .week
    @Published var isLoading: Bool = false
    @Published var showAssessment: Bool = false
    @Published var showTemplateSelection: Bool = false
    @Published var reminderHour: Int = 8
    @Published var reminderMinute: Int = 0
    @Published var reminderEnabled: Bool = false
    
    // MARK: - 需求 10：自定义计划
    @Published var showCustomPlanBuilder: Bool = false
    @Published var userTemplates: [UserPlanTemplate] = []
    /// 自定义计划编辑器内存草稿（需求 10 / AC-10.2~10.6）；PlanBuilderView 通过 $customPlanDraft 双向绑定。
    @Published var customPlanDraft = PlanDraft()
    
    // MARK: - 需求 11：逐条编辑
    @Published var showPlanEditor: Bool = false
    @Published var editingDraft: PlanEditDraft? = nil
    
    // MARK: - 需求 12：直达陪练
    @Published var showPlanItemDetail: Bool = false
    @Published var selectedPlanItem: PlanItem?
    
    // MARK: - 计算属性
    
    /// 计划进度百分比
    var progressPercent: Int {
        guard let plan = currentPlan else { return 0 }
        return Int(plan.progress * 100)
    }
    
    /// 今日完成项数
    var todayCompletedCount: Int {
        todayItems.filter { $0.isCompleted }.count
    }
    
    /// 今日总项数
    var todayTotalCount: Int {
        todayItems.count
    }
    
    /// 本周完成项数
    var weekCompletedCount: Int {
        weekItems.filter { $0.isCompleted }.count
    }
    
    /// 本周总项数
    var weekTotalCount: Int {
        weekItems.count
    }
    
    /// 计划目标
    var planGoal: String {
        currentPlan?.goal ?? "暂无计划"
    }
    
    /// 计划剩余天数
    var remainingDays: Int {
        guard let plan = currentPlan else { return 0 }
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: Date(), to: plan.endDate).day ?? 0
        return max(0, days)
    }
    
    /// 是否有活跃计划
    var hasActivePlan: Bool {
        currentPlan != nil
    }
    
    // MARK: - Dependencies
    
    private let planRepository: PlanRepository
    private let trainingRepository: TrainingRepository
    
    init(planRepository: PlanRepository = PlanRepository(),
         trainingRepository: TrainingRepository = TrainingRepository()) {
        self.planRepository = planRepository
        self.trainingRepository = trainingRepository
        loadReminderSettings()
    }
    
    // MARK: - 数据加载
    
    /// 加载计划数据
    func loadPlan() {
        isLoading = true
        
        // 加载当前活跃计划
        currentPlan = planRepository.fetchActivePlan()
        
        // 加载今日计划项
        todayItems = planRepository.fetchTodayPlanItems()
        
        // 加载本周计划项
        loadWeekItems()
        
        // 检查是否需要评估
        if currentPlan == nil {
            let defaults = UserDefaults.standard
            showAssessment = !defaults.bool(forKey: "hasCompletedAssessment")
        }
        
        isLoading = false
    }
    
    /// 加载本周计划项
    private func loadWeekItems() {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek)!
        weekItems = planRepository.fetchPlanItems(from: startOfWeek, to: endOfWeek)
    }
    
    /// 刷新数据
    func refresh() {
        loadPlan()
    }
    
    // MARK: - 计划操作
    
    /// 使用模板创建计划
    func createPlanFromTemplate(_ template: PlanTemplate) {
        let plan = PlanService.shared.generatePlanFromTemplate(template)
        planRepository.saveTrainingPlan(plan)
        loadPlan()
    }
    
    /// 重新生成计划（基于最新训练数据）
    func regeneratePlan() {
        guard let assessment = AssessmentViewModel.loadSavedAssessment() else { return }
        
        // 删除旧计划
        if let oldPlan = currentPlan {
            planRepository.deletePlan(oldPlan.id)
        }
        
        // 生成新计划
        let plan = PlanService.shared.generatePlan(from: assessment)
        planRepository.saveTrainingPlan(plan)
        loadPlan()
    }
    
    /// 标记计划项完成
    func markItemCompleted(_ itemId: UUID) {
        planRepository.markPlanItemCompleted(itemId: itemId)
        loadPlan()
    }
    
    /// 动态调整计划
    func adjustPlanIfNeeded() {
        guard let plan = currentPlan else { return }
        
        // 获取近期训练记录
        let records = trainingRepository.fetchRecentRecords(limit: 10)
        guard !records.isEmpty else { return }
        
        // 调整计划
        let adjustedPlan = PlanService.shared.adjustPlan(plan, basedOn: records)
        
        // 保存调整后的计划
        if adjustedPlan.items != plan.items {
            planRepository.updatePlanItems(planId: adjustedPlan.id, items: adjustedPlan.items)
            loadPlan()
        }
    }
    
    // MARK: - 需求 10：自定义计划
    
    /// 打开自定义计划编辑器（≤2 次点击，AC-10.1）
    /// - Parameter template: 选填预设/我的模板，传入即「选模板再改」；nil 为「空白自建」。
    func openCustomPlan(from template: PlanTemplate? = nil) {
        if let template = template {
            customPlanDraft = PlanService.shared.draftFromTemplate(template)
        } else {
            customPlanDraft = PlanDraft()
        }
        loadUserTemplates()
        showCustomPlanBuilder = true
    }
    
    /// 重新加载「我的模板」（AC-10.5）
    func loadUserTemplates() {
        userTemplates = PlanService.shared.loadUserTemplates()
    }
    
    /// 将当前草稿保存为「我的模板」（AC-10.5 / Q3 以 days 记录每日方法）
    func saveCurrentDraftAsTemplate(name: String) {
        let draft = customPlanDraft
        let days = draft.dayDrafts.map {
            UserPlanTemplateDay(dayOffset: $0.dayOffset, methodIds: $0.methodIds)
        }
        let template = UserPlanTemplate(
            name: name,
            difficulty: draft.difficulty,
            frequency: draft.dayDrafts.count,
            goal: draft.goal,
            icon: draft.goal.icon,
            days: days
        )
        PlanService.shared.saveUserTemplate(template)
        loadUserTemplates()
    }
    
    /// 删除「我的模板」（AC-10.5）
    func deleteUserTemplate(_ id: UUID) {
        PlanRepository().deleteUserTemplate(id)
        loadUserTemplates()
    }
    
    /// 由草稿生成计划并写入当前活跃计划（AC-10.6 / Q3 每日可多方法）
    /// 覆盖前二次确认由 `PlanBuilderView` 负责（明确「将替换当前计划」）。
    func generatePlanFromDraft() {
        guard !customPlanDraft.dayDrafts.isEmpty,
              customPlanDraft.dayDrafts.contains(where: { !$0.methodIds.isEmpty }) else { return }
        commitCustomPlan()
    }

    private func commitCustomPlan() {
        let plan = PlanService.shared.buildCustomPlan(
            dayDrafts: customPlanDraft.dayDrafts,
            goal: customPlanDraft.goal
        )
        // 覆盖写：删除旧活跃计划，避免 fetchActivePlan 取到多个（呼应 regeneratePlan）
        if let old = currentPlan {
            planRepository.deletePlan(old.id)
        }
        planRepository.saveTrainingPlan(plan)
        showCustomPlanBuilder = false
        loadPlan()
    }
    
    // MARK: - 需求 11：当前计划逐条编辑
    
    /// 进入编辑模式：深拷贝当前计划为草稿（AC-11.1/11.5）
    func beginPlanEditing() {
        guard let plan = currentPlan else { return }
        editingDraft = PlanEditDraft(
            planId: plan.id,
            startDate: plan.startDate,
            endDate: plan.endDate,
            items: plan.items
        )
        showPlanEditor = true
    }
    
    /// 替换某项的训练方法（AC-11.2）
    func editItemMethod(_ itemId: UUID, method: TrainingMethod) {
        guard var draft = editingDraft else { return }
        if let idx = draft.items.firstIndex(where: { $0.id == itemId }) {
            let old = draft.items[idx]
            draft.items[idx] = PlanItem(
                id: old.id, date: old.date, methodId: method.id,
                methodName: method.name, duration: old.duration,
                isCompleted: old.isCompleted, completedAt: old.completedAt
            )
        }
        editingDraft = draft
    }
    
    /// 修改某项单次时长（单位：秒，AC-11.2）
    func editItemDuration(_ itemId: UUID, duration: TimeInterval) {
        guard var draft = editingDraft else { return }
        if let idx = draft.items.firstIndex(where: { $0.id == itemId }) {
            let old = draft.items[idx]
            draft.items[idx] = PlanItem(
                id: old.id, date: old.date, methodId: old.methodId,
                methodName: old.methodName, duration: duration,
                isCompleted: old.isCompleted, completedAt: old.completedAt
            )
        }
        editingDraft = draft
    }
    
    /// 修改某项所在日期（AC-11.2）
    func editItemDate(_ itemId: UUID, date: Date) {
        guard var draft = editingDraft else { return }
        if let idx = draft.items.firstIndex(where: { $0.id == itemId }) {
            let old = draft.items[idx]
            draft.items[idx] = PlanItem(
                id: old.id, date: date, methodId: old.methodId,
                methodName: old.methodName, duration: old.duration,
                isCompleted: old.isCompleted, completedAt: old.completedAt
            )
        }
        editingDraft = draft
    }
    
    /// 新增项目（从方法池选，默认未完成；时长取自所选方法，AC-11.3）
    func addItem(method: TrainingMethod, date: Date) {
        guard var draft = editingDraft else { return }
        let item = PlanItem(
            date: date, methodId: method.id,
            methodName: method.name, duration: method.defaultDuration
        )
        draft.items.append(item)
        editingDraft = draft
    }
    
    /// 删除项目（AC-11.3）
    func removeItem(_ itemId: UUID) {
        guard var draft = editingDraft else { return }
        draft.items.removeAll { $0.id == itemId }
        editingDraft = draft
    }
    
    /// 编辑校验错误（AC-11.5）
    struct PlanEditValidationError: Identifiable {
        let id = UUID()
        let message: String
    }
    
    /// 保存编辑：先校验再落库（AC-11.4/11.5）
    /// - Returns: 非空表示校验失败（不写库），调用方据此提示。
    func savePlanEdits() -> [PlanEditValidationError] {
        guard var draft = editingDraft else { return [] }
        
        var errors: [PlanEditValidationError] = []
        let calendar = Calendar.current
        let startOfPlan = calendar.startOfDay(for: draft.startDate)
        let endOfPlan = calendar.startOfDay(for: draft.endDate)
        
        for item in draft.items {
            if item.duration <= 0 {
                errors.append(PlanEditValidationError(message: "训练时长必须大于 0 分钟"))
                break
            }
            let itemDay = calendar.startOfDay(for: item.date)
            if !(itemDay >= startOfPlan && itemDay <= endOfPlan) {
                errors.append(PlanEditValidationError(message: "训练日期必须在该计划周期内"))
                break
            }
        }
        if draft.items.isEmpty {
            errors.append(PlanEditValidationError(message: "计划至少包含 1 个训练项目"))
        }
        
        if !errors.isEmpty { return errors }
        
        planRepository.updatePlanItems(planId: draft.planId, items: draft.items)
        editingDraft = nil
        showPlanEditor = false
        loadPlan()
        return []
    }
    
    /// 取消编辑：丢弃草稿（AC-11.5）
    func cancelPlanEdits() {
        editingDraft = nil
        showPlanEditor = false
    }
    
    // MARK: - 需求 12：今日动作直达陪练
    
    /// 打开计划项详情（AC-12.1）
    func openPlanItemDetail(_ item: PlanItem) {
        selectedPlanItem = item
        showPlanItemDetail = true
    }
    
    // MARK: - 提醒设置
    
    /// 切换提醒开关
    func toggleReminder() {
        reminderEnabled.toggle()
        if reminderEnabled {
            NotificationService.shared.requestAuthorization()
            NotificationService.shared.scheduleDailyTrainingReminder(hour: reminderHour, minute: reminderMinute)
        } else {
            NotificationService.shared.cancelDailyTrainingReminder()
        }
        saveReminderSettings()
    }
    
    /// 更新提醒时间
    func updateReminderTime(hour: Int, minute: Int) {
        reminderHour = hour
        reminderMinute = minute
        if reminderEnabled {
            NotificationService.shared.scheduleDailyTrainingReminder(hour: hour, minute: minute)
        }
        saveReminderSettings()
    }
    
    /// 加载提醒设置
    private func loadReminderSettings() {
        let defaults = UserDefaults.standard
        reminderEnabled = defaults.bool(forKey: "reminderEnabled")
        reminderHour = defaults.integer(forKey: "reminderHour")
        reminderMinute = defaults.integer(forKey: "reminderMinute")
        if reminderHour == 0 && reminderMinute == 0 {
            reminderHour = 8
        }
    }
    
    /// 保存提醒设置
    private func saveReminderSettings() {
        let defaults = UserDefaults.standard
        defaults.set(reminderEnabled, forKey: "reminderEnabled")
        defaults.set(reminderHour, forKey: "reminderHour")
        defaults.set(reminderMinute, forKey: "reminderMinute")
    }
    
    // MARK: - 日历数据
    
    /// 获取指定日期的计划项
    func itemsForDate(_ date: Date) -> [PlanItem] {
        let calendar = Calendar.current
        return weekItems.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }
    
    /// 判断指定日期是否有计划
    func hasItemsOnDate(_ date: Date) -> Bool {
        !itemsForDate(date).isEmpty
    }
    
    /// 判断指定日期是否全部完成
    func isDateCompleted(_ date: Date) -> Bool {
        let items = itemsForDate(date)
        return !items.isEmpty && items.allSatisfy { $0.isCompleted }
    }
    
    /// 判断指定日期是否部分完成
    func isDatePartiallyCompleted(_ date: Date) -> Bool {
        let items = itemsForDate(date)
        let completedCount = items.filter { $0.isCompleted }.count
        return completedCount > 0 && completedCount < items.count
    }
}