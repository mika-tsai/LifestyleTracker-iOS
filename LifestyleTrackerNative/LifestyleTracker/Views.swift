import SwiftUI
import EventKit
import UniformTypeIdentifiers

private let green = Color(red:0.18,green:0.39,blue:0.31)
private let softGreen = Color(red:0.91,green:0.95,blue:0.91)

struct MainView: View {
    @EnvironmentObject private var model: LifestyleModel
    var body: some View {
        TabView(selection:$model.selectedTab) {
            CalendarHomeView().tabItem { Label("月曆",systemImage:"calendar") }.tag(0)
            DayDetailView().tabItem { Label("當天",systemImage:"sun.max") }.tag(1)
            HabitsView().tabItem { Label("習慣",systemImage:"checklist") }.tag(2)
            TrendsView().tabItem { Label("趨勢",systemImage:"chart.xyaxis.line") }.tag(3)
            SettingsView().tabItem { Label("設定",systemImage:"gearshape") }.tag(4)
        }
        .alert("提醒", isPresented:Binding(get:{model.errorMessage != nil},set:{if !$0 {model.errorMessage=nil}})) {
            Button("好",role:.cancel){model.errorMessage=nil}
        } message: {Text(model.errorMessage ?? "")}
    }
}

struct CalendarHomeView: View {
    @EnvironmentObject private var model: LifestyleModel
    @EnvironmentObject private var cal: CalendarManager
    @State private var month = Date().startDay
    private let weekdays=["一","二","三","四","五","六","日"]
    private var grid: [Date?] {
        let calendar=Calendar.current
        let components=calendar.dateComponents([.year,.month],from:month)
        guard let first=calendar.date(from:components), let range=calendar.range(of:.day,in:.month,for:first) else{return []}
        let offset=(calendar.component(.weekday,from:first)+5)%7
        return Array(repeating:Date?.none,count:offset) + range.compactMap { calendar.date(byAdding:.day,value:$0-1,to:first) as Date? }
    }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment:.leading,spacing:18){
                    HStack {
                        Button { shiftMonth(-1) } label: {Image(systemName:"chevron.left").font(.headline)}
                        Spacer(); Text(month.monthLabel).font(.title2.bold()); Spacer()
                        Button { shiftMonth(1) } label: {Image(systemName:"chevron.right").font(.headline)}
                    }.padding(.horizontal,8)
                    LazyVGrid(columns:Array(repeating:GridItem(.flexible(),spacing:5),count:7),spacing:9){
                        ForEach(weekdays,id:\.self) { d in Text(d).font(.caption).foregroundStyle(.secondary) }
                        ForEach(grid.indices,id:\.self){ i in
                            if let date=grid[i] {
                                Button {
                                    model.selectedDay=date
                                    model.selectedTab=1
                                } label: {
                                    VStack(spacing:5){
                                        Text(String(Calendar.current.component(.day,from:date)))
                                            .font(.subheadline.weight(date.dayKey==Date().dayKey ? .bold:.regular))
                                        HStack(spacing:3){
                                            if !cal.events(on:date).isEmpty {Circle().fill(.blue).frame(width:5,height:5)}
                                            if model.data.records[date.dayKey] != nil {Circle().fill(.green).frame(width:5,height:5)}
                                        }.frame(height:6)
                                    }.frame(maxWidth:.infinity,minHeight:49)
                                        .background(date.dayKey==model.selectedDay.dayKey ? softGreen:Color(.secondarySystemGroupedBackground),in:RoundedRectangle(cornerRadius:10))
                                }.buttonStyle(.plain)
                            } else {Color.clear.frame(height:49)}
                        }
                    }
                    HStack(spacing:14){Label("日曆行程",systemImage:"circle.fill").foregroundStyle(.blue);Label("健康紀錄",systemImage:"circle.fill").foregroundStyle(.green)}.font(.caption)
                    infoCard(title:"今日建議",icon:"heart.text.square") {
                        let today=Date().startDay
                        let plan=Planner.make(day:today,events:cal.events(on:today),record:model.record(for:today),settings:model.data)
                        VStack(alignment:.leading,spacing:9){
                            Text("今日負荷：\(plan.load)").font(.headline)
                            Text(plan.summary).font(.subheadline)
                            Button("查看當日生活安排") {model.selectedDay=today;model.selectedTab=1}
                                .font(.subheadline.weight(.semibold))
                        }
                    }
                    if !cal.hasPermission {
                        infoCard(title:"連接 iPhone 行事曆",icon:"calendar.badge.exclamationmark") {
                            Text("要顯示 Google 行程，請先在 iPhone『設定 → App → 行事曆 → 行事曆帳號』加入 Google 帳號，然後在 App 設定頁允許行事曆權限。")
                                .font(.subheadline)
                            Button("前往 App 設定") {model.selectedTab=4}
                        }
                    }
                }.padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("我的生活重整 🐶")
            .onAppear {cal.loadEvents(center:month)}
        }
    }
    private func shiftMonth(_ amount:Int){
        month=Calendar.current.date(byAdding:.month,value:amount,to:month) ?? month
        cal.loadEvents(center:month)
    }
}

