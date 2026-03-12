---
name: Achievement System Completion
overview: 將成就系統改為以專用 `achievements` 表儲存狀態、事件驅動更新，並擴充四大類成就（習慣養成、功能探索、財務健康、長期里程碑），搭配階梯式／疊加計數與現有 Progress Ring／glow UI。
todos: []
isProject: false
---

# 成就系統完善實作計畫

## 現狀摘要

- **成就來源**：目前由 [profile_page_data.dart](mobile/lib/features/profile/domain/profile_page_data.dart) 的 `buildAchievements(totalEntries)` 動態計算，僅 3 個成就（初來乍到、百筆達成、理財日常），且 `three_weeks_streak` 永遠為 0。
- **解鎖通知**：[achievement_unlock.dart](mobile/lib/features/profile/data/services/achievement_unlock.dart) 依 `EntryRepository.getCount()` 與 `buildAchievements()` 比對 SharedPreferences 已通知 ID 來觸發 Toast；成就狀態未持久化在 DB。
- **UI**：[AchievementBadgeGraphics](mobile/lib/features/profile/presentation/widgets/achievement_badge_graphics.dart) 已有 progress ring（未解鎖）、glow、`iconForId`；[AchievementBadgeItem](mobile/lib/features/profile/presentation/widgets/achievement_badge_item.dart) 顯示 current/target。
- **資料層**：SQLite 透過 [app_database.dart](mobile/lib/core/database/app_database.dart)，`entry` 表含 `created_at`、`occurred_at`；Account/Tag 有獨立 Repository；**預算功能尚未實作**（僅 plan + profile 假資料）。

## 架構決策

- **單一成就狀態表**：所有成就進度與解鎖狀態只存在 `achievements` 表，Profile 與成就列表僅讀取該表 + 靜態定義，不再在進入頁面時用交易/帳戶資料動態計算成就是否解鎖。
- **事件驅動更新**：在 Repository/Service 層於「新增/更新 entry、新增 account、首次進入統計頁、使用 tag」等事件後，於背景非同步更新對應成就的 `progress`/`unlocked_at`/`completed_count`；必要時做輕量查詢（例如當月筆數、當月 distinct 日數、最近 100 天 streak）。
- **狀態鎖定**：一旦寫入 `unlocked_at` 不再收回；刪除歷史帳務不影響已解鎖成就。
- **離線與多裝置**：`achievements` 表使用 client-generated UUID、`updated_at`、`synced`，與現有 sync 設計一致；各裝置只同步成就表，不需拉全量交易重算。

---

## 1. 資料庫：`achievements` 表與 Init 寫入

**路徑**：新增 `mobile/lib/features/profile/data/schema/achievement.dart`，在 [app_database.dart](mobile/lib/core/database/app_database.dart) 的 `_onCreate` 中執行此 schema（App 尚未正式發佈，不需特別處理 migration）。

**建議欄位**：

| 欄位                      | 型別                | 說明                                      |
| ----------------------- | ----------------- | --------------------------------------- |
| id                      | TEXT PK           | Client-generated UUID                   |
| achievement_id          | TEXT NOT NULL     | 成就代號，如 `first_entry`, `streak_100_days` |
| progress                | INTEGER DEFAULT 0 | 當前進度（如筆數、連續天數、當月已記帳日數）                  |
| target                  | INTEGER NOT NULL  | 目標值                                     |
| unlocked_at             | TEXT NULL         | 解鎖時間（ISO8601），一旦寫入不收回                   |
| completed_count         | INTEGER DEFAULT 0 | 疊加制用：達成次數（如全勤月數）                        |
| progress_period         | TEXT NULL         | 可選，當前進度所屬週期，如 `2025-03`（月）              |
| created_at / updated_at | TEXT              | 與現有表一致                                  |
| synced                  | INTEGER DEFAULT 0 | 供 sync 使用                               |

**索引**：`achievement_id` UNIQUE 或單列索引，以便 per-achievement 查詢/upsert（一使用者每個 `achievement_id` 一筆）。

**Init 時寫入所有成就**：比照 [account 的 schema](mobile/lib/features/account/data/schema/account.dart) 做法——**在 schema 檔案內**完成 init：

- `run(Database db)` 內先 `CREATE TABLE IF NOT EXISTS achievements (...)`，接著 `**await seedDefaults(db);`**（或命名為 `seedAchievements(db)`）。
- 同檔內實作 `seedDefaults(Database db)`：依靜態成就列表（可為同檔內常數列表，或 import 自 `achievement_definitions`）迴圈，對每個成就呼叫 `db.insert('achievements', {...}, conflictAlgorithm: ConflictAlgorithm.ignore)`，插入一筆列（client-generated `id`、`achievement_id`、`progress=0`、`target`、`unlocked_at=NULL`、`created_at`/`updated_at`/`synced` 等）。使用 `ConflictAlgorithm.ignore` 與 account 一致，重跑不會重複插入。

如此表中從一開始就具備所有成就的狀態列，之後事件驅動只做 UPDATE；AchievementRepository **不需**對外提供 seed 方法。

---

## 2. 成就定義（靜態）與 Repository

