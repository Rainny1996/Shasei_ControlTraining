import Foundation

// MARK: - Training Plan Model

/// 训练计划数据模型
struct TrainingPlan: Identifiable {
    let id: UUID
    let startDate: Date
    let endDate: Date
    var items: [PlanItem]
    var progress: Double
    let goal: String
    
    init(id: UUID = UUID(),
         startDate: Date = Date(),
         endDate: Date,
         items: [PlanItem] = [],
         progress: Double = 0,
         goal: String = "") {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.items = items
        self.progress = progress
        self.goal = goal
    }
    
    /// 计划周期类型
    var periodType: PlanPeriod {
        let days = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        switch days {
        case 1...7: return .week
        case 8...31: return .month
        default: return .quarter
        }
    }
    
    /// 计算完成进度
    mutating func updateProgress() {
        guard !items.isEmpty else {
            progress = 0
            return
        }
        let completedCount = items.filter { $0.isCompleted }.count
        progress = Double(completedCount) / Double(items.count)
    }
}

/// 计划周期
enum PlanPeriod: String, CaseIterable {
    case week = "短期（1周）"
    case month = "中期（1月）"
    case quarter = "长期（3月）"
}

/// 计划项
struct PlanItem: Identifiable, Equatable {
    let id: UUID
    let date: Date
    let methodId: UUID
    let methodName: String
    let duration: TimeInterval
    var isCompleted: Bool
    var completedAt: Date?
    
    init(id: UUID = UUID(),
         date: Date,
         methodId: UUID,
         methodName: String,
         duration: TimeInterval,
         isCompleted: Bool = false,
         completedAt: Date? = nil) {
        self.id = id
        self.date = date
        self.methodId = methodId
        self.methodName = methodName
        self.duration = duration
        self.isCompleted = isCompleted
        self.completedAt = completedAt
    }
}

// MARK: - 自定义计划草稿（不落库，仅编辑器内存态）

/// 单日草稿：某个训练日及其方法（需求 10 / Q3 支持一日多方法）
struct DayDraft: Identifiable, Hashable {
    let id: UUID = UUID()
    var dayOffset: Int        // 0...6，相对 plan.startDate 的星期偏移
    var methodIds: [UUID]      // 该日选择的训练方法（≥1，支持多方法）
}

/// 自定义计划编辑器内存草稿（需求 10 / AC-10.2/10.3/10.4，Q3 支持一日多方法）
/// - 由模板初始化：前端先调 `PlanService.draftFromTemplate(_:)` 得到预填草稿（按日分组）
/// - 由空白初始化：`dayDrafts=[]`，`goal/difficulty` 由用户选择
struct PlanDraft {
    var sourceTemplateId: UUID? = nil   // 选模板再改时记录来源；空白为 nil
    var name: String = ""             // 仅用于「保存为我的模板」时命名
    var goal: TrainingGoal = .endurance
    var difficulty: DifficultyLevel = .beginner
    var dayDrafts: [DayDraft] = []      // 各训练日及其方法（取代原 selectedMethodIds + trainingDayOffsets）

    /// 全部已选方法（去重、保序），供「我的模板」/展示使用
    var allMethodIds: [UUID] {
        var seen: [UUID] = []
        for d in dayDrafts where !d.methodIds.isEmpty {
            for m in d.methodIds where !seen.contains(m) { seen.append(m) }
        }
        return seen
    }
    /// 全部训练日偏移（排序）
    var trainingDayOffsets: [Int] {
        dayDrafts.map { $0.dayOffset }.sorted()
    }
}

// MARK: - 计划编辑草稿（需求 11 / AC-11.5）

/// 计划编辑态内存草稿（需求 11 / AC-11.1~11.5）
/// 进入编辑即深拷贝当前 `TrainingPlan`，全程不写库；取消直接丢弃（AC-11.5）。
struct PlanEditDraft {
    let planId: UUID
    let startDate: Date
    let endDate: Date
    var items: [PlanItem]                 // 可变副本，编辑仅改 methodId/methodName/duration/date
}

// MARK: - 我的模板（用户数据，持久化）

/// 模板中的单日定义（需求 10 / Q3 支持一日多方法）
struct UserPlanTemplateDay: Codable, Identifiable, Hashable {
    let id: UUID = UUID()
    var dayOffset: Int        // 0...6
    var methodIds: [UUID]      // 该日方法（≥1）
}

