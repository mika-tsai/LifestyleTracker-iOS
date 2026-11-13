import SwiftUI

@main
struct LifestyleTrackerApp: App {
    @StateObject private var model = LifestyleModel()
    @StateObject private var calendar = CalendarManager()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(model)
                .environmentObject(calendar)
                .tint(Color(red: 0.24, green: 0.47, blue: 0.38))
                .task { calendar.refreshAccessStatus() }
        }
    }
}
