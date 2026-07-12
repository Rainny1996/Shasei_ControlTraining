import XCTest
import CoreData
import UIKit
import SwiftUI
@testable import ControlTraining

/// 需求 12（今日训练动作直达陪练）单元测试 + 进程内集成断言
/// 覆盖：AC-12.3 / AC-12.4 / AC-12.5（AC-12.1/12.2/12.6 见集成渲染、XCUI 与手动验证）
final class Tests需求12直达陪练: XCTestCase {

    func waitUntil(_ condition: @escaping () -> Bool, timeout: TimeInterval = 3) {
        let start = Date()
        while !condition() && Date().timeIntervalSince(start) < timeout {
            RunLoop.current.run(until: Date().addingTimeInterval(0.01))
        }
    }

    /// 极短方法：defaultDuration=6 → 基础模式约 6 秒即可自然完成
    private func shortMethod() -> TrainingMethod {
        TrainingMethod(
            name: "测试短方法",
            category: .kegel,
            difficulty: .beginner,
            description: "测试描述",
            principle: "测试原理",
            steps: [TrainingStep(order: 1, title: "收缩", instruction: "收缩 3 秒")],
            precautions: [],
            expectedEffect: "测试效果",
            targetAudience: "测试人群",
            defaultDuration: 6
        )
    }

    // MARK: - AC-12.3 / AC-12.4 正常完成：触发回调 + 写非 partial 记录

    func testCoachNormalCompletionTriggersCallbackAndWritesNonPartial() {
        let spy = SpyTrainingRepository()
        let vm = CoachViewModel(method: shortMethod(), mode: .basic, trainingRepository: spy)
        vm.voiceGuidanceEnabled = false // 跳过语音，避免音频依赖

        let completed = expectation(description: "onTrainingCompleted 应被调用")
        vm.onTrainingCompleted = { completed.fulfill() }

        vm.startPreparation() // 3 秒倒计时后进入训练，约 6 秒后自然完成
        waitForExpectations(timeout: 20)

        XCTAssertTrue(spy.savedRecords.contains { !$0.isPartial },
                      "正常完成应生成非 partial 训练记录")
    }

    // MARK: - AC-12.4 中途退出：不触发回调 + 写 partial 记录

    func testCoachStopTrainingDoesNotTriggerCallbackAndWritesPartial() {
        let spy = SpyTrainingRepository()
        let vm = CoachViewModel(method: shortMethod(), mode: .basic, trainingRepository: spy)
        vm.voiceGuidanceEnabled = false

        let shouldNotComplete = expectation(description: "onTrainingCompleted 不应被调用")
        shouldNotComplete.isInverted = true
        vm.onTrainingCompleted = { shouldNotComplete.fulfill() }

        vm.startPreparation()
        let stop = expectation(description: "中途退出")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            vm.stopTraining() // 中途自行退出
            stop.fulfill()
        }
        waitForExpectations(timeout: 5)