struct DayDetailView: View {
    @EnvironmentObject private var model:LifestyleModel
    @EnvironmentObject private var cal:CalendarManager
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment:.leading,spacing:14){
                    HStack {
                        Button {model.selectedDay=model.selectedDay.addingDays(-1);cal.loadEvents(center:model.selectedDay)} label:{Image(systemName:"chevron.left")}
                        Spacer()
                        DatePicker("日期",selection:$model.selectedDay,displayedComponents:.date).labelsHidden()
                        Spacer()
                        Button {model.selectedDay=model.selectedDay.addingDays(1);cal.loadEvents(center:model.selectedDay)} label:{Image(systemName:"chevron.right")}
                    }.padding(.horizontal)
                    Text(model.selectedDay.dayLabel).font(.title2.bold())
                    let record=model.record(for:model.selectedDay)
                    let plan=Planner.make(day:model.selectedDay,events:cal.events(on:model.selectedDay),record:record,settings:model.data)
                    infoCard(title:"今天的節奏 · \(plan.load)",icon:"sparkles") {
                        Text(plan.summary).font(.subheadline)
                    }
                    if !plan.warnings.isEmpty {
                        infoCard(title:"時間衝突／待確認",icon:"exclamationmark.triangle") {
                            ForEach(plan.warnings,id:\.self){Text("• "+$0).font(.subheadline)}
                        }
                    }
                    infoCard(title:"建議一日安排",icon:"clock") {
                        Text("綠色＝建議；日曆活動＝固定。這些不是 Google Calendar 新增的行程。").font(.caption).foregroundStyle(.secondary)
                        ForEach(plan.items){ item in
                            HStack(alignment:.top,spacing:10){
                                Text(item.time).font(.caption.monospacedDigit()).frame(width:105,alignment:.leading)
                                VStack(alignment:.leading,spacing:3){
                                    Text(item.title).font(.subheadline.weight(.semibold))
                                    Text(item.note).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer(minLength:0)
                                Image(systemName:item.kind == .fixed ? "calendar" : item.kind == .commute ? "tram" : "leaf")
                                    .foregroundStyle(item.kind == .fixed ? .blue : green)
                            }.padding(.vertical,6)
                            Divider()
                        }
                    }
                    DayRecordEditor(day:model.selectedDay)
                }.padding()
            }.background(Color(.systemGroupedBackground))
                .navigationTitle("當天")
                .onChange(of:model.selectedDay){_,newValue in cal.loadEvents(center:newValue)}
        }
    }
}

struct DayRecordEditor:View {
    @EnvironmentObject private var model:LifestyleModel
    let day:Date
    @State private var edited=DayRecord(day:Date().dayKey)
    @State private var confirmation=false
    var body:some View {
        infoCard(title:"今日健康紀錄",icon:"heart.text.square") {
            HStack {Text("入睡");Spacer();TextField("00:30",text:$edited.sleep).multilineTextAlignment(.trailing).keyboardType(.numbersAndPunctuation)}
            HStack {Text("實際離床");Spacer();TextField("08:10",text:$edited.wake).multilineTextAlignment(.trailing).keyboardType(.numbersAndPunctuation)}
            Stepper("精神程度：\(edited.energy)/10",value:$edited.energy,in:1...10)
            Stepper("疼痛程度：\(edited.pain)/10",value:$edited.pain,in:0...10)
            Stepper("有氧運動：\(edited.exercise) 分鐘",value:$edited.exercise,in:0...300,step:10)
            Toggle("早餐",isOn:$edited.breakfast)
            Toggle("午餐",isOn:$edited.lunch)
            Toggle("晚餐",isOn:$edited.dinner)
            Toggle("留意飲水",isOn:$edited.water)
            TextField("今天身體、情緒或經期的備註",text:$edited.notes,axis:.vertical).lineLimit(3...6)
                .textFieldStyle(.roundedBorder)
            Button {model.setRecord(edited);confirmation=true} label:{Label("儲存這一天",systemImage:"square.and.arrow.down").frame(maxWidth:.infinity)}
                .buttonStyle(.borderedProminent)
            if confirmation {Text("已儲存到 iPhone App 本機資料檔").font(.caption).foregroundStyle(.green)}
        }
        .onAppear {edited=model.record(for:day);confirmation=false}
        .onChange(of:day){_,date in edited=model.record(for:date);confirmation=false}
    }
}

