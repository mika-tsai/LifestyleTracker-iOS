# Lifestyle Tracker · iPhone 原生 App（SwiftUI）

這是 **Xcode 原生 iOS 專案**，不是 HTML/PWA，也不是可以直接點 ZIP 安裝的 IPA。

## 第一次安裝（Mac + iPhone）
1. 在 Mac App Store 安裝 **Xcode**（建議最新版）。解壓縮專案 ZIP。
2. 雙擊 `LifestyleTracker.xcodeproj`，用 Xcode 開啟。
3. 點左側藍色專案 `LifestyleTracker` → TARGETS `LifestyleTracker` → **Signing & Capabilities**。
4. 勾選 `Automatically manage signing`，在 **Team** 選自己的 Apple Account／Personal Team。若尚未登入，Xcode → Settings → Accounts → 加入 Apple Account。
5. 若 Bundle Identifier 已被使用，改成自己的唯一名稱，例如 `com.你的英文代號.lifestyletracker`。
6. 使用傳輸線連接 iPhone、解鎖並信任電腦；Xcode 上方選你的 iPhone 作為執行目標。
7. 若提示 Developer Mode：iPhone 設定 → 隱私權與安全性 → 開發者模式，依畫面重新啟動並確認。
8. 在 Xcode 按左上角 ▶ Run。安裝後可在主畫面看見線條小狗圖示。

## Google Calendar 讀取
- 這個版本透過 **iOS EventKit 行事曆**，不使用原網頁 Google OAuth Client ID。
- iPhone 設定 → App → 行事曆 → 行事曆帳號（或設定 → 行事曆 → 帳號）→ 新增 Google 帳號並開啟日曆同步。
- 確認 Apple「行事曆」App 能看到 Google 日曆。
- Lifestyle Tracker → 設定 → 允許讀取行事曆 → 在選單勾選要納入分析的日曆。沒有勾選就不會被 App 納入分析。
- iOS 提供的是 **Full Calendar Access** 系統權限，技術上允許讀寫；但本專案程式只讀取活動，不提供新增、修改或刪除行程的功能。

## 資料儲存
- 健康紀錄與打卡：iPhone App 的 Application Support/lifestyle-data.json，本機私有空間。
- 選擇的日曆：UserDefaults（僅保存識別碼）。
- 行程：從 iOS 系統日曆讀取，App 不會上傳行程到自己的伺服器。
- 沒有 iCloud 跨裝置即時同步。請在 App「設定」匯出 JSON 定期備份。匯入會覆蓋目前紀錄。
- 如果換了 Bundle Identifier、解除安裝 App，原本資料可能無法保留。
- **舊版網頁/PWA 的 localStorage 不會自動移植到原生 App**，並且其 JSON 資料格式與這版不同；如需遷移，需另行製作轉換工具。

## 限制
- 排程採本機規則：依使用者勾選的日曆、通勤預設 60 分鐘、疲勞/疼痛分數及星期判斷，不具備完整地圖路線規劃或 AI 自動調整能力。
- 工作日暫以 10:00–18:00 作為預設；如果實際家教銜接衝突，App 會警告，但不會擅自更改日曆。
- 自動排程只顯示在 App 內，不寫入 Apple/Google 日曆。
- 不能在此 Linux 環境使用 xcodebuild 編譯或在實機測試；第一次打開時如 Xcode 出現編譯或簽署錯誤，請依錯誤訊息調整。
- 免費 Personal Team 佈署的簽署／provisioning 通常需要定期（約七天）重簽及重新安裝；不代表資料有雲端備份。

### 軟體結構
`LifestyleTrackerApp.swift`：進入點；`Models.swift`：資料模型；`LifestyleModel.swift`：檔案儲存；`CalendarManager.swift`：EventKit；`Planner.swift`：每日建議規則；`Views.swift`：五個頁面。
