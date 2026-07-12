import Foundation
import Combine

/// 训练记录视图模型：列表与图表数据聚合
final class RecordsViewModel: ObservableObject {
    @Published var sessions: [TrainingSession] = []
    @Published var chartData: [(index: Int, avgControl: Double)] = []

    init() { reload() }

    func reload() {
        sessions = CoreDataStack.shared.allSessions()
        chartData = sessions.enumerated().compactMap { idx, s in
            let arr = s.controlDurationsArray
            guard !arr.isEmpty else { return nil }
            let avg = Double(arr.reduce(0, +)) / Double(arr.count)
            return (index: idx, avgControl: avg)
        }.reversed()
    }

    /// 导出加密 JSON 分享
    func exportJSON() -> URL? {
        let dicts = sessions.map { $0.toExportDictionary() }
        guard let data = try? JSONSerialization.data(withJSONObject: dicts, options: .prettyPrinted) else { return nil }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("yilian_export.json")
        try? data.write(to: url)
        return url
    }
}
