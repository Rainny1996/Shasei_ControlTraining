import XCTest

/// UI 冒烟测试（XCUI）
///
/// 目的：现有 159 个用例全为逻辑单测，无任何 UI 测试。本文件补齐最小可用 UI 测试，
/// 验证 App 在模拟器中可正常启动、进入引导流程，并能在跳过引导后到达初始设置页（AC-9.4 首启引导）。
/// 注意：UI 测试运行于独立进程，禁止 @testable import，只通过 XCUIApplication 访问可访问性元素。
final class ControlTrainingUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    /// 冒烟测试：App 成功启动并渲染引导首页
    /// AC-9.4 首启引导可达性
    func testAppLaunchesAndShowsOnboarding() {
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10),
                      "App 应成功启动并进入前台")
        let welcome = app.staticTexts["欢迎来到控制训练"]
        XCTAssertTrue(welcome.exists, "首启应展示引导首页标题")
    }

    /// 冒烟测试：跳过引导后进入初始设置问卷
    /// AC-9.4 / AC-3.1 初始评估问卷入口可达
    func testSkipOnboardingReachesInitialSetup() {
        let skip = app.buttons["跳过"]
        guard skip.exists else {
            XCTFail("未找到「跳过」按钮，引导流程可能已变更")
            return
        }
        skip.tap()

        let initialSetup = app.staticTexts["初始设置"]
        XCTAssertTrue(initialSetup.waitForExistence(timeout: 10),
                      "跳过引导后应进入初始设置页")
    }

    // MARK: - 需求 10 / 11 / 12 入口与控件可达性（XCUI 冒烟）

    /// 辅助：尽力从首屏到达「训练计划」页（容忍首启引导）
    private func navigateToPlanTab() {
        let skip = app.buttons["跳过"]
        if skip.waitForExistence(timeout: 3) { skip.tap() }

        let planTab = app.tabBars.buttons["训练计划"]
        if planTab.waitForExistence(timeout: 5) {
            planTab.tap()
        }
    }

    /// AC-10.1：自定义计划入口可达（无计划页也提供「自定义计划」按钮，≤2 次点击）
    func testCustomPlanEntryReachable() {
        navigateToPlanTab()
        let custom = app.buttons["自定义计划"]
        XCTAssertTrue(custom.waitForExistence(timeout: 5),
                      "计划页应提供「自定义计划」入口（AC-10.1）")
        custom.tap()
        XCTAssertTrue(app.staticTexts["组建方式"].waitForExistence(timeout: 5),
                      "进入自定义计划编辑器应展示「组建方式」（AC-10.1/10.2）")
    }

    /// AC-10.4：自定义阶段不暴露时长/强度/周期调整入口
    func testBuilderNoDurationIntensityPeriodControls() {
        navigateToPlanTab()
        app.buttons["自定义计划"].tap()
        XCTAssertTrue(app.staticTexts["组建方式"].waitForExistence(timeout: 5))

        // 不应出现「训练强度」维度
        XCTAssertFalse(app.staticTexts["训练强度"].exists,
                       "Builder 不应暴露「训练强度」入口（AC-10.4）")
        // 不应出现「周期」维度（具体训练日期已提供，周期长度不在本阶段调整）
        let periodRelated = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '周期'"))
        XCTAssertEqual(periodRelated.count, 0, "Builder 不应暴露「周期」入口（AC-10.4）")

        // 仅有的维度应为：训练目标 / 难度 / 每周训练天数 / 具体训练日期 / 每日训练方法
        XCTAssertTrue(app.staticTexts["训练目标"].exists)
        XCTAssertTrue(app.staticTexts["每周训练天数"].exists)
        XCTAssertTrue(app.staticTexts["具体训练日期"].exists)
    }

    /// AC-10.7 / 11.7 / 12.6：关键入口带 VoiceOver 标签且可点击
    func testKeyEntriesHaveAccessibilityLabels() {
        navigateToPlanTab()
        let custom = app.buttons["自定义计划"]
        XCTAssertTrue(custom.waitForExistence(timeout: 5),
                      "「自定义计划」入口应存在并带 VoiceOver 标签（AC-10.7）")
        XCTAssertTrue(custom.isHittable, "「自定义计划」入口可点击（≥44pt 命中区，AC-10.7）")

        // 编辑计划入口（存在活跃计划时）：菜单项含「编辑计划」标签
        let edit = app.buttons["编辑计划"]
        if edit.exists {
            XCTAssertTrue(edit.isHittable, "编辑计划入口可点击（AC-11.1/11.7）")
        }

        // 今日动作行「查看详情并开始陪练」标签（AC-12.6）
        let todayRow = app.buttons["查看"]
        if todayRow.exists {
            XCTAssertTrue(todayRow.isHittable, "今日动作行可点击进入详情（AC-12.6）")
        }
    }
}