- **定義層**：建立靜態成就目錄（例如 `achievement_definitions.dart`），每個項目包含：`id`、`name`、`description`、`conditionText`、`target`、`category`（habit / discovery / financial / milestone）、`type`（one_shot / progressive / repeatable_stackable）、`isSecret`、圖示 key（對應 `AchievementBadgeGraphics.iconForId`）。
  - 習慣：全勤模範（疊加）、週末不打烊、補登達人；階梯式連續記帳 7/30/100 天。
  - 探索：資產總管、精打細算、數據分析師、分類強迫症。
  - 財務：預算守門員、開源節流、第一桶金。
  - 長期：記帳大師 1000 筆、歲月如梭一週年、連續百日（與階梯 100 天共用或同一邏輯）。
- **Repository**：`AchievementRepository` 負責依 `achievement_id` 取得/寫入一筆狀態、取得所有成就狀態（供 Profile / 成就列表）。Init 由 schema 的 `seedDefaults(db)` 完成，Repository 不負責也不暴露 seed。

Profile 的 `_loadData()` 改為：

- 從 `AchievementRepository` 取得「所有成就狀態」；
- 與靜態定義 merge 成 `List<AchievementItem>`（含 `current`/`target`/`isUnlocked`/`unlockedAt`/ 疊加用的 `completedCount`）；
- 其餘 stats（如總筆數、當月筆數）仍可由 `EntryRepository` 輕量查詢，僅供卡片數字與非成就邏輯使用；**成就解鎖與進度只讀自 `achievements` 表**。

---

## 3. 事件驅動更新（AchievementService）

集中一個 **AchievementService**（或擴展現有 [achievement_unlock](mobile/lib/features/profile/data/services/achievement_unlock.dart)）：在下列事件後只更新「受影響的」成就列，並做最少必要查詢。

- **Entry 新增/複製**（在 [EntryRepository](mobile/lib/features/entry/data/repositories/entry.dart) 的 `insert`/`duplicate` 成功後呼叫，或由上層在 `entry_page` 儲存成功後呼叫，並傳入 `occurredAt`、`createdAt`、`type`、是否為補登等）：
  - 第一筆 / 累積筆數（初來乍到、百筆、記帳大師 1000）：依 `EntryRepository.getCount()` 更新對應 achievement 的 progress，達標寫入 `unlocked_at`。
  - 補登達人：若為「事後補登」（例如 `occurred_at` 為昨日或更早），更新專用成就的連續補登次數（存在 progress 或另用一列）；非補登則將連續次數歸零。
  - 全勤模範：以 `occurred_at` 所屬月份為 `progress_period`，查詢該月「有記帳的 distinct 日數」與該月總日數，更新 progress/target；若 progress == target 則 `completed_count += 1` 並在首次達標時設 `unlocked_at`。
  - 週末不打烊：若該筆發生在週末，查詢「最近 4 個週末是否各有至少一筆」；若滿足則解鎖（one-shot）。
  - 連續 7/30/100 天：以 `occurred_at` 與 DB 中未刪除筆數，計算「以今天為止的連續記帳天數」（可限定只掃最近 100 天）；更新 streak_7_days、streak_30_days、streak_100_days 的 progress，達標則寫入 `unlocked_at`。
  - 開源節流：可選在「當月有變動」時，查詢當月收入/支出總和，若收入 > 支出則解鎖該月成就（one-shot 或疊加依產品決定）。
  - 第一桶金：若 `type == income` 且為首次收入，解鎖對應成就。
- **Account 新增**：在 [AccountRepository](mobile/lib/features/account/data/repositories/account.dart) 的 `insert` 成功後呼叫；查詢當前帳戶數（或 balance 帳戶數），若 >= 2 則解鎖「資產總管」。
- **首次進入統計/圖表頁**：在 [StatisticsPage](mobile/lib/features/statistics/presentation/pages/statistics_page.dart) 首次可見時（例如 `initState` 或 `didChangeDependencies` 搭配單次 flag），呼叫 Service 的「記錄首次查看統計」；Service 對應成就 progress=1, target=1，寫入 `unlocked_at`。
- **首次使用自訂標籤**：在新增/更新一筆 entry 且 `tagIds.isNotEmpty` 時，解鎖「分類強迫症」（一次即可）。
- **預算**：預算功能上線後，在「設定/啟用預算」與「月結算未超支」處各觸發一次成就更新（精打細算、預算守門員）；目前可先在定義中保留，progress 維持 0。
- **歲月如梭**：可在每次任一事務寫入後（或 App 啟動時）檢查：以「最早一筆 entry 的 created_at」或專用 `first_use_at`（若未來有）推算是否滿一年，是則解鎖；避免在 Profile 進入時才做大量掃描。

實作時注意：

- 所有「查詢」僅限於單次、有範圍的查詢（例如當月、最近 100 天、count），不在 Profile 載入時做。
- 已解鎖成就只做 progress 更新（例如疊加 `completed_count`），不覆寫 `unlocked_at` 為 null。

---

## 4. 習慣型成就的產品形態（對應你文件）

- **階梯式**：連續 7/30/100 天記帳 — 三個獨立 `achievement_id`，共用同一套「當前連續天數」計算，寫入各自 progress；現有 Progress Ring 直接顯示 progress/target。
- **疊加計數**：全勤模範（單月全勤）— 單一 `achievement_id`，`completed_count` 表示達成月數；徽章右上角顯示次數（如 x5）。
