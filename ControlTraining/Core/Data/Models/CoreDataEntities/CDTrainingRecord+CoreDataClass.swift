import Foundation
import CoreData

/// Core Data 训练记录实体
/// 属性声明由 Xcode 自动生成（CDTrainingRecord+CoreDataProperties.swift）
@objc(CDTrainingRecord)
public class CDTrainingRecord: NSManagedObject {
}

extension CDTrainingRecord {
    /// 便利初始化方法（AC-2.10: 含 isPartial 部分记录标记）
    /// AC-13.7 / AC-13.9: 含 modeId/modeName 方法专属模式持久化
    convenience init(context: NSManagedObjectContext, from record: TrainingRecord) {
        self.init(context: context)
        self.id = record.id
        self.methodId = record.methodId
        self.date = record.date
        self.duration = record.duration
        self.completionRate = record.completionRate
        self.selfRating = Int16(record.selfRating)
        self.notes = record.notes
        self.mode = record.mode.rawValue
        self.modeId = record.modeId
        self.modeName = record.modeName
        self.isPartial = record.isPartial
    }
    
    /// 转换为领域模型
    func toDomainModel() -> TrainingRecord {
        return TrainingRecord(
            id: id!,
            methodId: methodId!,
            date: date!,
            duration: duration,
            completionRate: completionRate,
            selfRating: Int(selfRating),
            notes: notes ?? "",
            mode: TrainingMode(rawValue: mode!) ?? .basic,
            modeId: modeId,
            modeName: modeName,
            isPartial: isPartial
        )
    }
}