/// 「我的模板」领域模型（需求 10 / AC-10.5）
/// 属用户数据，由 Core Data 持久化并排除 iCloud 备份（呼应 AC-7.5/AC-NF.7）
/// - Q3：以 `days` 记录每日方法，支持同一天多种方法；`methodIds`/`trainingDayOffsets` 为便捷计算属性，
///   仍满足需求 10「字段至少含 methodIds / trainingDayOffsets」的要求。
struct UserPlanTemplate: Identifiable, Codable {
    let id: UUID
    var name: String
    let difficulty: DifficultyLevel
    let frequency: Int              // 每周训练天数（= days.count，冗余保存便于展示/检索）
    let goal: TrainingGoal
    let icon: String
    let days: [UserPlanTemplateDay]  // 每日方法（支持 Q3 一日多方法）
    var description: String?        // 可选，提升模板库可读性（Q5）
    let createdAt: Date
    var updatedAt: Date

    /// 全部方法 id（去重），兼容既有字段命名
    var methodIds: [UUID] {
        var seen: [UUID] = []
        for d in days where !d.methodIds.isEmpty {
            for m in d.methodIds where !seen.contains(m) { seen.append(m) }
        }
        return seen
    }
    /// 全部训练日偏移（排序），兼容既有字段命名
    var trainingDayOffsets: [Int] {
        days.map { $0.dayOffset }.sorted()
    }

    init(id: UUID = UUID(),
         name: String,
         difficulty: DifficultyLevel,
         frequency: Int,
         goal: TrainingGoal,
         icon: String,
         days: [UserPlanTemplateDay],
         description: String? = nil,
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.difficulty = difficulty
        self.frequency = frequency
        self.goal = goal
        self.icon = icon
        self.days = days
        self.description = description
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Assessment Model

/// 初始评估问卷数据模型
struct Assessment: Codable {
    var age: Int
    var currentAbilityScore: Int // 1-10
    var trainingExperience: TrainingExperience
    var physicalCondition: PhysicalCondition
    var trainingGoal: TrainingGoal
    
    init(age: Int = 40,
         currentAbilityScore: Int = 5,
         trainingExperience: TrainingExperience = .none,
         physicalCondition: PhysicalCondition = .normal,
         trainingGoal: TrainingGoal = .endurance) {
        self.age = age
        self.currentAbilityScore = currentAbilityScore
        self.trainingExperience = trainingExperience
        self.physicalCondition = physicalCondition
        self.trainingGoal = trainingGoal
    }
}

/// 训练经验
enum TrainingExperience: String, Codable, CaseIterable {
    case none = "无经验"
    case beginner = "少量经验"
    case intermediate = "有一定经验"
    case advanced = "丰富经验"
}

/// 身体状况
enum PhysicalCondition: String, Codable, CaseIterable {
    case excellent = "优秀"
    case good = "良好"
    case normal = "一般"
    case poor = "较差"
}

/// 训练目标
enum TrainingGoal: String, Codable, CaseIterable {
    case endurance = "提升持久力"
    case control = "增强控制力"
    case recovery = "加快恢复"
    case comprehensive = "全面提升"

    var icon: String {
        switch self {
        case .endurance: return "figure.run"
        case .control: return "hand.point.up.fill"
        case .recovery: return "arrow.triangle.2.circlepath"
        case .comprehensive: return "star.fill"
        }
    }

    var description: String {
        switch self {
        case .endurance: return "延长可控时间，增强耐力"
        case .control: return "提升关键时刻的自控能力"
        case .recovery: return "加速身体机能恢复"
        case .comprehensive: return "综合提升各方面能力"
        }
    }
}

// MARK: - Review Note Model

/// 复盘笔记数据模型
struct ReviewNote: Identifiable {
    let id: UUID
    let trainingRecordId: UUID
    let date: Date
    var feelingScore: Int // 1-5
    var difficultyScore: Int // 1-5
    var bodyReaction: String
    var notes: String
    
    init(id: UUID = UUID(),
         trainingRecordId: UUID,
         date: Date = Date(),
         feelingScore: Int = 3,
         difficultyScore: Int = 3,
         bodyReaction: String = "",
         notes: String = "") {
        self.id = id
        self.trainingRecordId = trainingRecordId
        self.date = date
        self.feelingScore = feelingScore
        self.difficultyScore = difficultyScore
        self.bodyReaction = bodyReaction
        self.notes = notes
    }
}