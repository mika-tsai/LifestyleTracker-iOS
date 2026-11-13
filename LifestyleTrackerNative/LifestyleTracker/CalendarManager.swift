import Foundation
import EventKit
import SwiftUI

struct CalendarEvent: Identifiable {
    let id: String
    let title: String
    let start: Date
    let end: Date
    let isAllDay: Bool
    let calendarTitle: String
    let calendarID: String
    let location: String
}

@MainActor
final class CalendarManager: ObservableObject {
    @Published private(set) var calendars: [EKCalendar] = []
    @Published private(set) var events: [CalendarEvent] = []
    @Published var selectedIDs: Set<String> = [] { didSet { saveSelection() } }
    @Published var hasPermission: Bool = false
    @Published var message: String = "先允許行事曆存取，再選擇要納入的日曆。"
    private let eventStore=EKEventStore()
    private let prefKey="lifestyle.selectedCalendarIdentifiers"
    private let configuredKey="lifestyle.calendarsConfigured"

    init() { selectedIDs=Set(UserDefaults.standard.stringArray(forKey:prefKey) ?? []) }
    private func saveSelection() {
        UserDefaults.standard.set(Array(selectedIDs),forKey:prefKey)
        if hasPermission { UserDefaults.standard.set(true,forKey:configuredKey) }
    }
    func refreshAccessStatus() {
        hasPermission = EKEventStore.authorizationStatus(for: .event) == .fullAccess
        if hasPermission { loadCalendars();loadEvents(center: Date()) }
    }
    func requestAccess() async {
        do {
            let allowed=try await eventStore.requestFullAccessToEvents()
            hasPermission=allowed
            if allowed { loadCalendars();loadEvents(center:Date()) }
            else { message="尚未取得行事曆權限。可到 iPhone 設定修改。" }
        }catch{message="無法取得權限：\(error.localizedDescription)"}
    }
    private func loadCalendars() {
        calendars=eventStore.calendars(for:.event).sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
        let existing=Set(calendars.map(\.calendarIdentifier))
        selectedIDs.formIntersection(existing)
        message=calendars.isEmpty ? "iPhone 行事曆沒有可讀的日曆；請確認 Google 帳號已同步到 Apple 行事曆。" : "可選擇多個行事曆。未勾選的日曆不列入安排。"
    }
    func loadEvents(center: Date) {
        guard hasPermission else { events=[]; return }
        let chosen=calendars.filter { selectedIDs.contains($0.calendarIdentifier) }
        guard !chosen.isEmpty else { events=[]; return }
        let calendar=Calendar.current
        let start=calendar.date(byAdding:.month,value:-1,to:calendar.date(from:calendar.dateComponents([.year,.month],from:center))!) ?? center.addingDays(-35)
        let end=calendar.date(byAdding:.month,value:3,to:start) ?? center.addingDays(65)
        let predicate=eventStore.predicateForEvents(withStart:start,end:end,calendars:chosen)
        events=eventStore.events(matching:predicate).map { e in
            CalendarEvent(id:e.eventIdentifier ?? UUID().uuidString,title:e.title ?? "未命名活動",start:e.startDate,end:e.endDate,isAllDay:e.isAllDay,calendarTitle:e.calendar.title,calendarID:e.calendar.calendarIdentifier,location:e.location ?? "")
        }.sorted { $0.start < $1.start }
    }
    func events(on day: Date) -> [CalendarEvent] {
        let a=day.startDay,b=a.addingDays(1)
        return events.filter { $0.start < b && $0.end > a }
    }
    func toggleCalendar(_ id: String, center: Date) {
        if selectedIDs.contains(id) {selectedIDs.remove(id)} else {selectedIDs.insert(id)}
        loadEvents(center:center)
    }
}
