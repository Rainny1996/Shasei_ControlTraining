import Foundation
import CoreData

/// Core Data 用户计划模板实体（「我的模板」）
/// 属性声明由 Xcode 自动生成（CDUserPlanTemplate+CoreDataProperties.swift，codeGenerationType=category）
@objc(CDUserPlanTemplate)
public class CDUserPlanTemplate: NSManagedObject {
}

extension CDUserPlanTemplate {
    /// 便利初始化方法（Q3：以 daysData 持久化每日方法）
    convenience init(context: NSManagedObjectContext, from template: UserPlanTemplate) {
        self.init(context: context)
        self.id = template.id
        self.name = template.name
        self.difficulty = template.difficulty.rawValue
        self.frequency = Int16(template.frequency)
        self.goal = template.goal.rawValue
        self.icon = template.icon
        // 每日方法以 JSON(Binary) 存储，支持 Q3 一日多方法
        self.daysData = try? JSONEncoder().encode(template.days)
        self.desc = template.description
        self.createdAt = template.createdAt
        self.updatedAt = template.updatedAt
    }

    /// 转换为领域模型
    func toDomainModel() -> UserPlanTemplate {
        let days = (try? JSONDecoder().decode([UserPlanTemplateDay].self,
                                              from: self.daysData ?? Data())) ?? []
        return UserPlanTemplate(
            id: id!,
            name: name ?? "",
            difficulty: DifficultyLevel(rawValue: difficulty ?? "") ?? .beginner,
            frequency: Int(frequency),
            goal: TrainingGoal(rawValue: goal ?? "") ?? .endurance,
            icon: icon ?? "star.fill",
            days: days,
            description: desc,
            createdAt: createdAt ?? Date(),
            updatedAt: updatedAt ?? Date()
        )
    }
}
