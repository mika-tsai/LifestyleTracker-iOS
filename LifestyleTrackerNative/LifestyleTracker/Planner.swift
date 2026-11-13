import Foundation

struct PlannedItem: Identifiable {
    enum Kind { case fixed, commute, care, caution }
    let id = UUID()
    let time: String
    let title: String
    let note: String
    let kind: Kind
}

struct DayPlan {
    var items: [PlannedItem]
    var load: String
    var summary: String
    var warnings: [String]
}

enum Planner {
    private static func clock(_ date: Date) -> String { DateFormatter.hm.string(from: date) }
    private static func time(_ hour: Int, _ minute: Int = 0, on day: Date) -> Date {
        let calendar=Calendar.current
        return calendar.date(bySettingHour:hour,minute:minute,second:0,of:day) ?? day
    }
    private static func item(_ start: Date, _ end: Date, _ title: String, _ note: String, _ kind: PlannedItem.Kind) -> PlannedItem {
        PlannedItem(time:"\(clock(start))–\(clock(end))", title:title, note:note, kind:kind)
    }
    static func make(day: Date, events: [CalendarEvent], record: DayRecord, settings: SavedData) -> DayPlan {
        let calendar=Calendar.current
        let weekday=calendar.component(.weekday,from:day)
        let workday=(weekday >= 2 && weekday <= 6)
        let timed=events.filter { !$0.isAllDay }.sorted { $0.start < $1.start }
        let minutes=timed.reduce(0) { $0 + Int(max(0,$1.end.timeIntervalSince($1.start)/60)) }
        let late=timed.contains { calendar.component(.hour,from:$0.end) >= 21 }
        let painful=record.pain >= 5
        let fatigued=record.energy <= 4
        let load = painful || (fatigued && (late || minutes >= 240)) ? "需要恢復" : late || minutes >= 360 ? "高負荷" : minutes >= 180 ? "中負荷" : "低負荷"
        var warnings:[String]=[]
        var items:[PlannedItem]=[]

        // Morning routine: suggested, not a fixed medical or sleep prescription.
        if workday {
            let wake=settings.showerInMorning ? time(7,30,on:day) : time(8,0,on:day)
            items.append(item(wake,wake.addingTimeInterval(10*60),"起床、光線與離床","若前晚睡不夠，優先檢查睡眠安排",.care))
            if settings.showerInMorning {
                items.append(item(time(7,40,on:day),time(8,20,on:day),"晨間洗澡、洗頭、吹髮","保留幫助清醒的流程",.care))
                items.append(item(time(8,20,on:day),time(8,40,on:day),"保養、早餐、出門準備","衣服與包包前一晚備好",.care))
            } else {
                items.append(item(time(8,10,on:day),time(8,35,on:day),"洗漱、早餐與整理","早上採精簡流程，不急著補做家事",.care))
            }
            let start=time(settings.workStartHour,0,on:day)
            let depart=start.addingTimeInterval(TimeInterval(-settings.commuteMinutes*60-15*60))
            items.append(item(depart,start.addingTimeInterval(-15*60),"預留上班通勤","依目前設定：\(settings.commuteMinutes) 分鐘，另保留 15 分鐘緩衝",.commute))
        } else {
            items.append(item(time(8,30,on:day),time(9,0,on:day),"彈性起床與早餐","休假也盡量不要和平日相差太久；若睡眠不足先補足",.care))
        }
        for e in events.sorted(by: { $0.start < $1.start }) {
            if e.isAllDay {
                items.append(PlannedItem(time:"全天",title:e.title,note:e.calendarTitle,kind:.fixed))
            } else {
                let description=e.calendarTitle + (e.location.isEmpty ? "" : " · " + e.location)
                items.append(item(e.start,e.end,e.title,description,.fixed))
            }
        }
        let commute=TimeInterval(settings.commuteMinutes*60)
        if timed.count >= 2 {
            for (a,b) in zip(timed,timed.dropFirst()) {
                if b.start < a.end {warnings.append("「\(a.title)」與「\(b.title)」時間重疊。")}
                else if !a.location.isEmpty && !b.location.isEmpty && a.location != b.location && b.start.timeIntervalSince(a.end) < commute {
                    warnings.append("「\(a.title)」到「\(b.title)」只隔 \(Int(b.start.timeIntervalSince(a.end)/60)) 分鐘，不足設定的 \(settings.commuteMinutes) 分鐘通勤。")
                }
            }
        }
        if weekday == 2 || weekday == 3 { // Monday, Tuesday
            let start=time(settings.workStartHour,0,on:day),end=time(settings.workEndHour,0,on:day)
            if timed.contains(where: { $0.start < end && $0.end > start && ($0.title.localizedCaseInsensitiveContains("家教") || $0.title.localizedCaseInsensitiveContains("tutor")) }) {
                warnings.append("當天家教可能與預設工作 10:00–18:00 衝突；請確認提早下班或實際工作安排。")
            }
        }
        if late {
            items.append(item(time(22,0,on:day),time(22,45,on:day),"晚間簡化恢復流程","家教或活動後優先洗澡、基本整理，不再增加學習任務",.care))
        } else if !painful && !fatigued && minutes < 240 {
            items.append(PlannedItem(time:"可調整空檔",title:"運動／學習擇一",note:"可選跳舞、球類、R 或閱讀；記得另外預留交通",kind:.care))
        } else {
            items.append(PlannedItem(time:"可調整空檔",title:"保留真正的休息",note:"身體疲倦時不必塞滿所有空檔",kind:.care))
        }
        if workday && timed.isEmpty {
            warnings.append("今天沒有讀取到固定行程；上班時間目前僅使用設定中的 10:00–18:00 假設，不代表實際班表。")
        }
        let sleepReminder=late ? "盡量簡化睡前流程並保留睡眠；不要為了作息表硬減少睡眠。" : "今晚優先安排足夠的睡眠機會，逐漸建立穩定的起床時間。"
        let summary=(fatigued ? "今天精神偏低，" : "")+(painful ? "疼痛程度較高，" : "")+(late ? "晚間有較晚結束的活動。" : "請依固定行程安排用餐與恢復。") + sleepReminder
        return DayPlan(items:items,load:load,summary:summary,warnings:Array(Set(warnings)).sorted())
    }
}
