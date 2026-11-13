import Foundation
import SwiftUI

@MainActor
final class LifestyleModel: ObservableObject {
    @Published var data = SavedData() {
        didSet { persist() }
    }
    @Published var selectedDay = Date().startDay
    @Published var selectedTab: Int = 0
    @Published var errorMessage: String? = nil

    private let fileName = "lifestyle-data.json"
    init() { load() }

    private var fileURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base.appendingPathComponent(fileName)
    }
    private func load() {
        guard let bytes = try? Data(contentsOf: fileURL),
              let saved = try? JSONDecoder().decode(SavedData.self, from: bytes) else { return }
        data = saved
    }
    private func persist() {
        do { try JSONEncoder().encode(data).write(to: fileURL, options: .atomic) }
        catch { errorMessage = "儲存失敗：\(error.localizedDescription)" }
    }
    func record(for day: Date) -> DayRecord { data.records[day.dayKey] ?? DayRecord(day: day.dayKey) }
    func setRecord(_ record: DayRecord) { data.records[record.day] = record }
    func habitPeriod(_ category: HabitCategory, for day: Date) -> String {
        let calendar = Calendar.current
        switch category {
        case .daily: return day.dayKey
        case .weekly:
            let components=calendar.dateComponents([.yearForWeekOfYear,.weekOfYear], from: day)
            return "\(components.yearForWeekOfYear ?? 0)-W\(components.weekOfYear ?? 0)"
        case .monthly: return String(day.dayKey.prefix(7))
        }
    }
    func completionKey(_ category: HabitCategory, day: Date) -> String { category.rawValue + "|" + habitPeriod(category, for: day) }
    func isDone(_ habit: Habit, on day: Date) -> Bool { data.habitCompletions[completionKey(habit.category, day: day)]?.contains(habit.id) == true }
    func toggle(_ habit: Habit, on day: Date) {
        let k=completionKey(habit.category, day: day)
        var values=data.habitCompletions[k] ?? []
        if values.contains(habit.id) { values.remove(habit.id) } else { values.insert(habit.id) }
        data.habitCompletions[k]=values
    }
    func addHabit(_ title: String, category: HabitCategory) {
        let clean=title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else {return}
        data.habits.append(Habit(title: clean, category: category))
    }
    func removeHabit(_ habit: Habit) { data.habits.removeAll { $0.id == habit.id } }
    func exportURL() -> URL? {
        do {
            let url=FileManager.default.temporaryDirectory.appendingPathComponent("LifestyleTracker-backup-\(Date().dayKey).json")
            let bytes=try JSONEncoder().encode(data)
            try bytes.write(to:url,options:.atomic)
            return url
        } catch { errorMessage="匯出失敗：\(error.localizedDescription)"; return nil }
    }
    func importFile(_ url: URL) {
        let scoped=url.startAccessingSecurityScopedResource(); defer{if scoped{url.stopAccessingSecurityScopedResource()}}
        do {
            let incoming=try JSONDecoder().decode(SavedData.self,from:Data(contentsOf:url))
            data=incoming
        }catch{errorMessage="匯入失敗，請使用本 App 匯出的 JSON：\(error.localizedDescription)"}
    }
}
