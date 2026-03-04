---
name: Achievement System Plan
overview: 在新建的「我的 (Profile)」頁面中，導入專注於習慣養成與正向理財回饋的輕量級成就系統。
todos:
  - id: define-schema
    content: 定義 Achievement Schema 與資料庫儲存模型
    status: pending
  - id: implement-repository
    content: 實作 AchievementRepository 與連續天數/活躍週計算邏輯
    status: pending
  - id: implement-profile-ui
    content: 在 Profile 頁面中實作頂部的成就儀表板與徽章列表 UI
    status: pending
  - id: integrate-events
    content: 整合 Entry 儲存事件，觸發成就進度更新
    status: pending
  - id: implement-toast
    content: 實作解鎖成就時的無干擾 Toast 通知機制
    status: pending
isProject: false
---

# Achievement System Implementation Plan

## 1. 架構與狀態管理 (Architecture)

- 建立 `achievement` domain，包含 `Achievement` (定義) 與 `AchievementProgress` (進度) 的 Schema。
- **資料不可逆原則 (Append-only)**：Schema 中的 `unlockedAt` 應為不可逆狀態。若使用者刪除 Entry 導致進度倒退，**已解鎖的成就不得被收回**，以符合 UX 的 Forgiveness 原則。
- 實作 `AchievementService` 或 `AchievementRepository`，使用本地儲存 (如 Hive 或 SharedPreferences) 記錄進度。
- **時間基準點**：成就與進度的計算（如連續活躍週、累積筆數），應以**操作當下的系統時間 (System Time / Created At)** 為準。這能防止使用者透過事後大量補登歷史帳目來「刷」成就，確保成就系統真正獎勵的是「持續且規律使用 App 的行為」。
- 建立 Event Listener：監聽 `Entry` 的新增/刪除/更新操作，動態重新計算進度指標。

## 2. 核心成就定義 (Initial Achievements)

將成就分為三個維度，從單純的頻率擴展到正向理財行為：

- **習慣型 (Habit)**：
  - **初來乍到**：完成首筆記帳。
  - **百筆達成**：累積記帳滿 100 筆。
  - **理財日常**：連續 3 週、7 週有記帳活動 (改為追蹤「活躍週 Weekly Streak」，取代嚴苛的每日打卡，更符合真實週末補帳情境)。
- **探索型 (Discovery)**：
  - **精打細算**：建立第一筆預算。
  - **分類大師**：建立第一個自訂分類。
- **質量型 (Quality)**：
  - **克制力**：單週累積 3 個「無消費日 (No Spend Day)」。（*註：需搭配實作「標記今日無消費」的互動*）
  - **完美控制**：當月總花費低於設定預算。

## 3. Profile 頁面成就儀表板 (UI)

基於現有的 `profile_page.dart` 進行擴充：

- **頂部區塊**：加入使用者狀態卡片 (連續活躍週、總筆數、本週無消費日數)。
- **成就展示區**：建立水平滑動或網格狀的 `AchievementList` Widget，包含已解鎖 (彩色高亮) 與未解鎖 (帶進度條、灰階) 的徽章，落實 Progressive Disclosure (漸進式揭露)。
- **設定區塊**：將原本的設定項目維持在頁面的下方 Section。

## 4. 互動回饋 (UX)

- 在 `journal_page` 或 `entry_page` 儲存成功時，若觸發成就，顯示自訂的 Toast/SnackBar (例如使用 `cherry_toast` 或客製化 `Overlay`) 通知使用者。
- **無干擾設計**：Toast 必須顯示在畫面頂部 (Top-aligned)，絕對不可遮擋底部的「儲存」按鈕或鍵盤操作區，避免打斷高頻輸入的心流。
- **通知合併 (Debounce)**：實作 Debounce 機制，若短時間內 (如批次補帳時) 同時解鎖多個成就，應合併為一則通知 (例如：「🎉 一次解鎖了 2 項新成就！」)，避免畫面頻繁閃爍干擾。
