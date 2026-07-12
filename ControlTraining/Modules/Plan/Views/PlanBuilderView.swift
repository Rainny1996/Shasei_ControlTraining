import SwiftUI

/// 自定义计划编辑器（需求 10 / AC-10.1~10.7，Q3 支持一日多方法）
/// 支持「选模板再改」与「空白自建」两种起点，仅暴露方法/每周天数/具体日期三类可调维度
/// （AC-10.4，不暴露时长/强度/周期），可保存为「我的模板」并生成活跃计划。
struct PlanBuilderView: View {
    @ObservedObject var viewModel: PlanViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showTemplatePicker = false
    @State private var showNameDialog = false
    @State private var templateName = ""

    // 每日方法选择 sheet 状态
    @State private var showMethodPicker = false
    @State private var editingDayId: UUID?
    @State private var tempSelectedMethods: Set<UUID> = []
    @State private var showOverwriteConfirm = false

    private var draft: Binding<PlanDraft> { $viewModel.customPlanDraft }
    private let weekdayNames = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 20) {
                        // 组建方式
                        assembleModeSection

                        // 目标 / 难度
                        goalSection

                        // 每周训练天数
                        weeklyDaysSection

                        // 具体训练日期
                        dateSection

                        // 每日训练方法（Q3：支持一日多方法）
                        methodPerDaySection
                    }
                    .padding()
                }

                // 底部操作栏
                bottomBar
            }
            .navigationTitle("自定义计划")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                        .accessibilityLabel("取消自定义计划")
                }
            }
            // 选模板起点 sheet（预设 + 我的模板）
            .sheet(isPresented: $showTemplatePicker) {
                templatePickerSheet
            }
            // 保存为我的模板：命名
            .alert("保存为模板", isPresented: $showNameDialog) {
                TextField("模板名称", text: $templateName)
                Button("保存") {
                    let name = templateName.trimmingCharacters(in: .whitespaces)
                    if !name.isEmpty {
                        viewModel.customPlanDraft.name = name
                        viewModel.saveCurrentDraftAsTemplate(name)
                    }
                    templateName = ""
                }
                Button("取消", role: .cancel) { templateName = "" }
            } message: {
                Text("为当前自定义计划输入一个名称，便于下次复用。")
            }
            // 每日方法多选 sheet
            .sheet(isPresented: $showMethodPicker) {
                methodPickerSheet
            }
            // 覆盖当前计划：二次确认（AC-10.6）
            .confirmationDialog("将替换当前计划", isPresented: $showOverwriteConfirm) {
                Button("替换并生成", role: .destructive) {
                    viewModel.generatePlanFromDraft()
                }
                Button("取消", role: .cancel) { }
            } message: {
                Text("当前已有进行中的计划，生成新计划将覆盖它。是否继续？")
            }
        }
    }

    // MARK: - 组建方式

    private var assembleModeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("组建方式")
                .font(.headline)

            if !viewModel.customPlanDraft.name.isEmpty {
                HStack {
                    Image(systemName: "doc.text")
                        .foregroundColor(.accentColor)
                    Text("当前基于：\(viewModel.customPlanDraft.name)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Button(action: { showTemplatePicker = true }) {
                HStack {
                    Image(systemName: "square.on.square")
                    Text("从模板开始（选模板再改）")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.accentColor.opacity(0.1))
                .foregroundColor(.accentColor)
                .cornerRadius(12)
            }
            .accessibilityLabel("从模板开始选模板再改")

            Button(action: { viewModel.customPlanDraft = PlanDraft() }) {
                HStack {
                    Image(systemName: "plus.circle")
                    Text("空白自建")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(.systemGray6))
                .foregroundColor(.primary)
                .cornerRadius(12)
            }
            .accessibilityLabel("空白自建")
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    // MARK: - 目标 / 难度

    private var goalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("训练目标 / 难度")
                .font(.headline)

            Picker("训练目标", selection: draft.goal) {
                ForEach(TrainingGoal.allCases, id: \.self) { goal in
                    Text(goal.rawValue).tag(goal)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("训练目标")

            Picker("难度", selection: draft.difficulty) {
                ForEach(DifficultyLevel.allCases, id: \.self) { level in
                    Text(level.rawValue).tag(level)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("难度")
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    // MARK: - 每周训练天数

    private var weeklyDaysSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("每周训练天数")
                .font(.headline)

            Stepper(value: trainingDayCount, in: 1...6, step: 1) {
                Text("每周 \(viewModel.customPlanDraft.dayDrafts.count) 天")
                    .font(.subheadline)
            }
            .accessibilityLabel("每周训练天数 \(viewModel.customPlanDraft.dayDrafts.count) 天")
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    private var trainingDayCount: Binding<Int> {
        Binding(
            get: { viewModel.customPlanDraft.dayDrafts.count },
            set: { newCount in
                var d = viewModel.customPlanDraft
                d.dayDrafts = PlanBuilderView.redistributeDays(d.dayDrafts, count: newCount)
                viewModel.customPlanDraft = d
            }
        )
    }

    // MARK: - 具体训练日期

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("具体训练日期")
                .font(.headline)

            ForEach(0..<7, id: \.self) { offset in
                let selected = viewModel.customPlanDraft.dayDrafts.contains(where: { $0.dayOffset == offset })
                Button(action: { toggleDay(offset) }) {
                    HStack {
                        Text(weekdayNames[offset])
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        Spacer()
                        if selected {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .padding(.vertical, 8)
                    .accessibilityLabel("\(weekdayNames[offset]) \(selected ? "已选" : "未选")")
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    // MARK: - 每日训练方法（Q3 支持一日多方法）

    private var methodPerDaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("每日训练方法（可多选，支持一天多项）")
                .font(.headline)

            if viewModel.customPlanDraft.dayDrafts.isEmpty {
                Text("请先在下方选择训练日期")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            ForEach($viewModel.customPlanDraft.dayDrafts) { $day in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(weekdayNames[day.dayOffset])
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        Button(action: { openMethodPicker(for: day.id) }) {
                            Image(systemName: "plus.circle")
                                .foregroundColor(.accentColor)
                        }
                        .accessibilityLabel("为\(weekdayNames[day.dayOffset])设置训练方法")
                    }
                    if day.methodIds.isEmpty {
                        Text("未选择方法")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        let names = day.methodIds.compactMap { id in
                            TrainingContentData.allTrainingMethods().first(where: { $0.id == id })?.name
                        }
                        Text(names.joined(separator: "、"))
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                }
                .padding(.vertical, 6)
                .accessibilityElement(children: .combine)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    // MARK: - 底部操作栏

    private var bottomBar: some View {
        VStack(spacing: 12) {
            Button(action: { showNameDialog = true }) {
                HStack {
                    Image(systemName: "tray.and.arrow.down")
                    Text("保存为我的模板")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(.systemGray6))
                .foregroundColor(.primary)
                .cornerRadius(12)
            }
            .accessibilityLabel("保存为我的模板")

            let hasMethod = viewModel.customPlanDraft.dayDrafts.contains(where: { !$0.methodIds.isEmpty })
            Button(action: { generate() }) {
                HStack {
                    Image(systemName: "checkmark.circle")
                    Text("生成计划")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(hasMethod ? Color.accentColor : Color(.systemGray3))
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(!hasMethod)
            .accessibilityLabel("生成计划")

            if !hasMethod {
                Text("请至少为 1 个训练日选择 1 个训练方法")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 12)
    }

    // MARK: - 模板选择 sheet

    private var templatePickerSheet: some View {
        NavigationStack {
            List {
                Section("预设模板") {
                    ForEach(PlanService.planTemplates()) { template in
                        Button(action: { selectPreset(template) }) {
                            HStack {
                                Image(systemName: template.icon)
                                    .foregroundColor(.accentColor)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(template.name).font(.subheadline)
                                    Text(template.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 4)
                            .accessibilityLabel("选择模板 \(template.name)")
                        }
                        .buttonStyle(.plain)
                    }
                }

                Section("我的模板") {
                    if viewModel.userTemplates.isEmpty {
                        Text("暂无保存的模板")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    ForEach(viewModel.userTemplates) { ut in
                        HStack {
                            Button(action: { selectUserTemplate(ut) }) {
                                HStack {
                                    Image(systemName: ut.icon)
                                        .foregroundColor(.accentColor)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(ut.name).font(.subheadline)
                                        Text("每周\(ut.frequency)天 · \(ut.goal.rawValue)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                }
                                .padding(.vertical, 4)
                                .accessibilityLabel("复用模板 \(ut.name)")
                            }
                            .buttonStyle(.plain)

                            Button(action: { viewModel.deleteUserTemplate(ut.id) }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .accessibilityLabel("删除模板 \(ut.name)")
                        }
                    }
                }
            }
            .navigationTitle("选择起点模板")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") { showTemplatePicker = false }
                        .accessibilityLabel("关闭")
                }
            }
        }
    }

    // MARK: - 每日方法选择 sheet

    private var methodPickerSheet: some View {
        NavigationStack {
            List(TrainingContentData.allTrainingMethods()) { method in
                Button(action: { toggleTempMethod(method.id) }) {
                    HStack {
                        Text(method.name)
                        Spacer()
                        if tempSelectedMethods.contains(method.id) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .accessibilityLabel("\(method.name) \(tempSelectedMethods.contains(method.id) ? "已选" : "未选")")
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("选择训练方法（可多选）")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { commitMethodPicker() }
                        .accessibilityLabel("完成方法选择")
                }
            }
        }
    }

    // MARK: - 交互辅助

    /// 生成计划（AC-10.6）：若已存在活跃计划，先弹二次确认「将替换当前计划」。
    private func generate() {
        if viewModel.hasActivePlan {
            showOverwriteConfirm = true
        } else {
            viewModel.generatePlanFromDraft()
        }
    }

    private func openMethodPicker(for dayId: UUID) {
        let methods = viewModel.customPlanDraft.dayDrafts.first(where: { $0.id == dayId })?.methodIds ?? []
        tempSelectedMethods = Set(methods)
        editingDayId = dayId
        showMethodPicker = true
    }

    private func toggleTempMethod(_ id: UUID) {
        if tempSelectedMethods.contains(id) {
            tempSelectedMethods.remove(id)
        } else {
            tempSelectedMethods.insert(id)
        }
    }

    private func commitMethodPicker() {
        guard let dayId = editingDayId else { return }
        var d = viewModel.customPlanDraft
        if let idx = d.dayDrafts.firstIndex(where: { $0.id == dayId }) {
            d.dayDrafts[idx].methodIds = Array(tempSelectedMethods)
        }
        viewModel.customPlanDraft = d
    }

    private func toggleDay(_ offset: Int) {
        var d = viewModel.customPlanDraft
        if let idx = d.dayDrafts.firstIndex(where: { $0.dayOffset == offset }) {
            d.dayDrafts.remove(at: idx)
        } else {
            d.dayDrafts.append(DayDraft(dayOffset: offset, methodIds: []))
            d.dayDrafts.sort { $0.dayOffset < $1.dayOffset }
        }
        viewModel.customPlanDraft = d
    }

    private func selectPreset(_ template: PlanTemplate) {
        var d = PlanService.shared.draftFromTemplate(template)
        d.name = template.name
        viewModel.customPlanDraft = d
        showTemplatePicker = false
    }

    private func selectUserTemplate(_ ut: UserPlanTemplate) {
        viewModel.customPlanDraft = PlanService.shared.draftFromUserTemplate(ut)
        showTemplatePicker = false
    }

    // MARK: - 排期分布辅助

    /// 将 n 个训练日均匀分布在 0...6（保留既有每日方法分配）
    static func redistributeDays(_ current: [DayDraft], count: Int) -> [DayDraft] {
        guard count > 0 else { return [] }
        let offsets = PlanBuilderView.distributeOffsets(count)
        var reused = current
        var result: [DayDraft] = []
        for off in offsets {
            if let idx = reused.firstIndex(where: { $0.dayOffset == off }) {
                result.append(reused.remove(at: idx))
            } else {
                result.append(DayDraft(dayOffset: off, methodIds: []))
            }
        }
        return result.sorted { $0.dayOffset < $1.dayOffset }
    }

    /// 均匀分布 n 个偏移量到 0...6
    static func distributeOffsets(_ n: Int) -> [Int] {
        guard n > 0 else { return [] }
        var offsets: [Int] = []
        for i in 0..<n {
            let idx = (i * 7) / n
            if !offsets.contains(idx) { offsets.append(idx) }
        }
        var c = 0
        while offsets.count < n, c < 7 {
            if !offsets.contains(c) { offsets.append(c) }
            c += 1
        }
        return offsets.sorted()
    }
}

#Preview {
    PlanBuilderView(viewModel: PlanViewModel())
}