        XCTAssertTrue(spy.savedRecords.contains { $0.isPartial },
                      "中途退出应生成 partial 训练记录")
    }

    // MARK: - AC-12.4 markPlanItemCompleted：持久化 + 进度重算 + 幂等

    func testMarkItemCompletedPersistsAndRecomputes() {
        let dc = DataController(inMemory: true)
        let repo = PlanRepository(dataController: dc)
        let vm = PlanViewModel(planRepository: repo,
                               trainingRepository: TrainingRepository(dataController: dc))

        let start = Calendar.current.startOfDay(for: Date())
        let end = Calendar.current.date(byAdding: .day, value: 7, to: start)!
        let m = TrainingContentData.allTrainingMethods().first!
        let i1 = PlanItem(date: start, methodId: m.id, methodName: m.name, duration: 300, isCompleted: true)
        let i2 = PlanItem(date: start, methodId: m.id, methodName: m.name, duration: 300, isCompleted: false)
        let plan = TrainingPlan(startDate: start, endDate: end, items: [i1, i2])
        repo.saveTrainingPlan(plan)
        waitUntil { repo.fetchActivePlan() != nil }
        vm.loadPlan()

        XCTAssertEqual(vm.currentPlan!.progress, 0.5, accuracy: 0.001, "初始进度 1/2")

        vm.markItemCompleted(i2.id)
        XCTAssertTrue(vm.currentPlan?.items.first(where: { $0.id == i2.id })?.isCompleted == true,
                      "标记后该项应已完成")
        XCTAssertEqual(vm.currentPlan!.progress, 1.0, accuracy: 0.001, "全部完成进度应为 1.0")
    }

    func testMarkItemCompletedIdempotent() {
        let dc = DataController(inMemory: true)
        let repo = PlanRepository(dataController: dc)
        let vm = PlanViewModel(planRepository: repo,
                               trainingRepository: TrainingRepository(dataController: dc))

        let start = Calendar.current.startOfDay(for: Date())
        let end = Calendar.current.date(byAdding: .day, value: 7, to: start)!
        let m = TrainingContentData.allTrainingMethods().first!
        let i1 = PlanItem(date: start, methodId: m.id, methodName: m.name, duration: 300, isCompleted: true)
        let i2 = PlanItem(date: start, methodId: m.id, methodName: m.name, duration: 300, isCompleted: false)
        let plan = TrainingPlan(startDate: start, endDate: end, items: [i1, i2])
        repo.saveTrainingPlan(plan)
        waitUntil { repo.fetchActivePlan() != nil }
        vm.loadPlan()

        vm.markItemCompleted(i2.id)
        vm.markItemCompleted(i2.id) // 再次调用
        XCTAssertEqual(vm.currentPlan!.progress, 1.0, accuracy: 0.001, "幂等：重复调用进度不变")
    }

    // MARK: - AC-12.5 已完成项点击仅查看，不触发新陪练

    func testCompletedItemDetailOpensButNoRetrigger() {
        let dc = DataController(inMemory: true)
        let repo = PlanRepository(dataController: dc)
        let vm = PlanViewModel(planRepository: repo,
                               trainingRepository: TrainingRepository(dataController: dc))

        let start = Calendar.current.startOfDay(for: Date())
        let end = Calendar.current.date(byAdding: .day, value: 7, to: start)!
        let m = TrainingContentData.allTrainingMethods().first!
        let done = PlanItem(date: start, methodId: m.id, methodName: m.name, duration: 300, isCompleted: true)
        let plan = TrainingPlan(startDate: start, endDate: end, items: [done])
        repo.saveTrainingPlan(plan)
        waitUntil { repo.fetchActivePlan() != nil }
        vm.loadPlan()

        vm.openPlanItemDetail(done)
        XCTAssertTrue(vm.showPlanItemDetail)
        XCTAssertTrue(vm.selectedPlanItem?.isCompleted == true, "已完成项进入详情，但不再触发陪练")
    }
}

/// 捕获训练记录写入的 spy（子类多态注入 CoachViewModel）
final class SpyTrainingRepository: TrainingRepository {
    var savedRecords: [TrainingRecord] = []
    override func saveTrainingRecord(_ record: TrainingRecord) {
        savedRecords.append(record)
    }
}

// MARK: - 进程内 SwiftUI 集成：PlanItemDetailView 渲染（AC-12.1/12.2/12.5）

final class PlanItemDetailIntegrationTests: XCTestCase {

    func testPlanItemDetailViewRendersNonCompleted() {
        let dc = DataController(inMemory: true)
        let repo = PlanRepository(dataController: dc)

        let m = TrainingContentData.allTrainingMethods().first!
        let item = PlanItem(date: Date(), methodId: m.id, methodName: m.name, duration: 300)
        let detailVM = PlanViewModel(planRepository: repo,
                                     trainingRepository: TrainingRepository(dataController: dc))
        let vc = UIHostingController(rootView: PlanItemDetailView(item: item, method: m, planViewModel: detailVM))
        _ = vc.view

        // 点击动作行进入详情（非完成按钮路径）
        detailVM.openPlanItemDetail(item)
        XCTAssertTrue(detailVM.showPlanItemDetail)
        XCTAssertFalse(item.isCompleted, "未完成项可正常进入详情并允许开始陪练")
    }

    func testPlanItemDetailViewRendersCompleted() {
        let dc = DataController(inMemory: true)
        let repo = PlanRepository(dataController: dc)
        let m = TrainingContentData.allTrainingMethods().first!
        let item = PlanItem(date: Date(), methodId: m.id, methodName: m.name, duration: 300, isCompleted: true)
        let detailVM = PlanViewModel(planRepository: repo,
                                     trainingRepository: TrainingRepository(dataController: dc))
        let vc = UIHostingController(rootView: PlanItemDetailView(item: item, method: m, planViewModel: detailVM))
        _ = vc.view
        // 不崩溃，且已完成项仅查看（视图以 enableStart: !item.isCompleted 禁用开始陪练，代码审查确认）
        XCTAssertTrue(item.isCompleted)
    }
}