struct HabitsView: View {
    @EnvironmentObject private var model:LifestyleModel
    @State private var category:HabitCategory = .daily
    @State private var title=""
    var body:some View {
        NavigationStack {
            ScrollView {
                VStack(alignment:.leading,spacing:14){
                    Picker("類別",selection:$category){ForEach(HabitCategory.allCases){Text($0.rawValue).tag($0)}}.pickerStyle(.segmented)
                    Text("勾選日期：\(model.selectedDay.dayLabel)").font(.subheadline).foregroundStyle(.secondary)
                    let habits=model.data.habits.filter{$0.category == category}
                    let count=habits.filter{model.isDone($0,on:model.selectedDay)}.count
                    ProgressView(value:Double(count),total:Double(max(1,habits.count)))
                    Text("已完成 \(count) / \(habits.count) 項").font(.caption)
                    infoCard(title:category.rawValue+"習慣",icon:"checklist") {
                        ForEach(habits){habit in
                            HStack(spacing:12){
                                Button {model.toggle(habit,on:model.selectedDay)} label:{
                                    Image(systemName:model.isDone(habit,on:model.selectedDay) ? "checkmark.circle.fill":"circle")
                                        .font(.title3)
                                }.buttonStyle(.plain)
                                VStack(alignment:.leading,spacing:3){
                                    Text(habit.title).font(.subheadline)
                                    if !habit.detail.isEmpty {Text(habit.detail).font(.caption).foregroundStyle(.secondary)}
                                }
                                Spacer()
                                Button(role:.destructive){model.removeHabit(habit)}label:{Image(systemName:"trash").font(.caption)}
                            }.padding(.vertical,5)
                            Divider()
                        }
                        HStack {
                            TextField("新增自己的習慣",text:$title).textFieldStyle(.roundedBorder)
                            Button("新增") {model.addHabit(title,category:category);title=""}.disabled(title.trimmingCharacters(in:.whitespaces).isEmpty)
                        }
                    }
                    Text("目標不是每天都打滿勾；疲倦時先保留睡眠、飲食和必要休息。")
                        .font(.caption).foregroundStyle(.secondary)
                }.padding()
            }.background(Color(.systemGroupedBackground)).navigationTitle("習慣")
        }
    }
}

struct TrendsView: View {
    @EnvironmentObject private var model:LifestyleModel
    private var recent:[DayRecord] {
        (0..<14).compactMap { i in model.data.records[Date().addingDays(-i).dayKey] }.reversed()
    }
    var body:some View {
        NavigationStack {
            ScrollView {
                VStack(alignment:.leading,spacing:15){
                    let average=recent.isEmpty ? 0 : Double(recent.map(\.energy).reduce(0,+))/Double(recent.count)
                    let aerobic=recent.map(\.exercise).reduce(0,+)
                    HStack {
                        metric("近 14 天紀錄", "\(recent.count) 天")
                        metric("平均精神", recent.isEmpty ? "—" : String(format:"%.1f/10",average))
                        metric("有氧累積", "\(aerobic) 分")
                    }
                    infoCard(title:"最近紀錄",icon:"chart.bar"){
                        if recent.isEmpty {Text("先在『當天』記錄睡眠和精神，這裡就會出現趨勢。")}
                        ForEach(recent) { r in
                            HStack {Text(r.day).font(.caption);Spacer();Text("精神 \(r.energy)/10").font(.subheadline);Text("疼痛 \(r.pain)/10").font(.caption).foregroundStyle(.secondary)}
                            Divider()
                        }
                    }
                    Text("這些紀錄僅供觀察規律，不能用於診斷。整天持續疲倦或嚴重經痛請尋求醫師評估。")
                        .font(.caption).foregroundStyle(.secondary)
                }.padding()
            }.background(Color(.systemGroupedBackground)).navigationTitle("趨勢")
        }
    }
    private func metric(_ title:String,_ value:String)->some View {
        VStack(spacing:8){Text(title).font(.caption).foregroundStyle(.secondary);Text(value).font(.subheadline.bold())}
            .frame(maxWidth:.infinity,minHeight:80).background(softGreen,in:RoundedRectangle(cornerRadius:12))
    }
}

