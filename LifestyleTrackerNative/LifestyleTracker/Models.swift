import Foundation
import SwiftUI

struct DayRecord: Codable, Identifiable {
    var day: String
    var sleep: String = ""
    var wake: String = ""
    var energy: Int = 4
    var pain: Int = 0
    var exercise: Int = 0
    var breakfast: Bool = false
    var lunch: Bool = false
    var dinner: Bool = false
    var water: Bool = false
    var notes: String = ""
    var id: String { day }
}

struct Habit: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var title: String
    var detail: String = ""
    var category: HabitCategory
}

enum HabitCategory: String, Codable, CaseIterable, Identifiable {
    case daily = "每日", weekly = "每週", monthly = "每月"
    var id: String { rawValue }
}

struct SavedData: Codable {
    var records: [String: DayRecord] = [:]
    var habits: [Habit] = Habit.defaults
    var habitCompletions: [String: Set<UUID>] = [:]
    var commuteMinutes: Int = 60
    var workStartHour: Int = 10
    var workEndHour: Int = 18
    var targetExerciseMinutes: Int = 120
    var showerInMorning: Bool = false
}

extension Habit {
    static let defaults: [Habit] = [
        Habit(title: "起床後離床、接觸明亮光線", detail: "不強迫自己六點起床", category: .daily),
        Habit(title: "早餐或簡單晨間補充", detail: "豆漿、蛋、吐司即可", category: .daily),
        Habit(title: "正常吃午餐", detail: "維持飯、菜、蛋白質", category: .daily),
        Habit(title: "準備或吃到晚餐", detail: "晚間家教日前預先安排", category: .daily),
        Habit(title: "留意飲水與身體狀況", category: .daily),
        Habit(title: "睡前整理隔天必需品", category: .daily),
        Habit(title: "保留真正的恢復時間", category: .daily),
        Habit(title: "累積有氧運動，目標每週 120 分鐘", detail: "從能負荷的強度逐漸增加", category: .weekly),
        Habit(title: "保留一個不加工作的晚上", category: .weekly),
        Habit(title: "採買／準備 2–3 天食材", category: .weekly),
        Habit(title: "洗衣與整理居家環境", category: .weekly),
        Habit(title: "R、論文、英文或練鼓擇一", category: .weekly),
        Habit(title: "檢視收入、支出與預算", category: .monthly),
        Habit(title: "整理冰箱與檢查食品保存", category: .monthly),
        Habit(title: "回顧疲倦、經期及疼痛紀錄", category: .monthly),
        Habit(title: "設定下月生活目標", category: .monthly)
    ]
}

extension Date {
    var dayKey: String { DateFormatter.key.string(from: self) }
    var monthLabel: String {
        let f = DateFormatter(); f.locale = Locale(identifier: "zh_TW"); f.dateFormat = "yyyy 年 M 月"
        return f.string(from: self)
    }
    var dayLabel: String {
        let f = DateFormatter(); f.locale = Locale(identifier: "zh_TW"); f.dateFormat = "M 月 d 日 EEEE"
        return f.string(from: self)
    }
    var startDay: Date { Calendar.current.startOfDay(for: self) }
    func addingDays(_ days: Int) -> Date { Calendar.current.date(byAdding: .day, value: days, to: self) ?? self }
}

extension DateFormatter {
    static let key: DateFormatter = {
        let f=DateFormatter(); f.locale=Locale(identifier:"en_US_POSIX"); f.dateFormat="yyyy-MM-dd"; return f
    }()
    static let hm: DateFormatter = {
        let f=DateFormatter(); f.locale=Locale(identifier:"zh_TW"); f.timeStyle = .short; f.dateStyle = .none; return f
    }()
}