struct SettingsView: View {
    @EnvironmentObject private var model:LifestyleModel
    @EnvironmentObject private var cal:CalendarManager
    @State private var showImporter=false
    @State private var exportURL:URL?
    var body:some View {
        NavigationStack {
            Form {
                Section("iPhone 行事曆 / Google Calendar") {
                    Text("原生版使用 iOS EventKit，不需要網頁 Google OAuth。先在 iPhone 設定將 Google 帳號加入行事曆，再授權本 App。")
                        .font(.caption)
                    if cal.hasPermission {
                        Label("行事曆權限已開啟",systemImage:"checkmark.circle.fill").foregroundStyle(.green)
                        Text(cal.message).font(.caption)
                        HStack {Button("全選") { for c in cal.calendars where !cal.selectedIDs.contains(c.calendarIdentifier) {cal.toggleCalendar(c.calendarIdentifier,center:model.selectedDay)} };Spacer();Button("全部取消") {for c in cal.calendars where cal.selectedIDs.contains(c.calendarIdentifier) {cal.toggleCalendar(c.calendarIdentifier,center:model.selectedDay)}}}
                        ForEach(cal.calendars,id:\.calendarIdentifier){ calendar in
                            Toggle(calendar.title,isOn:Binding(get:{cal.selectedIDs.contains(calendar.calendarIdentifier)},set:{_ in cal.toggleCalendar(calendar.calendarIdentifier,center:model.selectedDay)}))
                        }
                        Button("重新讀取行程") {cal.loadEvents(center:model.selectedDay)}
                    }else {
                        Button("允許讀取行事曆") {Task{await cal.requestAccess()}}
                        Text(cal.message).font(.caption).foregroundStyle(.secondary)
                    }
                }
                Section("生活規劃設定") {
                    Stepper("跨地點通勤 \(model.data.commuteMinutes) 分鐘",value:$model.data.commuteMinutes,in:10...180,step:5)
                    Stepper("預設上班 \(model.data.workStartHour):00",value:$model.data.workStartHour,in:5...16)
                    Stepper("預設下班 \(model.data.workEndHour):00",value:$model.data.workEndHour,in:12...23)
                    Stepper("每週有氧目標 \(model.data.targetExerciseMinutes) 分鐘",value:$model.data.targetExerciseMinutes,in:0...300,step:15)
                    Toggle("早上完整洗澡（增加晨間準備時間）",isOn:$model.data.showerInMorning)
                    Text("上班時間是預設值，不會取代 Google Calendar 行程；提醒僅供規劃。")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Section("備份與資料") {
                    Text("所有健康與習慣資料存在這支 iPhone 的 App 私有資料夾。未啟用 iCloud，同一帳號的 Mac 不會自動同步。Google Calendar 行程只是即時讀取，不寫入健康資料。")
                        .font(.caption)
                    Button("準備 JSON 備份") {exportURL=model.exportURL()}
                    if let url=exportURL {ShareLink(item:url) {Label("分享／儲存備份檔",systemImage:"square.and.arrow.up")}}
                    Button("從 JSON 匯入（覆蓋目前紀錄）") {showImporter=true}
                }
                Section("關於") {
                    Text("Lifestyle Tracker · 原生 SwiftUI 版")
                    Text("純個人使用，App 不會將紀錄上傳 GitHub 或 Google。")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("設定")
            .fileImporter(isPresented:$showImporter,allowedContentTypes:[.json]) {result in
                switch result {
                case .success(let url):model.importFile(url)
                case .failure(let err):model.errorMessage=err.localizedDescription
                }
            }
        }
    }
}

@ViewBuilder
func infoCard<Content:View>(title:String,icon:String,@ViewBuilder content:()->Content)->some View {
    VStack(alignment:.leading,spacing:12){
        Label(title,systemImage:icon).font(.headline).foregroundStyle(green)
        content()
    }.padding(16).frame(maxWidth:.infinity,alignment:.leading)
        .background(Color(.secondarySystemGroupedBackground),in:RoundedRectangle(cornerRadius:16))
}
