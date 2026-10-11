# 03 資料格式

> 狀態：已確認（2026-10-10）
> 建立日期：2026-10-10
> 依據：`docs/00-decisions.md`、`docs/01-architecture.md`、`docs/02-networking.md`
> 決策編號格式：`03-Dxx`
> 修訂：第 2 版（2026-10-10）依你確認第 1 版時的指示修改：所有資料都用英文，中文顯示文字另外放（00-S06）；RO 的老舊做法不照抄，並考慮效能優化（00-S14）。第 1 版的 10 項待確認事項你回覆「全部照建議」，紀錄在第 16.1 節。
> 修訂：2026-10-10，第 10.1 節的 origin 加上 makehuman、第 10.2 節寫明 Tripo 的授權代碼（確認 04 時同意，見 04 第 19 節）
> 修訂：2026-10-10，第 4.11 節第一版的外觀選項、第 8.3 節的範例改用 05 定的選項（依你的授權先照建議定案，見 05 第 16 節）
> 修訂：2026-10-10，第 4.9 節加上等級差修正表、第 4.10 節加上戰鬥用的規則常數（依你的授權先照建議定案，見 06 第 19 節）
> 修訂：2026-10-10，M0 實作時依 11-D10 補充：第 3.1 節加上外觀資料夾的例外、第 3.3 節寫明換算後的欄位名稱、第 4.10 節加上 `new_character`、第 4.11 節寫明每種外觀各自一張表（見 `artifacts/review/m0-b`、`m0-d` 的報告）
> 修訂：2026-10-11，依 `docs/proposals/`（最終決定在 `2026-10-11-replies.md`）：資料改用公尺、公尺／秒（03-D05、第 3.3 節）；顯示文字全部移出 `data/`，`locale/` 改成多語言（03-D02、03-D17、第 7 節）；新增生成表、附加能力、任務、NPC、感知組合的資料表（第 4.13～4.17 節）；物品實例、效果類型、存檔改 SQLite 的時程（第 4.7、8 節）；地圖標記加上 `spawn_id`、不能過的傳點、NPC 位置（第 6.2 節）；授權登記表照 04 放寬（第 10 節）；地圖的中文名稱改成克羅能堡（03-D14）

---

## 1. 目的與範圍

**本文件決定：**
- 遊戲資料表（`data/`）的檔案格式、分檔方式、ID、單位和數字規則
- 各資料表有哪些欄位（照 RO Renewal 的機制，用現代的寫法）
- 邏輯資料和表現資料怎麼分開（`visual_id` 和 `.tres`）
- 地圖 ID、地圖定義，以及出生點、傳送點、怪物生成區、安全區、NPC 位置怎麼擺
- 生成表、附加能力、任務、NPC、怪物感知的資料表
- 座標和角度的慣例
- 顯示文字（各種語言）放在哪裡
- 存檔（帳號、角色）的欄位、版本號和遷移規則
- 客戶端和伺服器的設定檔
- 授權登記表
- 資料驗證和守門測試

**不在本文件：**

| 內容 | 文件 |
|---|---|
| 數值本身（職業的 HP 表、技能倍率、怪物數值）、公式、RO 數值的換算表、以哪一版 Renewal 為準 | 06、07 |
| 素材管線、`assets/` 底下的分類細節、面數和貼圖預算 | 04 |
| `.tres` 外觀設定的內容（動作清單、掛點、頭髮顯示模式） | 05、07 |
| 地圖內容、導航網格怎麼烘焙、觀測點擺在哪裡 | 08 |
| 預設按鍵、鏡頭設定的項目 | 09 |
| 介面文字的內容、致謝名單在哪裡顯示 | 10 |
| 每一批要做哪些資料 | 11 |

---

## 2. 決策摘要

| 編號 | 決策 | 理由／對應 00 |
|---|---|---|
| 03-D01 | 遊戲資料用 JSON（UTF-8、無 BOM、LF），放在 `data/`。一種資料一個資料夾，資料夾裡可以分成多個檔。每個檔有標頭和項目陣列，每個項目都有 `id`。 | Godot 內建，伺服器不用載入美術資源就能讀；文字檔好比對差異，也方便算 02-D05 的資料雜湊。項目用陣列，不用「以 ID 當鍵的物件」，因為 Godot 遇到重複的鍵會默默保留後面那個，重複的 ID 就抓不到了。 |
| 03-D02 | 資料只放 ID、數值和給開發看的英文備註（`ro_ref`、`note`），不放名稱和說明；顯示文字一律放在 `locale/<語系>/`（第 7 節）。`data/` 裡不能有中文字元，檔名和資料夾名稱也不能有，由守門測試檢查。 | 00-S06（2026-10-11 改：顯示文字全部移出資料，改任何語言的文字都不會動到資料雜湊和伺服器）。 |
| 03-D03 | ID 是英文小寫加底線的描述性名稱，例如 `swordsman`、`bash`、`gelly`，不沿用 RO 的縮寫（例如 `SM_BASH`）。RO 的名稱記在 `ro_ref`。存檔用到的 ID 不能隨便改名，要改就寫遷移。 | 好讀（00-S14）；`ro_ref` 保留跟 RO 的對照。 |
| 03-D04 | 網路上的資料 ID 一律用 u16 索引，也就是每種資料依 ID 排序後的順序。兩邊的資料雜湊相同（02-D05），索引就一定一致。存檔一律存 ID 字串。 | 比送字串省頻寬，處理也比較快（00-S14 的效能優化）。 |
| 03-D05 | 資料一律用 3D 的標準單位：時間用毫秒；距離、範圍、射程、尺寸、位置用公尺；速度用公尺／秒；角度用度。欄位名稱一定帶單位後綴（`_ms`、`_m`、`_mps`、`_deg`）。不存格數。RO 的原始值靠 `ro_ref` 追，換算表在 06 第 3 節（RO 的 1 格 ＝ 1 公尺）。 | 3D 要表達身體大小、高度差、扇形範圍，格子表達不了；執行中本來就只用公尺（2026-10-11 改，原本是「照 RO 的格數存、載入時換算」）。 |
| 03-D06 | 程式執行時，遊戲規則的數值一律是整數。資料檔裡寫看得懂的數字：重量寫遊戲裡顯示的值（最多 1 位小數），機率寫百分比（最多 2 位小數），載入時再轉成整數（重量以 0.1 為單位、機率用萬分率）；距離和速度可以有小數（最多 2 位）。 | 不照抄 RO 的「重量 10 代表 1」「7000 代表 70%」（00-S14），計算仍然全部是整數。 |
| 03-D07 | 每種資料在 shared 裡有一個定義類別，同時當作 schema（型別、必填、範圍、列舉、參照）。載入時全部驗證，錯誤一次列完；有任何錯誤就拒絕啟動。驗證通過後轉成唯讀物件，常用的表（屬性表、體型修正表）攤平成陣列直接查。 | 錯誤在啟動時就抓到；戰鬥中查表不用再查字典（效能）。 |
| 03-D08 | 欄位照 RO Renewal 的機制設計（參考 rAthena 的 `db/re`），但用清楚的名稱，不照抄 RO 的舊寫法，例如用負數表示特殊意義、意義不固定的「第二持續時間」。數值由 06、07 填。 | 00-S04、00-S07、00-S14。 |
| 03-D09 | 不建「種族修正表」。RO 沒有全域的種族修正，種族只給技能和裝備效果判斷用。 | 00-S07（第 1 版第 2 項，已同意）。 |
| 03-D10 | 怪物的行為用「有名字的行為組合」（例如 `passive_looter`），每個組合是一組行為旗標，不用 RO 的 AI 類型編號（01～27）。行為旗標跟 RO 相同，所以行為也相同。 | 編號看不出意思（00-S14）。 |
| 03-D11 | 攻擊的命中時間只有一個 `attack_hit_ms`：伺服器在這個時間套用傷害，客戶端的動作命中點也對齊它，由測試檢查。 | RO 的伺服器和客戶端各用一個時間，要另外設定才會同步（00-S14）。 |
| 03-D12 | 影響遊戲規則的常數（玩家移動速度、新角色出生點、抵達保護時間、噪音、高度差上限等）放在 `data/rules/`；只跟伺服器運作有關的設定（埠、tick 頻率）放在 `server.cfg`。 | 規則兩邊一定一致，也算進資料雜湊；運作設定可以每台伺服器不同。 |
| 03-D13 | JSON 只放 `visual_id` 字串。模型、動作庫、掛點偏移、頭飾的頭髮顯示模式等放在客戶端的 `.tres`，用 `visual_id` 依固定路徑找到；第一次用到時才載入，之後快取。伺服器從不載入 `.tres`。 | 伺服器完全不依賴美術素材（00-A04、01-D07）。RO 的物品資料用「外觀編號（View）」也是同樣的做法。 |
| 03-D14 | 地圖 ID 是 `kronenberg` 和 `kronenberg_south_field`，中文顯示名稱是「克羅能堡」和「克羅能堡南方草原」（00-S13，放在 `locale/`）。地圖定義放在 `data/maps/`。 | 第 1 版第 3 項，已同意；中文名稱 2026-10-11 改。 |
| 03-D15 | 出生點、傳送點、怪物生成區、安全區、NPC 位置用 logic 場景裡的標記節點擺放，參數用匯出屬性設定。傳送點的目的地寫「目標地圖＋抵達點名稱」，不寫座標；還沒開放的出口用不能過的傳點（`open` 是 false）。怪物生成區只放範圍和 `spawn_id`，生成的內容（怪物、數量、重生時間）在 `data/spawns/`。 | 在編輯器裡直接看得到位置（計畫大綱）；移動抵達點時，傳送點會自動跟著；調生成數量不用改場景（2026-10-11 加）。 |
| 03-D16 | 座標：1 單位 ＝ 1 公尺，Y 朝上，地圖北方是 −Z、東方是 +X。面向 0° 朝北，數字增加時逆時針轉（從上往下看）。 | 跟 Godot 的 Y 軸旋轉方向一致，也跟 RO 的方向編號順序（北、西北、西…）一致。 |
| 03-D17 | 顯示文字放在 `locale/`：一份語言清單（`locales.json`），每種語言一個資料夾，地位相同。第一版是繁體中文（預設）和英文，兩種都要 100% 完整；之後加的語言可以不完整，缺的依清單退回。執行中可以切換。只有客戶端讀，不算進資料雜湊。 | 00-S06。改任何語言的文字都不用動伺服器；加一種語言只要加一個資料夾和清單的一行（2026-10-11 改）。 |
| 03-D18 | 存檔：M9 之前一個帳號一個檔、一個角色一個檔（02-D17）；M9 之前改成 SQLite（單機和多人都改，角色資料仍然是 JSON，放在一個欄位裡），另外有匯出 JSON 的工具。欄位照 RO 的角色資料，加上 00-A10 的外觀預留欄位。第一版只寫位置、職業和外觀。永久 ID 是遞增的整數，不重複使用。 | 01 第 16 節、02 第 12.2 節。 |
| 03-D19 | 角色名稱 2～16 個字（中文、英文字母、數字都算 1 個字）。全伺服器不重複，比對時不分大小寫、不分全形半形，看起來一樣的名稱也算重複。 | RO 用位元組算長度、分大小寫，是舊編碼留下的限制，也容易被冒充（00-S14）。 |
| 03-D20 | 存檔遷移：每個檔有 `schema_version`，舊版一步一步遷移到新版，遷移前先備份。版本比程式新、有不認識的欄位、引用不存在的資料 ID，一律拒絕讀取並記錄錯誤，原檔不動。 | 寧可讀不進來，也不要默默丟掉資料（第 1 版第 6 項，已同意）。 |
| 03-D21 | 寫檔順序：寫暫存檔 → 舊檔改名成備份 → 暫存檔改名成正式檔。讀檔時正式檔壞了或不見，依序改用暫存檔、備份。 | Godot 在 Windows 上「改名覆蓋」會先刪掉舊檔，不是一步完成。這是 02-D17 的具體做法，沒有改變它。 |
| 03-D22 | 設定檔：客戶端 `user://settings.cfg`、伺服器 `server.cfg`，都是 ConfigFile。客戶端設定壞了就用預設值；伺服器設定錯了就拒絕啟動。使用者資料夾固定為 `%APPDATA%\RagnarokChange\`。 | 遊戲不會因為設定開不起來；伺服器不會用錯的設定跑（第 1 版第 5 項，已同意）。 |
| 03-D23 | 授權登記表是 `assets/license_registry.json`，每個素材一筆，授權名稱用 SPDX 代碼。管線自動新增；守門測試檢查每個素材檔都有登記，授權和限制標記照 04 第 5 節的白名單（2026-10-11 放寬：收 NC、SA，ND 只有原樣使用時才收）；有限制或跟概念圖不同的素材標上待替換的原因。 | 00-A11、00-S16、01 第 4.3 節（第 1 版第 7 項，已同意）。 |
| 03-D24 | 資料分「定義（`data/`，唯讀）、狀態（伺服器和存檔）、衍生值（快取，不存檔）」三層（01 第 7.5 節）。狀態只用 ID 或 u16 索引指向定義，不複製定義的數值。物品實例有固定的欄位（第 8.3 節）。 | 改了平衡數值立刻生效；存檔小、遷移單純（2026-10-11 加）。 |
| 03-D25 | 裝備、卡片、附加能力、狀態效果、被動技能的效果，共用一套「有名字的效果類型」：`{effect, 參數…, value, when}`。每種效果在 shared 有定義（名稱、參數、型別），伺服器有一個處理器；名稱照用途取，RO 的 bonus 腳本記在 `ro_ref`。不發明腳本語言。 | 加新效果只要加一個定義、一個處理器和測試；驗證擋得住未知的效果和錯的參數（2026-10-11 加）。 |
| 03-D26 | 任務和 NPC 對話是資料（`data/quests/`、`data/npcs/`）：任務的步驟只有固定幾種（`talk`、`kill`、`collect`、`deliver`），對話節點只能做固定幾種動作。不用 RO 的 NPC 腳本語言。 | 00-S14；跟技能「做什麼寫在程式、資料只放數值」一致（2026-10-11 加）。 |

---

## 3. 共通規則

### 3.1 檔案與語言

- 編碼 UTF-8、不加 BOM、換行 LF（`.gitattributes` 已經規定 JSON 用 LF）。
- 縮排 2 個空白。程式寫出的 JSON（存檔、登記表）一律把鍵排序後輸出，比對差異時才看得清楚。
- 檔名和資料夾名稱一律用英文小寫加底線；資料檔、場景、素材、概念圖都一樣（00-S06）。
- `data/` 裡只有 ID、數值、列舉和英文備註，沒有玩家看得到的文字。名稱和說明放在 `locale/<語系>/`（第 7 節）。
- 資料檔的結構：

```text
{
  "table": "monsters",          ← 資料表名稱，要跟資料夾名稱一致
  "entries": [
    { "id": "...", ... },
    { "id": "...", ... }
  ]
}
```

- 同一種資料可以分成多個檔（例如技能依職業分檔），載入時合併；ID 在整種資料裡都不能重複。
- 唯一的例外：`data/appearance/` 放四張表（hair_styles、hair_colors、eye_colors、face_shapes），因為髮色和瞳色都有 `brown`，放同一張表會撞 ID（第 4.11 節）。
- JSON 不能寫註解。需要說明時，用兩個所有項目都可以有、遊戲不會讀的欄位（一樣用英文）：
  - `ro_ref`：對應的 RO 項目，例如 `PORING (1002)`，用來追查數值的來源。
  - `note`：給人看的備註。

Godot 的 JSON 解析器跟標準不完全一樣（官方文件有寫），要注意：

| 行為 | 影響 | 對策 |
|---|---|---|
| 所有數字都讀成浮點數 | 整數欄位要自己轉；超過 2⁵³ 的整數會失真 | 03-D06；所有整數都在 2⁵³ 以內 |
| 同一個物件裡有重複的鍵時，默默保留後面那個 | 重複的欄位會被吃掉 | 項目用陣列（03-D01）；驗證時另外掃描原始文字，找出同一個物件裡重複的鍵 |
| 陣列或物件結尾多一個逗號不會報錯 | 換其他工具讀就可能失敗 | 同一次文字掃描一起檢查 |

### 3.2 ID

| 規則 | 內容 |
|---|---|
| 格式 | 小寫英文字母開頭，只用小寫英文字母、數字、底線，最長 48 個字元。 |
| 範圍 | 同一種資料裡不能重複；不同種資料可以同名（物品 `knife` 和外觀 `knife` 不衝突）。 |
| 命名 | 描述性的英文，例如職業 `swordsman`、技能 `bash`、`double_attack`、`heal`、怪物 `gelly`。不沿用 RO 的 Aegis 縮寫（例如 `SM_BASH`），也不沿用 RO 的拼法（RO 把劍士拼成 Swordman）；RO 的名稱記在 `ro_ref`。概念圖已經有英文名稱的，資料 ID 用同一個（見 `ConceptArt/README.md`）。 |
| 穩定 | 被存檔用到的 ID（職業、物品、技能、地圖等）要改名時，一定要寫遷移（第 8.4 節）。 |
| 網路 | 用 u16 索引（03-D04）：每種資料依 ID 的字母順序從 0 開始編號，一種資料最多 65,536 筆。新增或刪除項目時索引會變，但連線時已經比對過資料雜湊，兩邊一定一樣。索引只用在網路上，存檔一律存 ID 字串。 |

### 3.3 單位

| 種類 | 單位 | 欄位後綴 | 例子 |
|---|---|---|---|
| 時間 | 毫秒（整數） | `_ms` | `attack_interval_ms`、`cooldown_ms` |
| 距離、範圍、射程、尺寸、位置、半徑 | 公尺（最多 2 位小數） | `_m` | `attack_range_m`、`body_radius_m`、`interest_radius_m` |
| 速度 | 公尺／秒（最多 2 位小數） | `_mps` | `move_speed_mps` |
| 角度 | 度 | `_deg` | `facing_deg`、`cone_angle_deg` |
| 重量 | 遊戲裡顯示的重量，最多 1 位小數 | — | `weight`（例如 40、0.1） |
| 機率 | 百分比，最多 2 位小數 | `_pct` | `chance_pct`（例如 70、0.01） |
| 修正比例 | 百分率整數（100 ＝ 100%） | `_pct` | `cast_def_reduction_pct` |

- 不存格數，也沒有「1 格幾公尺」的設定（2026-10-11 拿掉 `_cells`、`_ms_per_cell` 和 `cell_size_m`）。
- 從 RO 的資料填值時，照 06 第 3 節的換算表算一次（RO 的 1 格 ＝ 1 公尺；移動速度 N 毫秒／格 ＝ 1000 ÷ N 公尺／秒），原始值和來源記在 `ro_ref`。
- 例：RO 玩家預設 150 毫秒走一格，就是 6.67 m/s。以寫實人物來說偏快，06 和 09 會一起檢討。

### 3.4 數字

- 程式執行時，遊戲規則的數值（HP、ATK、經驗值、機率、時間）一律是整數，跟 RO 一樣。小數只出現在位置、距離、速度、角度、外觀權重這類空間或表現的數值。
- 資料檔裡只有重量、機率、距離和速度可以寫小數。重量和機率載入時轉成整數：重量 × 10，機率 × 100（變成萬分率）；距離和速度最多 2 位小數，執行中用浮點數（位置本來就是浮點數）。超過精度（例如重量寫 `0.15`、距離寫 `1.255`）就報錯，不會默默捨入。
- 其他整數欄位寫了小數（例如 `1.5`）也報錯。
- 每個數字欄位都有範圍，例如等級 1～99、屬性等級 1～4、機率 0～100。

### 3.5 列舉

列舉值在 JSON 裡寫英文字串，不寫數字。定義放在 shared，各語言的名稱放在 `locale/<語系>/enums.json`（例如 `enum.element.fire` → 「火」）。

| 列舉 | 值 | RO 對應 |
|---|---|---|
| 屬性 | neutral、water、earth、fire、wind、poison、holy、dark、ghost、undead | Element（10 種） |
| 屬性等級 | 1～4 | ElementLevel |
| 體型 | small、medium、large | Size |
| 種族 | formless、undead、brute、plant、insect、fish、demon、demihuman、angel、dragon | Race。玩家算哪一種由 06 決定（新版 RO 把玩家從 demihuman 分了出來） |
| 怪物等級 | normal、boss、mvp | Class 加上 MVP 旗標。RO 另有 guardian、battlefield、event，用不到就不留 |
| 性別 | female、male | Gender |
| 素質 | str、agi、vit、int、dex、luk | — |
| 裝備位置 | head_top、head_mid、head_low、armor、weapon、shield、garment、shoes、accessory_1、accessory_2 | Locations。RO 叫 Right_Hand、Left_Hand、Right_Accessory、Left_Accessory，這裡改成看得懂的名稱 |
| 武器種類 | fist、dagger、one_handed_sword、two_handed_sword、one_handed_spear、two_handed_spear、one_handed_axe、two_handed_axe、one_handed_mace、two_handed_mace、one_handed_staff、two_handed_staff、bow | 四個職業的基礎 ASPD 表裡出現的種類。概念圖已經有短劍、單手劍、雙手劍、鈍器、單手杖；第一版要做哪幾種由 05 挑 |
| 物品類型 | consumable、misc、weapon、armor、card、ammo | Type。RO 把 Healing、Usable、DelayConsume 分成三種，這裡合併成 consumable，用法寫在使用效果裡；Etc 改叫 misc |
| 技能目標 | passive、attack、ground、self、support、trap | TargetType |
| 技能攻擊類型 | none、weapon、magic、misc | Type |
| 傷害顯示 | split（每段分開顯示）、total（合計成一個數字） | 取代 RO 的 Hit 類型和「段數寫負數」的寫法 |
| 範圍形狀 | circle、square、cone、line | RO 只有方形範圍；方形範圍（半徑 k 格）換成半徑 k＋0.5 m 的圓（06 第 3 節） |
| 任務步驟 | talk、kill、collect、deliver | NPC 腳本裡的條件（第 4.16 節） |

### 3.6 每級數值

技能這類「每一級不同」的欄位，可以寫成：
- **一個數字**：所有等級都一樣。
- **一個陣列**：長度一定要等於最大等級，第 1 個是 1 級的值。

例：狂擊（`bash`）的 SP 消耗在 RO 是 1～5 級 8、6～10 級 15，就寫成 `[8, 8, 8, 8, 8, 15, 15, 15, 15, 15]`；如果每級都是 8，直接寫 `8`。

---

## 4. 遊戲資料表

### 4.1 目錄

```text
data/
  rules/              全域規則（只有一個項目：default）
  jobs/               職業
  skills/             技能，依職業分檔（novice、swordsman、thief、acolyte）
  status_effects/     狀態效果
  monsters/           怪物
  monster_behaviors/  怪物的行為組合
  items/              物品，依種類分檔（weapons、shields、headgears、armors、consumables、misc、cards）
  maps/               地圖定義
  tables/             數值表（經驗表、基礎 HP/SP 表、素質點數表、屬性表、體型修正表）
  appearance/         外觀選項（髮型、髮色、瞳色、臉部形狀；00-A10 預留）
  spawns/             怪物的生成表，一張地圖一個檔（第 4.13 節）
  perception_profiles/ 怪物的感知組合（第 4.14 節）
  random_options/     附加能力的每一種能力（第 4.15 節）
  random_option_groups/ 附加能力的池組合（第 4.15 節）
  quests/             任務（第 4.16 節，M8）
  npcs/               NPC 和對話（第 4.17 節，M8；概念圖已經有冒險公會服務員）
```

- 顯示文字不在 `data/` 裡，放在 `locale/<語系>/`（第 7 節）。
- `data/` 不加 `.gdignore`，而且要打包進客戶端和伺服器的匯出版本（M9 的匯出測試會確認）。
- 程式只讀不寫（01 第 10 節：資料載入後唯讀）。要改資料就改 JSON，再重新啟動。

### 4.2 載入流程

```text
啟動（01 第 5.2 節第 2 步）

  讀取所有 JSON → 掃描重複的鍵 → 依定義類別檢查每個項目 → 檢查交叉參照 → 換算重量和機率 → 建立唯讀物件和索引
                  └──────────── 錯誤都先收集起來，最後一次列出；有錯誤就拒絕啟動 ────────────┘
```

- 錯誤訊息指出檔案和行號（解析錯誤），或項目 ID 和欄位名稱（驗證錯誤）。
- 交叉參照的例子：職業技能樹裡的技能、怪物掉落的物品和附加能力的池、怪物用的行為組合和感知組合、物品可以裝備的職業、地圖標記指向的地圖和生成表、生成表指向的怪物、任務指向的 NPC、怪物、物品、技能、NPC 對話指向的任務。
- 載入後由 GameData（01 第 9.1 節的 autoload）提供查詢，伺服器和客戶端讀的是同一份資料。
- 效能：
  - 每種資料建好兩種查詢：用 ID 找、用 u16 索引找。
  - 屬性表、體型修正表攤平成陣列，用列舉的順序直接查，不用字典。
  - 重量和機率的整數轉換、每級數值展開都在載入時做完，執行中不再換算。
- 動作檢視器（05、07）也讀這份資料，所以新增的職業、武器、怪物會自動出現在檢視器裡。
- 「開始」欄是該欄位第一次被用到的里程碑，以 11 為準。定義類別跟著系統一起長：M0 只驗證第一版用得到的欄位，M5 起再加上戰鬥欄位（01 第 16 節：資料表「持續擴充」）。

### 4.3 職業（`data/jobs/`）

| 欄位 | 內容 | RO 對應（rAthena） | 開始 |
|---|---|---|---|
| id | `novice`、`swordsman`、`thief`、`acolyte`（顯示名稱在 `locale` 的 `job.<id>.name`：初心者、劍士、盜賊、服事） | Job | M0 |
| tier | novice、first（之後有 second…） | — | M0 |
| base_job | 從哪個職業轉職而來（劍士是 novice），技能樹也從它繼承 | skill_tree 的 Inherit | M0 |
| visual_ids | 依性別的服裝外觀：`female` 必填；`male` 依 00-S03 預留，可以先不填 | — | M0 |
| max_base_level、max_job_level | Base 99；Job 初心者 10、一轉 50 | MaxBaseLevel、MaxJobLevel | M5 |
| base_exp_table、job_exp_table | 用哪一張經驗表 | BaseExp、JobExp | M5 |
| hp_sp_table | 用哪一張基礎 HP/SP 表 | BaseHp、BaseSp | M5 |
| base_aspd | 各武器種類的基礎 ASPD，另有 `shield`（拿盾牌時的修正） | BaseASPD | M5 |
| job_bonus_stats | 職業等級的素質加成：`[{job_level, stat, amount}]` | BonusStats | M5 |
| change_job | 轉職條件（例如 Job 10、基本技能 9 級），06 定 | — | M5 |
| max_weight | 基本負重（顯示的值，例如 2800） | MaxWeight（RO 寫成 28000） | M6 |
| skill_tree | `[{skill, max_level, job_level, requires: [{skill, level}]}]` | Tree | M7 |

- 能不能裝備某件物品，跟 RO 一樣由物品的 `jobs` 決定。驗證時檢查：物品允許的職業，都有那個武器種類的基礎 ASPD。

### 4.4 技能（`data/skills/`）

| 欄位 | 內容 | RO 對應 |
|---|---|---|
| id | 描述性的英文，例如 `bash`、`double_attack`、`heal`（顯示名稱和說明在 `locale` 的 `skill.<id>.name`、`.desc`，中文預設沿用 RO 的中文技能名） | Name（例如 `SM_BASH`，記在 ro_ref） |
| max_level | 最大等級 | MaxLevel |
| target | 技能目標（第 3.5 節） | TargetType |
| attack_type | none、weapon、magic、misc | Type |
| range_m | 射程（每級，邊緣到邊緣，06）。寫 `"weapon"` 表示用武器的射程 | Range（RO 用負數表示用武器射程；1 格 ＝ 1 m） |
| hits | 段數（每級） | HitCount |
| damage_display | split 或 total | Hit，以及 HitCount 的正負號 |
| element | 屬性（每級）；`weapon` 表示用武器的屬性 | Element |
| area | 範圍的形狀（每級）：`{"shape": "circle", "radius_m": 2.5}`、`{"shape": "cone", "radius_m": 5, "angle_deg": 90}`、`{"shape": "line", "length_m": 8, "width_m": 2}`、`{"shape": "square", "half_size_m": 2}` | SplashArea（RO 的方形範圍半徑 k 格 → 半徑 k＋0.5 m 的圓，06 第 3 節） |
| knockback_m | 擊退距離（每級）：沿著攻擊方向推，貼著導航網格滑動 | Knockback |
| variable_cast_ms、fixed_cast_ms | 變動詠唱、固定詠唱（每級） | CastTime、FixedCastTime |
| cast_interruptible | 被打時會不會中斷詠唱 | CastCancel |
| cast_def_reduction_pct | 詠唱時 DEF 降低多少 | CastDefenseReduction |
| after_cast_delay_ms | 技能後延遲（每級） | AfterCastActDelay |
| after_cast_move_delay_ms | 施放後多久不能移動（每級） | AfterCastWalkDelay |
| cooldown_ms | 冷卻（每級） | Cooldown |
| duration_ms | 主要的持續時間（每級） | Duration1 |
| requires | sp_cost、hp_cost（每級）、weapon_types、statuses、items | Requires |
| flags | 有名字的性質旗標（清單由 06 定），例如 `quest_skill`（要用任務學，例如緊急治療、裝死，第 4.16 節） | Flags、DamageFlags、CastTimeFlags、CastDelayFlags |
| status | 這個技能造成的狀態效果 | Status |
| params | 這個技能自己的數值（每級），名稱要看得懂，例如 `damage_pct`、`chance_pct`、`stun_duration_ms` | RO 的 Duration2 這類通用欄位，或寫在程式裡的數值 |
| visual_id | 施放和命中的特效（10） | — |

- 技能「做什麼」跟 RO 一樣寫在程式裡，依技能 ID 對應處理方式；資料只放數值。這樣不用另外發明一套技能腳本語言。
- 開始：M5～M7，依 11 的安排（例如二連擊屬於普攻，可能在 M5 就要用到）。

### 4.5 怪物（`data/monsters/`）

| 欄位 | 內容 | RO 對應 | 開始 |
|---|---|---|---|
| id | 英文，例如 `gelly`（顯示名稱在 `locale` 的 `monster.<id>.name`：果凍怪）。用概念圖的英文名稱 | AegisName | M4 |
| visual_id | 外觀 | — | M4 |
| move_speed_mps | 移動速度（檢視器播放移動動作時也用它） | WalkSpeed（毫秒／格，換算見 06 第 3 節） | M4 |
| body_radius_m、height_m | 身體半徑和身高：距離用邊緣到邊緣算、點選範圍、名牌高度（06、09） | 沒有（RO 只有體型列舉） | M4 |
| level、hp、sp | | Level、Hp、Sp | M5 |
| base_exp、job_exp | | BaseExp、JobExp | M5 |
| atk、matk | Renewal 的基礎 ATK、MATK | Attack、Attack2 | M5 |
| def、mdef | | Defense、MagicDefense | M5 |
| stats | `{str, agi, vit, int, dex, luk}` | Str～Luk | M5 |
| size、race、element、element_level | 第 3.5 節的列舉（體型是戰鬥規則，跟實際的身體大小分開） | Size、Race、Element、ElementLevel | M5 |
| attack_range_m、skill_range_m、chase_range_m | 攻擊距離、技能距離（也是視野）、追擊距離 | AttackRange、SkillRange、ChaseRange（格 → 公尺） | M5 |
| attack_interval_ms | 攻擊間隔 | AttackDelay | M5 |
| attack_hit_ms | 從揮擊開始到傷害生效的時間（03-D11） | ClientAttackMotion 的值 | M5 |
| attack_lock_ms | 揮擊後多久不能移動 | AttackMotion | M5 |
| hit_stun_ms | 受擊硬直：被打之後多久不能移動 | DamageMotion | M5 |
| rank | normal、boss、mvp | Class、MVP 旗標 | M5 |
| behavior | 行為組合的 ID（第 4.6 節） | Ai | M6 |
| behavior_overrides | 對行為組合的個別調整，例如 `{"looter": false}` | Modes | M6 |
| perception、perception_overrides | 感知組合的 ID（第 4.14 節）和個別調整 | 沒有（RO 只有視野距離） | M6 |
| drops | `[{item, chance_pct, steal_protected, random_option_group}]`，不限數量；`random_option_group` 沒寫時依物品種類用預設的池，寫 `none` 關掉（第 4.15 節） | Drops（RO 最多 10 種；RandomOptionGroup） | M6 |
| mvp_exp、mvp_drops | MVP 用 | MvpExp、MvpDrops | 之後 |

- `attack_hit_ms` 用 RO 的 ClientAttackMotion 的值，因為那是 RO 玩家看到傷害數字出現的時間，手感才會一樣。這幾個時間的實際用法由 06、07 定。
- 怪物在哪裡生成、幾隻、多久重生，寫在生成表（第 4.13 節），不寫在怪物資料裡。

範例（數值取自 rAthena 的 Renewal 資料，只是示意；正式的數值由 07 決定）：

```text
{
  "id": "gelly",
  "ro_ref": "PORING (1002)",
  "visual_id": "gelly",
  "move_speed_mps": 2.5,
  "body_radius_m": 0.25,
  "height_m": 0.5,
  "level": 1,
  "hp": 55,
  "base_exp": 150,
  "job_exp": 40,
  "size": "medium",
  "race": "plant",
  "element": "water",
  "element_level": 1,
  "attack_range_m": 1,
  "attack_interval_ms": 1872,
  "attack_hit_ms": 288,
  "attack_lock_ms": 672,
  "hit_stun_ms": 480,
  "rank": "normal",
  "behavior": "passive_looter",
  "perception": "gelly",
  "drops": [
    { "item": "example_item", "chance_pct": 70 },
    { "item": "example_dagger", "chance_pct": 0.5, "random_option_group": "weapon_physical" }
  ]
}
```

### 4.6 怪物的行為組合（`data/monster_behaviors/`）

| 欄位 | 內容 | RO 對應 |
|---|---|---|
| id | 例如 `passive`、`passive_looter`、`aggressive_immobile`（不是玩家看得到的名稱，說明寫在 `note`） | — |
| flags | 行為旗標清單，名稱照 RO 的行為，例如 `can_move`、`can_attack`、`looter`、`aggressive`、`assist`、`change_target_melee`、`detector`、`cast_sensor_idle`、`cast_sensor_chase` | Modes 的各個位元 |
| ro_ref | 對應的 RO AI 類型，例如 `AI 02` | Ai |

- 第一版會用到哪些組合由 07 定。RO 的每個 AI 類型都可以換成一組同樣的旗標，所以行為跟 RO 一樣。

### 4.7 物品（`data/items/`）

**共通欄位**

| 欄位 | 內容 | RO 對應 |
|---|---|---|
| id | 英文（顯示名稱和說明在 `locale` 的 `item.<id>.name`、`.desc`） | AegisName |
| type | 物品類型（第 3.5 節） | Type |
| buy、sell | 價格（zeny） | Buy、Sell |
| weight | 遊戲裡顯示的重量（最多 1 位小數） | Weight（RO 用 10 代表 1） |
| visual_id | 裝備時和掉在地上的外觀 | View |

**裝備（armor、weapon）**

| 欄位 | 內容 | RO 對應 |
|---|---|---|
| jobs | 可以裝備的職業 | Jobs |
| gender | both、female、male | Gender |
| locations | 佔用的裝備位置，可以多格：全罩頭盔是 `["head_top", "head_mid"]`，雙手武器是 `["weapon", "shield"]` | Locations |
| equip_level_min、equip_level_max | 裝備等級限制 | EquipLevelMin、EquipLevelMax |
| defense | 防具的 DEF（硬 DEF） | Defense |
| slots | 卡片插槽數 0～4 | Slots |
| refineable | 能不能精煉 | Refineable |
| armor_level | 防具等級（Renewal 精煉用） | ArmorLevel |
| bonuses | 裝備效果，用效果類型（03-D25）：`[{"effect": "stat_add", "stat": "str", "value": 2}, {"effect": "atk_add", "value": 10, "when": {"refine_at_least": 7}}]`；效果類型的清單由 06 定 | Script（RO 用 bonus 腳本，記在 `ro_ref`） |
| random_option_group | 掉落時用哪一個附加能力的池（M6）；沒寫時依種類用預設的池（武器、鎧甲、披肩、鞋子），盾牌、頭飾、飾品目前沒有（第 4.15 節） | 掉落的 RandomOptionGroup |

**武器另外有**

| 欄位 | 內容 | RO 對應 |
|---|---|---|
| weapon_type | 武器種類 | SubType |
| weapon_level | 武器等級 | WeaponLevel |
| atk | 武器 ATK | Attack |
| matk | 武器 MATK（Renewal） | MagicAttack |
| range_m | 攻擊距離（邊緣到邊緣） | Range（1 格 ＝ 1 m） |

**消耗品**：`use_effect` 寫用法和效果，例如回復 HP 的範圍、要不要先選目標。RO 用 Healing、Usable、DelayConsume 三種類型區分的規則，都寫在這裡。細節在 M6 依 06 定。

- 開始：M3 先用到武器、盾牌、頭飾的 id、type、jobs、gender、locations、weapon_type、visual_id（給裝備外顯和檢視器）；數值欄位從 M5、M6 開始。
- 頭飾「佔哪幾格」是規則（佔了上段和中段，就不能再戴中段頭飾），放在 JSON；「頭髮怎麼顯示」是表現，放在 `.tres`（第 5 節）。

### 4.8 狀態效果（`data/status_effects/`）

| 欄位 | 內容 | RO 對應 |
|---|---|---|
| id | 英文（顯示名稱和說明在 `locale` 的 `status.<id>.name`、`.desc`） | Status |
| visual_id | 狀態圖示和身上的特效（10） | Icon、Opt |
| states | 會限制什麼：no_move、no_cast、no_attack… | States |
| flags | 有名字的性質，例如 debuff、keep_on_death、keep_on_logout、boss_immune（清單由 06 定） | Flags（RO 叫 NoRemoveOnDead、NoSave 等） |
| removes_on_start | 開始時會解除哪些狀態 | EndOnStart |
| blocked_by | 已經有哪些狀態時，這個狀態上不去 | Fail |
| min_duration_ms | 被抗性減免後的最短時間 | MinDuration |

- 跟技能一樣，狀態「做什麼」寫在程式裡，資料只放性質和數值。
- 開始：M5（02 的 StatusChange 從 M5 開始）。

### 4.9 數值表（`data/tables/`）

| 檔案 | 內容 | RO 對應 | 開始 |
|---|---|---|---|
| exp_tables.json | 經驗表，每個項目是一張表（例如 `base_normal`、`job_novice`、`job_first`），列出每一級升到下一級要的經驗值 | job_exp.yml | M5 |
| hp_sp_tables.json | 每個職業群組各等級的基礎 HP、SP | job_basepoints.yml | M5 |
| stat_points.json | 到每個 Base 等級為止累計的素質點數（1 級 48 點） | statpoint.yml | M5 |
| element.json | 屬性表：屬性等級 1～4 × 攻擊屬性 10 種 × 防禦屬性 10 種，值是百分率（−100～200） | attr_fix.yml | M5 |
| size_modifiers.json | 武器種類 × 體型的修正百分率，沒寫的是 100 | size_fix.yml | M5 |
| level_penalty.json | 依「怪物等級 − 玩家等級」調整經驗和掉落率的表（Renewal） | level_penalty.yml | M5 |

### 4.10 全域規則（`data/rules/`）

只有一個項目 `default`：

| 欄位 | 內容 | 由誰決定 | 開始 |
|---|---|---|---|
| start_map、start_point | 新角色出生的地圖和抵達點（大教堂廣場的雅典娜神像旁，08） | 08 | M0 |
| character_name_length | 角色名稱的字數範圍 `[2, 16]`（03-D19） | 本文件 | M0 |
| player_move_speed_mps | 玩家預設移動速度 6.67（RO 是 150 毫秒／格） | 06、09 | M1 |
| arrival_protection_ms | 換圖後的保護時間 3000 | 02 已定 | M1 |
| new_character | 新角色的職業和預設外觀：job、gender、hair_style、hair_color、eye_color（novice、female、hair_twin_tails、auburn、brown），每一項都要是資料表裡的 ID | 05 第 10.3 節 | M0 |
| sight_grid_cell_m | 視線格網的格子大小 0.5 | 07、08 | M1 |
| default_save_map、default_save_point | 預設儲存點（死亡後復活的地方，雅典娜神像旁） | 06、08 | M5 |
| player_body_radius_m | 玩家的身體半徑 0.4（跟導航網格一樣） | 06 | M5 |
| attack_height_limit_m | 攻擊和技能時雙方的高度差上限 3 | 06 | M5 |
| moving_target_range_bonus_m | 目標移動中時射程多 1（RO 的 1 格） | 02、06 | M5 |
| logout_block_ms | 戰鬥後不能登出的時間 10000 | 02 已定 | M9 |
| max_aspd | ASPD 上限 190（一轉、二轉） | 06 | M5 |
| player_hit_pct | 玩家的命中時間在 amotion 的位置，100 表示 amotion 結束時 | 06 | M5 |
| heal_block_weight_pct、major_overweight_pct | 負重 70% 以上不自然回復；90% 以上不能攻擊和使用技能 | 06 | M6 |
| death_penalty_per_10000 | 死亡時失去目前等級所需經驗的比例，100 就是 1% | 06 | M5 |
| respawn_hp、respawn_sp | 回到儲存點時的 HP、SP，各 1 | 06 | M5 |
| loot_priority_ms | 撿取優先權的三段時間：3000、2000、2000 | 06 | M6 |
| ground_item_lifetime_ms | 掉落物在地上的時間 60000 | 06 | M6 |
| pickup_range_m | 撿東西的距離 1.5（角色邊緣到物品） | 06 | M6 |
| noise_run_pct、noise_walk_pct、noise_still_pct、noise_sit_pct | 玩家發出的噪音（乘在怪物的聽覺距離上）：100、20、0、0 | 07 | M6 |
| noise_combat_pct、noise_combat_ms | 戰鬥中的噪音和持續時間：125、2000 | 07 | M6 |
| perception_height_limit_m | 怪物感知的高度差上限 3 | 07 | M6 |
| assist_range_m | 協助同伴的距離 11（rAthena 的 assist_range） | 07 | M6 |
| loot_range_m | 撿東西的怪物找物品的距離 12（rAthena 的 loot_range） | 07 | M6 |

- 2026-10-11 拿掉 `cell_size_m`（資料不再存格數，03-D05），`player_walk_ms_per_cell` 改成 `player_move_speed_mps`。

### 4.11 外觀選項（`data/appearance/`）

| 種類 | 內容 | 第一版 |
|---|---|---|
| hair_style | 髮型：id、依性別的 visual_id | 4 種（05 第 10.3 節） |
| hair_color | 髮色：id（顏色值在客戶端的 `.tres`） | 4 種（05 第 10.3 節） |
| eye_color | 瞳色：id（顏色值在客戶端的 `.tres`） | 2 種（05 第 10.3 節） |
| face_shape | 臉型 blendshape 的名稱（`face_` 開頭，05 第 10.1 節） | 清單先空著 |

- 外觀自訂畫面之後才做（00-A10），但存檔裡的外觀欄位從第一版起就指向這裡的 ID。
- 每一種各自一張表：hair_styles、hair_colors、eye_colors、face_shapes（第 3.1 節的例外）。顯示文字的鍵是 `hair_style.<id>.name`、`hair_color.<id>.name`、`eye_color.<id>.name`。

### 4.12 地圖定義（`data/maps/`）

| 欄位 | 內容 | RO 對應 | 開始 |
|---|---|---|---|
| id | `kronenberg`、`kronenberg_south_field`（顯示名稱在 `locale` 的 `map.<id>.name`：克羅能堡、克羅能堡南方草原；換圖畫面的副標 `map.<id>.subtitle`，例如「王都」） | 地圖名稱 | M0 |
| type | town、field（之後有 dungeon…） | — | M0 |
| flags | 地圖旗標。只定義用得到的，名稱自己取；第一版只有 `town` | mapflag（RO 有幾十種） | M1 |
| interest_radius_m | 可視半徑；沒寫就用 50（02 第 9 節） | — | M1 |
| max_players_per_instance | 每份分流的人數上限（02 第 13.5 節），城鎮可以高一點 | — | M11 |

- 場景路徑照固定規則 `maps/<id>/map.tscn`、`maps/<id>/logic.tscn`（01 第 7.3 節），不寫在資料裡。
- 背景音樂和環境音是表現，放在客戶端的 `map.tscn`（10），不寫在資料裡。
- 有 `town` 旗標的地圖整張都是安全區（第 6.2 節）。
- 之後新增地圖的命名規則：
  - 野外：`<地區>_<方位>_field`；同一個方位有好幾張時，第二張起加兩位數序號，例如 `kronenberg_south_field_02`。
  - 地城：`<名稱>_dungeon_<兩位數樓層>`，例如 `<名稱>_dungeon_01`。

### 4.13 生成表（`data/spawns/`）

一張地圖一個檔（`data/spawns/<地圖 ID>.json`，表名 `spawns`）。生成的內容在這裡，位置在 logic 場景的 MonsterSpawnArea 標記（第 6.2 節）。

| 欄位 | 內容 | RO 對應 | 開始 |
|---|---|---|---|
| id | 生成表的 ID（`spawn_id`），全部地圖裡不重複，建議 `<地圖>_<名稱>`，例如 `south_field_gelly_all` | — | M6 |
| map | 地圖 ID | 腳本所在的地圖 | M6 |
| area | `whole_map`（整張地圖的導航網格上隨機）或 `marker`（用同 `spawn_id` 的標記的範圍） | 座標寫 0 表示整張地圖 | M6 |
| monster | 怪物 ID | 怪物 | M6 |
| amount | 數量 | 數量 | M6 |
| respawn_base_ms、respawn_variance_ms | 基本重生時間、往上加的隨機時間 | delay1、delay2 | M6 |

- 驗證：`area` 是 `marker` 的項目，地圖上剛好有一個同 `spawn_id` 的標記；標記的 `spawn_id` 一定存在於生成表；`map` 跟標記所在的地圖一致。
- 調數量、重生時間只改這個檔，不用開場景；也算進資料雜湊。

### 4.14 感知組合（`data/perception_profiles/`）

怪物的視覺、聽覺、貼身察覺（07）。像行為組合一樣可以共用，怪物用 `perception_overrides` 個別調整。

| 欄位 | 內容 | 建議預設 | RO 對應 |
|---|---|---|---|
| id | 例如 `gelly`、`default` | — | — |
| sight_range_m | 視覺距離 | 10（RO 的視野 SkillRange） | SkillRange（全方向） |
| sight_angle_deg | 視野扇形的角度（左右合計） | 120 | 沒有 |
| hearing_range_m | 聽覺距離（玩家跑步時） | 7 | 沒有 |
| proximity_range_m | 貼身距離 | 2 | 沒有 |
| hearing_wall_pct | 隔著牆時，聽覺距離剩多少 | 50 | 沒有 |
| reaction_ms | 察覺到之後多久開始行動 | 0 | 沒有（RO 是下一次思考就行動） |
| alert_ms | 警戒（只聽到、沒看到）最多多久 | 4000 | 沒有 |
| memory_ms | 追擊中失去感知後，還會往最後的位置追多久 | 3000 | 接近 rAthena 失去目標後還會走一段 |
| idle_look_interval_ms | 閒晃時轉頭看四周的間隔 `[最短, 最長]` | `[5000, 10000]` | 沒有 |

- 詠唱感知、看得到隱匿（`cast_sensor_idle`、`cast_sensor_chase`、`detector`）是行為旗標（第 4.6 節），照對應的 RO 怪物。
- 視線檢查用地圖的視線格網（第 6.3 節）。

### 4.15 附加能力（`data/random_options/`、`data/random_option_groups/`）

RO 官方的隨機選項制度（rAthena 的 `item_randomopt_db`、`item_randomopt_group`），條數和機率照你的規則（06）。

**每一種能力（`random_options`）：**

| 欄位 | 內容 | RO 對應 |
|---|---|---|
| id | 例如 `atk_add`、`max_hp_add`、`phys_damage_vs_element_rate` | — |
| effect | 效果類型（03-D25） | 選項對應的裝備效果 |
| （固定參數） | 例如 `stat`、`element`、`race` | — |
| ro_ref | 例如 `VAR_ATKAMOUNT` | 選項的名稱 |

**池組合（`random_option_groups`）：**

| 欄位 | 內容 |
|---|---|
| id | `weapon_physical`、`weapon_magic`、`armor_body`、`armor_garment`、`armor_shoes` |
| lines | 三條，依序是第 1、2、3 條：`{chance_pct, options: [{option, min, max, weight}]}`。第 1 條 100、第 2 條 70、第 3 條 30；**第 2 條起，前一條有出才擲** |
| ro_ref | 參考的池，例如 `Weapon_ATK4 (Ragnarok Zero)` |

```text
{
  "id": "weapon_physical",
  "lines": [
    { "chance_pct": 100, "options": [ { "option": "atk_add", "min": 5, "max": 30 }, { "option": "atk_rate", "min": 1, "max": 5 } ] },
    { "chance_pct": 70,  "options": [ … ] },
    { "chance_pct": 30,  "options": [ … ] }
  ]
}
```

- 每條從那一條的清單裡挑一個（依 `weight`，沒寫就是 1），數值在最小～最大之間平均隨機的整數。不同條可以是同一種能力，分開顯示、效果相加。
- 掉落的那一刻在伺服器用地圖實例的亂數決定（01-D17）；地上的物品已經帶著附加能力。
- 哪些裝備有：怪物掉落的武器、鎧甲、披肩、鞋子；盾牌、頭飾、飾品、商店的裝備沒有（飾品之後再加池）。
- 物品實例存 `random_options: [{option, value}]`（最多 3 條，依第 1、2、3 條的順序，第 8.3 節）；網路上用 u16 索引＋數值。
- 名稱的顏色由條數決定，不存資料：0 條白色、1 條綠色、2 條藍色、3 條紫色（10）。

### 4.16 任務（`data/quests/`，M8）

| 欄位 | 內容 |
|---|---|
| id | 例如 `guild_registration`、`hunt_gelly`、`learn_first_aid`（顯示文字在 `locale` 的 `quest.<id>.name`、`.desc`、`.step.<序號>`） |
| giver | 給任務的 NPC 種類（第 4.17 節） |
| requires | 接任務的條件，「任一組成立就可以接」：`[{job, job_level_min, base_level_min, quests_done, skills}]` |
| steps | 依序完成的步驟：`talk`（`npc`）、`kill`（`monster`、`count`、選填 `map`）、`collect`（`item`、`count`，交出時扣掉）、`deliver`（`npc`、`item`） |
| rewards | `{base_exp, job_exp, zeny, items: [{item, amount}], skills: [{id, level}]}` |
| repeatable、repeat_cooldown_ms | 可不可以重複接；第一批都不可以 |
| ro_ref | 參考的 RO 任務或腳本，例如 `npc/quests/skills/novice_skills.txt (First Aid)` |

```text
{
  "id": "learn_first_aid",
  "giver": "adventurer_guild_staff",
  "requires": [ { "job": "novice", "job_level_min": 4 }, { "job": "novice", "base_level_min": 12 } ],
  "steps": [ { "type": "collect", "item": "healing_herb", "count": 3 }, { "type": "collect", "item": "lucky_clover", "count": 3 } ],
  "rewards": { "skills": [ { "id": "first_aid", "level": 1 } ] },
  "repeatable": false,
  "ro_ref": "npc/quests/skills/novice_skills.txt (First Aid)"
}
```

- 物品 ID 只是例子，M6 定掉落時再決定，不用 RO 的名稱（00-A02）。
- 進度存在角色檔的 `quests`（第 8.3 節）；討伐由打倒怪物的玩家計數。

### 4.17 NPC（`data/npcs/`，M8）

| 欄位 | 內容 |
|---|---|
| id | NPC 的種類，例如 `adventurer_guild_staff`（冒險公會的服務員，組織名稱「卡德威爾」）、`training_instructor`（訓練營地的教官，先用服務員的模型）；顯示名稱在 `locale` 的 `npc.<id>.name` |
| visual_id | 外觀 |
| body_radius_m、height_m | 點選範圍、名牌高度 |
| interact_range_m | 對話距離 2（走到這個距離內才打開對話） |
| services | 提供的服務：`quests`；之後 `save_point`、`storage`（像 RO 的卡普拉） |
| dialog | 對話節點：`[{id, choices: [{next 或 action, when}]}]`；文字在 `locale` 的 `dialog.<npc>.<節點>`、`dialog.<npc>.<節點>.choice.<序號>` |

- 對話的動作只有固定幾種：`accept_quest`、`complete_quest`（發獎勵，包含學任務技能）、`give_item`、`close`；之後加 `set_save_point`、`open_storage`。條件（`when`）可以看任務狀態、職業、等級。
- 同一種 NPC 可以擺在好幾個地方（第 6.2 節的 NpcSpot），例如服務員在雅典娜神像旁和南門內側各一位。

---

## 5. 邏輯資料和表現資料分開

```text
data/items/weapons.json（伺服器和客戶端都讀）     assets/equipment/knife/（只有客戶端讀）
  { "id": "knife",                                 knife.visual.tres
    "visual_id": "knife", ... }  ── visual_id ──►    ├─ 模型場景（knife.glb）
                                                      ├─ 掛點：右手骨骼，加上位置、旋轉、縮放偏移
                                                      └─ 武器拖尾的起點和終點（10）
```

| 資料種類 | 外觀設定的位置 | 主要內容（細節在） |
|---|---|---|
| 職業服裝（依性別） | `assets/characters/<visual_id>/` | Body 網格、骨架設定、動作庫（05） |
| 頭、髮型 | `assets/characters/<visual_id>/` | 網格、blendshape、髮色和瞳色的顏色值（05） |
| 武器、盾牌、頭飾 | `assets/equipment/<visual_id>/` | 模型、掛點和偏移（可以依性別覆寫）、頭飾的頭髮顯示模式（05） |
| 怪物 | `assets/monsters/<visual_id>/` | 模型、程序化動畫參數、點選範圍、名牌高度（07） |
| 技能和狀態的特效 | `assets/vfx/<visual_id>/` | 特效場景（10） |
| NPC | `assets/characters/<visual_id>/` | 模型、動作（05、10） |

- 檔名規則：`assets/<類別>/<visual_id>/<visual_id>.visual.tres`。04 細定 `assets/` 的結構時如果要調整，會在 04 提出。
- 多個項目可以共用一個 visual_id，例如有插槽和沒插槽的同一款武器（RO 的 View 也是這樣用）。
- 美術還沒做好時，資料先指向佔位外觀（例如 `placeholder_weapon`、`placeholder_monster`，M0 建好）。客戶端的資料測試一律嚴格檢查「每個 visual_id 都找得到 `.tres`」。
- 伺服器只把 visual_id 當作索引轉送（例如其他玩家的裝備外顯，02 的 EntityAppear），從不載入 `.tres`。01 第 4.3 節的守門測試保證 server 和 shared 不會引用外觀設定。
- 載入時機（效能）：客戶端第一次用到某個 visual_id 才載入，之後放在快取；換圖時，在背景先載入新地圖會用到的外觀，淡入後才不會卡頓。
- 執行中真的找不到外觀時（測試應該已經擋下），客戶端顯示佔位外觀並記錄錯誤，不會當掉。

---

## 6. 地圖標記

### 6.1 座標和角度

```text
              北（−Z）
                ▲
                │
   西（−X） ◄───┼───► 東（+X）          Y 軸朝上；1 單位 ＝ 1 公尺
                │
                ▼
              南（+Z）

面向：0° 朝北、90° 朝西、180° 朝南、270° 朝東（從上往下看是逆時針）
```

- 這就是 Godot 節點的 Y 軸旋轉角度，資料和存檔裡的角度可以直接套到節點上，不用換算。
- RO 的方向編號也是從北開始逆時針（0 北、1 西北、2 西…），兩者一致。
- 網路上的角度用 u16（02 第 4.1 節）：u16 值 ＝ 角度 ÷ 360 × 65536。

### 6.2 標記種類

標記是 logic 場景（`maps/<id>/logic.tscn`）裡的節點，腳本放在 shared，沒有任何視覺依賴。位置和面向就是節點的位置和旋轉，其他參數用匯出屬性在檢查器裡設定。

| 標記 | 參數 | 用途 | RO 對應 | 開始 |
|---|---|---|---|---|
| SpawnPoint（抵達點） | point_id（同一張地圖裡不重複） | 新角色出生、傳送抵達、預設儲存點、除錯傳送 | warp 目的地的座標、儲存點 | M1 |
| Warp（傳送點） | 觸發範圍（長方體，公尺）、目標地圖、目標抵達點、`open`（預設 true） | 走進範圍就換圖（02 第 11 節）；`open` 是 false 時不換圖，只顯示「這條路還沒開放」，目標可以留空或先寫預定的地圖 ID | warp 腳本（觸發範圍和目的地）；RO 沒有「不能過的傳點」 | M1 |
| SafeZone（安全區） | 範圍（長方體或圓柱，公尺） | 範圍內不能攻擊（02 第 10 節） | — | M1 |
| MonsterSpawnArea（怪物生成區） | 範圍（長方體或圓柱）、`spawn_id`（內容在生成表，第 4.13 節）；整張地圖的生成不用擺標記 | 生成和重生（07） | monster 腳本：數量、delay1、delay2；座標寫 0 表示整張地圖隨機 | M6 |
| NpcSpot（NPC 位置） | NPC 種類（第 4.17 節）、`spot_id`（同一張地圖裡不重複）；面向就是節點的旋轉 | 放置 NPC | NPC 腳本的位置和方向 | M8 |

另外，客戶端的完整場景（`map.tscn`）裡有「觀測點」標記，給自動截圖使用（01 第 11.3 節）。伺服器不讀，細節在 08。

規則（載入地圖時驗證，M1 起測試涵蓋所有地圖）：
- 傳送點只寫「目標地圖＋目標抵達點」，抵達的位置和面向由抵達點決定。`open` 是 false 的傳點不檢查目標。
- 抵達點不能落在目標地圖任何傳送點的觸發範圍裡，不然一抵達就又被傳走。
- 抵達點、生成區、NPC 位置都要在導航網格上（離網格 0.5 m 以內）。
- 生成區的 `spawn_id` 一定存在於生成表，而且地圖一致（第 4.13 節）。
- 有 `town` 旗標的地圖整張是安全區，不用另外擺 SafeZone。

### 6.3 伺服器怎麼讀

- 伺服器把 logic 場景實例化後，只讀出標記資料（位置、面向、參數）和導航網格，接著就釋放節點。節點不加進場景樹，所以不會建立任何渲染或物理物件（01-D07）。
- 客戶端的 `map.tscn` 本來就包含 logic 場景，所以客戶端看得到同樣的標記：傳送點用來顯示傳送門特效，除錯模式可以顯示各種範圍。
- 讀出來的標記資料和導航網格也算進資料雜湊（02 第 4.3 節，第 15.1 節）。
- **視線格網**（`maps/<id>/sight_grid.res`）：每張地圖一張 2D 格網（0.5 m 一格，`sight_grid_cell_m`），標記擋住視線的格子（建築、城牆、大石頭、樹幹），給怪物的視覺和之後遠程攻擊的視線檢查用（07）。白模階段由 `tools/maps/build_whitebox.gd` 一起產生，換成正式素材後從 logic 場景的障礙重新烘焙（08）。伺服器載入；也算進資料雜湊。

### 6.4 存檔位置無效時

| 情況 | 處理 |
|---|---|
| 存的座標離導航網格 2 m 以內 | 移到網格上最近的點。RO 是格子地圖，沒有這種情況；連續移動難免有小誤差（例如重新烘焙過導航網格） |
| 更遠（例如地圖改過） | 照 RO：移到同一張地圖上隨機一個可以走的位置，不會落在傳送點的範圍裡；記錄警告 |
| 地圖已經不存在 | 照 RO（rAthena 會送到王都的固定地點）：移到預設儲存點，記錄警告 |

---

## 7. 顯示文字（多語言）

資料裡沒有任何顯示文字（03-D02）。所有語言的文字都放在 `locale/`，每種語言一個資料夾，地位相同（00-S06）。

```text
locale/                 只有客戶端讀；不在 data/ 裡，也不算進資料雜湊
  locales.json          語言清單
  zh_TW/                繁體中文（預設）
    names.json          資料項目的名稱和說明（職業、技能、物品、怪物、地圖、狀態、NPC、任務、附加能力）
    ui.json             介面文字
    messages.json       系統訊息
    enums.json          列舉的名稱
    dialogs.json        NPC 對話（M8）
  en/                   英文：同樣的檔案
  （之後）ja/、ko/、zh_CN/…：同樣的檔案，可以不完整
```

`locales.json`：

```text
{
  "table": "locales",
  "entries": [
    { "id": "zh_TW", "native_name": "繁體中文", "fallback": "en", "required": true,  "font": "noto_sans_tc" },
    { "id": "en",    "native_name": "English",  "fallback": "",   "required": true,  "font": "noto_sans_tc" }
  ]
}
```

| 文字的種類 | 鍵的格式 | 例子（英文 → 繁中） |
|---|---|---|
| 資料項目的名稱 | `<種類>.<id>.name` | `job.swordsman.name`：Swordsman → 劍士 |
| 資料項目的說明 | `<種類>.<id>.desc` | `item.knife.desc` |
| 列舉 | `enum.<列舉>.<值>` | `enum.element.fire`：Fire → 火 |
| 介面 | `ui.<畫面>.<項目>` | `ui.hud.hp`：HP → HP |
| 系統訊息 | `msg.<類別>.<名稱>` | `msg.login.wrong_password`：Wrong account or password. → 帳號或密碼錯誤。 |
| 任務 | `quest.<id>.name`、`.desc`、`.step.<序號>` | `quest.hunt_gelly.name`：Gelly Hunt → 討伐果凍怪 |
| NPC 對話 | `dialog.<npc>.<節點>`、`dialog.<npc>.<節點>.choice.<序號>` | `dialog.adventurer_guild_staff.greeting` |
| 附加能力 | `random_option.<id>.desc` | `random_option.phys_damage_vs_element_rate.desc`：對{element}屬性敵人造成的物理傷害增加 {value}% |

- 種類有 job、skill、item、monster、map、status、npc、quest、random_option、hair_style、hair_color、eye_color。地圖名稱的例子：`map.kronenberg.name` 是 Kronenberg → 克羅能堡（不中英混合；「王都」放在副標 `map.kronenberg.subtitle`）。
- 文字項目的欄位：`id`（就是鍵）、`text`；有參數的再加 `params`（參數名稱清單），參數用具名佔位，例如 `{item}`；英文有單複數的加 `plural`（用 Godot `Translation` 的 `add_plural_message`，程式用 `tr_n`）。
- 載入和切換：
  - 啟動時讀 `settings.cfg` 的 `[ui] language`（預設 zh_TW），只載入這個語言和它的退回語言。
  - 切換：載入新語言 → `TranslationServer.set_locale()` → 卸載用不到的。介面節點開了自動翻譯（`auto_translate_mode`）會自己更新；程式組出來的文字在收到 `NOTIFICATION_TRANSLATION_CHANGED` 時重組。
  - 伺服器只送訊息 ID 和參數；參數是資料 ID（例如物品）時，客戶端依目前的語言轉成名稱。訊息欄存的是「ID＋參數」，切換語言後舊訊息也用新語言顯示。
  - 字型：繁中和英文都用 Noto Sans TC；之後加日文、韓文、簡中時，清單裡指定 Noto Sans JP／KR／SC，切換時才載入。
  - 介面場景的文字直接寫鍵（例如 Label 寫 `ui.hud.hp`）；在編輯器裡看到的是鍵，執行時才顯示文字。這是預期中的。
  - 自動截圖可以用 `--lang=en` 指定語言，同一組觀測點可以中英文各截一次。
- 驗證（客戶端的測試）：

| 測試 | 內容 |
|---|---|
| 完整 | 每個資料項目和每個介面、訊息的鍵，在 `required` 的語言（zh_TW、en）都有文字；其他語言只列出完成度 |
| 參數 | 同一個鍵在各語言的參數完全一樣 |
| 不混用 | 繁中文字裡不能有英文字母，只允許白名單（`docs/glossary.md` 第 6、8 節的 RO 縮寫，例如 `STR`、`ATK`、`HP`、`BOSS`）和參數；英文文字裡不能有中文字元 |
| 伺服器的訊息 | 伺服器用到的每個訊息 ID 都存在（02 的 SystemMessage 只送 ID 和參數） |
| 寫死的文字 | 用 Godot 內建的偽本地化（pseudolocalization）跑一次自動截圖：沒有被轉換的文字就是寫死的；也順便看英文變長時版面會不會爆掉 |

- 為什麼不放在 `data/`：顯示文字只有客戶端用，伺服器只送 ID。改任何語言的文字都不用更新伺服器，也不會改到資料雜湊。
- 術語和譯名照 `docs/glossary.md`（職業、技能、素質優先用台灣版 RO 的官方譯名；地名、人名、組織名音譯或意譯擇一、整份一致；中文用全形標點、數字用半形）。
- 第一版要準備的文字（繁中和英文都要）：職業、地圖（克羅能堡、克羅能堡南方草原）、魔物（依 `ConceptArt/README.md`，例如果凍怪、毛絨蟲、小樹精）、外觀選項、基本介面文字和系統訊息（包含「這條路還沒開放」）。
- 玩家自己輸入的文字（角色名稱、之後的聊天）是玩家的內容，可以是任何語言，不受「資料沒有顯示文字」的限制。
- log 和錯誤訊息是給開發看的，一律英文（00-S06）。

---

## 8. 存檔

### 8.1 檔案位置

```text
saves/                     單機：使用者資料夾的 saves/；專用伺服器：/data/saves/（M9 之前的格式）
  accounts/<account_id>.json
  characters/<char_id>.json
  counters.json            下一個帳號 ID、下一個角色 ID
  backup/                  遷移前的舊版存檔（不會自動刪除）
```

- 每個存檔旁邊可能有同名的 `.tmp`（寫到一半的新檔）和 `.bak`（上一版），見第 8.5 節。
- 時間一律存成 UTC 的 ISO 8601 字串，例如 `2026-10-10T08:30:00Z`；剩餘時間（例如狀態效果）存毫秒數。
- 存檔裡的資料一律存 ID 字串，不存 u16 索引（索引會隨資料改變）。
- `counters.json` 不見時，用現有存檔裡最大的 ID 加 1 重建。
- **M9 之前改成 SQLite**（03-D18；單機和多人都改）：同一個 `saves/` 資料夾裡一個資料庫檔。帳號和角色各一個資料表，角色資料仍然存成 JSON（放在一個欄位裡，第 8.3、8.4 節的欄位和遷移規則照舊），名稱、帳號、地圖拉成欄位方便查詢；交易、倉庫、郵件一律在一個資料庫交易裡完成。另外提供「匯出成 JSON」的除錯工具，輸出的格式就是本節的帳號檔和角色檔。

### 8.2 帳號檔

| 欄位 | 內容 | 開始 |
|---|---|---|
| schema_version | 版本號 | M0 |
| account_id | 永久 ID（整數） | M0 |
| username | 帳號，4～23 個英數字（02 第 12.1 節）；單機是 `local` | M0 |
| created_at、last_login_at | 時間 | M0 |
| characters | 角色 ID 清單，順序就是角色選擇畫面上的位置 | M0 |
| password | `{algorithm, iterations, salt, hash}`，鹽和雜湊用 Base64（02-D18）；單機是 null | M9 |
| last_login_ip | 上次登入的 IP | M9 |
| storage | 倉庫（RO 的倉庫是同帳號共用） | 之後 |

### 8.3 角色檔

| 欄位 | 內容 | RO 對應 | 開始 |
|---|---|---|---|
| schema_version | 版本號 | — | M0 |
| char_id、account_id | 永久 ID | char_id、account_id | M0 |
| name | 角色名稱（03-D19，規則見下方） | name | M0 |
| created_at、last_saved_at | 時間 | — | M0 |
| job | 職業 ID | class | M0 |
| appearance | gender、hair_style、hair_color、eye_color、face_shapes（名稱 → 權重 0～1） | sex、hair、hair_color | M0 |
| position | map、x、y、z（公尺）、facing_deg（只存地圖 ID，不存分流的實例編號） | 上次的位置 | M0 |
| save_point | 死亡後復活的地方：map、x、y、z、facing_deg | 儲存點 | M5 |
| base_level、job_level、base_exp、job_exp | | 同名 | M5 |
| stats、status_points、skill_points | 素質、未分配的素質點和技能點 | str～luk、status_point、skill_point | M5 |
| hp、sp | 目前的 HP、SP | hp、sp | M5 |
| zeny | | zeny | M6 |
| inventory | 物品實例：`uid`（每件裝備唯一；可以堆疊的消耗品、材料沒有）、`item`（定義的 ID）、`amount`、`refine`、`cards`、`random_options`（`[{option, value}]`，第 4.15 節）、`identified`、`broken`、`bound` | inventory | M6 |
| equipment | 裝備位置 → 物品實例 | 裝備中的物品 | M6 |
| skills | 技能 ID → 等級 | skill | M7 |
| status_effects | 登出時要保留的狀態：狀態 ID、剩餘毫秒、數值 | 保留的狀態效果 | M7 |
| hotkeys | 快捷列（RO 把快捷列存在伺服器） | hotkey | M8 |
| quests | 進行中的任務（任務 ID、目前的步驟、每一步的進度）和完成過的任務（ID、完成時間，可以重複的記下次能接的時間） | quest log | M8 |

**角色名稱（03-D19）：**
- 2～16 個字，中文、英文字母、數字都算 1 個字。字和字之間可以有一個空白，開頭和結尾不能是空白。
- 全伺服器不重複。比對時不分大小寫、不分全形半形；看起來一樣的名稱（例如混用外型相似的字母）也算重複，例如 `Steven`、`steven`、`Ｓｔｅｖｅｎ` 是同一個名稱。
- 判斷「看起來一樣」用 Godot TextServer 內建的 Unicode 安全檢查（`is_confusable`、`spoof_check`），不用自己寫。專用伺服器的版本能不能用這項功能，M9 確認；不能用就退回「轉小寫、全形轉半形」再比對。
- RO 是 4～23 位元組（用客戶端的編碼計算），而且分大小寫。改成這樣的理由見第 14.1 節。

**單機第一次啟動**：自動建立本機帳號和一個初心者角色（女性、預設外觀，出生在 `data/rules/` 指定的抵達點）。名稱用顯示文字表裡的預設名稱，之後有角色建立畫面再改。

第一版的角色檔範例：

```text
{
  "schema_version": 1,
  "char_id": 1,
  "account_id": 1,
  "name": "<預設名稱>",
  "created_at": "2026-10-10T08:00:00Z",
  "last_saved_at": "2026-10-10T09:30:00Z",
  "job": "novice",
  "appearance": {
    "gender": "female",
    "hair_style": "hair_twin_tails",
    "hair_color": "auburn",
    "eye_color": "brown",
    "face_shapes": {}
  },
  "position": { "map": "kronenberg", "x": 12.5, "y": 0.0, "z": -40.25, "facing_deg": 90.0 }
}
```

### 8.4 版本與遷移

```text
讀檔 → 解析 JSON → 看 schema_version
         ├─ 等於目前版本 ─────────────────────────────────→ 驗證 → 使用
         ├─ 比目前舊 → 備份到 backup/ → 一步一步遷移 ─────→ 驗證 → 使用（下次存檔時寫成新版）
         └─ 比目前新 → 拒絕讀取，記錄錯誤，原檔不動
```

| 規則 | 內容 |
|---|---|
| 版本號 | 帳號檔、角色檔各自有一個整數版本號，從 1 開始；欄位有變動就加 1。 |
| 遷移步驟 | 每一步只負責「第 N 版 → 第 N+1 版」。新增欄位時填 RO 新角色的初始值，例如 M5 加上等級時，Base 和 Job 等級都是 1。 |
| 備份 | 遷移前把原檔複製到 `backup/`，檔名加上原本的版本號，例如 `1.v1.json`。 |
| 拒絕讀取 | 版本比程式新、缺少必填欄位、型別不對、有不認識的欄位、引用不存在的資料 ID（例如已經刪掉的物品），一律拒絕讀取並記錄是哪一個欄位，原檔不動。登入時告訴玩家「角色資料有問題」。 |
| 資料 ID 改名 | 也寫成遷移步驟（舊 ID → 新 ID 對照表）。 |
| 測試 | 每個舊版本都留一份範例檔在 `tests/fixtures/saves/`，測試會把它遷移到最新版並驗證結果。 |

### 8.5 寫入順序與讀檔備援

```text
寫入：
  1. 新內容寫到 x.json.tmp，寫完並關檔
  2. 刪掉舊的 x.json.bak，把 x.json 改名成 x.json.bak
  3. 把 x.json.tmp 改名成 x.json

讀取：
  x.json 正常                 → 使用
  x.json 不見或壞掉          → x.json.tmp 正常就用它；否則用 x.json.bak；都不行就拒絕讀取
  （用了 .tmp 或 .bak 時記錄警告）
```

- **為什麼這樣排**：Godot 在 Windows 上把檔案改名成已存在的檔名時，會先刪掉舊檔再搬過去。如果在兩個動作之間當機，原本的「先寫暫存檔再取代」就可能留下沒有完整檔案的情況。照上面的順序，任何時候都至少有一份完整的檔案（.tmp、.json 或 .bak）。
- Linux（專用伺服器）上的改名本來就是一步完成，用同一套流程也沒有問題。
- 這是 02-D17「先寫暫存檔再取代，並保留一份備份」的具體做法，沒有改變 02 的決定。

---

## 9. 設定檔

### 9.1 使用者資料夾

- 開啟 Godot 的「自訂使用者資料夾」，名稱固定為 `RagnarokChange`。在 Windows 上的位置是 `%APPDATA%\RagnarokChange\`。
- 如果不開，位置會是 `%APPDATA%\Godot\app_userdata\<專案名稱>\`。專案名稱一改就會換資料夾，舊的設定和存檔就找不到了。

```text
%APPDATA%\RagnarokChange\
  settings.cfg      客戶端設定
  server.cfg        單機時本地伺服器的設定（可以不存在，就用預設值）
  saves\            存檔（第 8 節）
  logs\             log 檔（Godot 內建的檔案 log，預設保留最近 5 個）
```

- 測試一律使用暫存資料夾，不會碰到這裡的設定和存檔。

### 9.2 客戶端設定（`settings.cfg`）

| 區段 | 內容（細項由各文件決定） |
|---|---|
| meta | 版本號 |
| graphics | 畫質預設（低、中、高、電影）、FSR 2 放大（預設關）、視窗模式、解析度、垂直同步、最高幀率、各項效果開關（01 第 14 節、08、10） |
| input | 按鍵（09） |
| camera | 滑鼠靈敏度、反轉、縮放速度、距離（09） |
| ui | 介面縮放、顯示語言（預設 zh_TW，可以切換，第 7 節）、任務追蹤列（預設開）（10） |
| audio | 各匯流排的音量：主音量、音樂、音效、介面、環境（10） |
| network | 上次連線的主機和帳號，不存密碼（M9） |

- 按鍵存成純文字，例如 `"F1"`、`"Ctrl+1"`、`"Alt+A"`、`"Mouse:Right"`、`"Wheel:Up"`。不存 Godot 的 InputEvent 物件，檔案好讀也好改。
- 只存「跟預設不同」的按鍵和數值。之後預設值改了，沒有自己改過的人會自動用到新的預設。
- 讀檔時：
  - 檔案不存在 → 全部用預設值。
  - 某一項的值不合法 → 那一項用預設值，記錄警告。
  - 不認識的項目 → 忽略，記錄警告。

範例：

```text
[meta]
version=1

[graphics]
preset="high"
vsync=true

[input]
sit=["Insert"]

[camera]
mouse_sensitivity=1.0
```

### 9.3 伺服器設定（`server.cfg`）

- 位置：專用伺服器在 `/data/server.cfg`；單機在使用者資料夾，可以不存在。
- 格式跟客戶端一樣是 ConfigFile，只有一個 `[server]` 區段。鍵名是 02 的環境變數去掉 `SERVER_` 再轉成小寫：

| 環境變數（02 第 13.3 節） | `server.cfg` 的鍵 |
|---|---|
| SERVER_PORT | port |
| SERVER_MAX_PLAYERS | max_players |
| SERVER_TICK_RATE | tick_rate |
| （其他依此類推） | |

- 優先順序照 02：環境變數 → `server.cfg` → 預設值。
- 值不合法，或有不認識的鍵 → 拒絕啟動，並說明是哪一項。伺服器設定錯了，寧可開不起來，也不要用錯的設定跑。
- 啟動時把最後生效的設定寫進 log（不含密碼或金鑰）。

### 9.4 專用伺服器的其他檔案（M9）

| 檔案 | 內容 |
|---|---|
| `/data/status.json` | 健康檢查（02 第 13.2 節）：更新時間、已經執行多久、在線人數、人數上限、最近 10 秒 tick 時間的平均和最大值、協定版本 |
| `/data/admin/*.json` | 管理指令（02 第 13.4 節）：command、args、issued_at；處理完就刪除，結果寫進 log。各指令的參數在 M9 定 |
| `/data/cert/` | DTLS 的金鑰和憑證（02 第 12.3 節），PEM 格式 |

---

## 10. 授權登記表

### 10.1 位置與欄位

- 位置：`assets/license_registry.json`。結構跟資料表一樣（table＋entries），每個素材一筆，依 id 排序。內容一律英文（00-S06）。
- 由管線自動新增（04）。資料不齊全時，管線會先停下來問你，不會亂填。

| 欄位 | 內容 | 必填 |
|---|---|---|
| id | 例如 `polyhaven_<資產名稱>` | ✔ |
| paths | `assets/` 底下這筆涵蓋的檔案或資料夾（處理後的成品，包含 LOD、縮放過的貼圖等衍生檔） | ✔ |
| source_paths | `assets/_source/` 底下的原始檔 | 有原始檔時 |
| origin | 來源，清單照 04 第 5 節的白名單，例如 polyhaven、ambientcg、makehuman、mixamo、sketchfab、quaternius、kenney、fab、itchio、blenderkit、cgtrader、opengameart、freesound、sonniss、game_icons、hunyuan3d（Colab）、gemini、tripo（備案）、google_fonts、original（自製）、other | ✔ |
| title | 原作品名稱 | ✔ |
| url | 原始頁面 | 自製以外都要 |
| author | 作者 | CC-BY 必填 |
| license | SPDX 代碼，例如 `CC0-1.0`、`CC-BY-4.0`、`CC-BY-NC-4.0`、`CC-BY-SA-4.0`、`OFL-1.1`。SPDX 清單上沒有的用 `LicenseRef-` 開頭，例如 `LicenseRef-Mixamo`、`LicenseRef-Tencent-Hunyuan3D-2-Community`、`LicenseRef-Google-Gemini`；自製的是 `LicenseRef-Original`。允許的代碼照 04 第 5 節 | ✔ |
| license_url | 授權條款的網址 | ✔ |
| attribution | 需要署名時的完整署名文字 | CC-BY 必填 |
| modifications | 做過的修改，例如減面、重拓撲、產生 LOD、貼圖縮放、ORM 打包、Mixamo 綁骨（沒改就是空清單） | ✔ |
| acquired_on | 取得日期 | ✔ |
| plan | 使用的方案等級（例如 Gemini 的付費方案、Tripo 的免費或付費方案） | gemini、tripo 必填 |
| generation | AI 生成的紀錄：工具和模型版本、種子、提示詞（Colab 輸出的 `.json`） | hunyuan3d、gemini 必填 |
| restrictions | 使用限制：`no_source_redistribution`（不能再散布原始檔，例如 Mixamo、Sonniss）、`non_commercial`（不能商用，NC）、`share_alike`（改作要用同授權，SA）、`no_derivatives`（不能改作，ND，只能原樣使用）、`public_output`（產出會公開，例如 Tripo 免費方案）、`territory_excludes_eu_uk_kr`（Hunyuan3D-2 的地區限制）、`personal_use_only`（只限個人自用，例如 Gemini 在查清商用條款之前） | 有就填 |
| replacement | 待替換的原因（04 的待替換清單）：`differs_from_concept`（跟概念圖不同）、`license_blocks_release`（授權限制公開或商用）、`quality`（品質不夠）；空清單表示正式素材 | ✔ |
| notes | 備註 | — |

範例（示意）：

```text
{
  "id": "polyhaven_<資產名稱>",
  "paths": ["assets/textures/<資產名稱>/"],
  "source_paths": ["assets/_source/textures/<資產名稱>/"],
  "origin": "polyhaven",
  "title": "<原作品名稱>",
  "url": "https://polyhaven.com/a/<資產名稱>",
  "author": "<作者>",
  "license": "CC0-1.0",
  "license_url": "https://creativecommons.org/publicdomain/zero/1.0/",
  "attribution": "",
  "modifications": ["resized to 2K", "packed ORM"],
  "acquired_on": "2026-10-20",
  "plan": "",
  "restrictions": [],
  "replacement": [],
  "notes": ""
}
```

### 10.2 守門測試的規則（01 第 4.3 節）

1. `assets/` 底下每個素材檔，都剛好被一筆的 `paths` 或 `source_paths` 涵蓋。`_inbox/` 不檢查。素材檔指這些副檔名：glb、gltf、fbx、obj、blend、png、jpg、jpeg、webp、tga、exr、hdr、wav、ogg、mp3、ttf、otf。
2. 每一筆寫到的路徑都存在。
3. 授權和來源在 04 第 5 節的允許清單裡（2026-10-11 放寬：收 NC、SA；ND 只有原樣使用時才收，也就是 `modifications` 是空的）。
4. 限制要標對：CC-BY 要有作者和署名文字；NC 要有 `non_commercial`、SA 要有 `share_alike`、ND 要有 `no_derivatives`；來源是 mixamo、sonniss 的要有 `no_source_redistribution`；hunyuan3d 要有 `territory_excludes_eu_uk_kr` 和 `generation`；gemini 要有方案、`generation` 和 `personal_use_only`；tripo 要有方案等級。
4a. 有 `non_commercial`、`personal_use_only`、`territory_excludes_eu_uk_kr` 的，`replacement` 一定要有 `license_blocks_release`（公開前要換）。
5. ID 不重複，而且依 id 排序。

補充：
- 我們自己寫的 Godot 檔案（`.tres`、`.tscn`、`.gdshader`、外觀設定）不算素材，不用登記；但用腳本產生的貼圖（例如雜訊圖）算，來源寫 original。
- `ConceptArt/` 是參考圖，不是遊戲素材，不用登記。
- 之後可以從登記表自動產生致謝名單（CC-BY 要求署名），在哪裡顯示由 10 決定。
- 待替換清單也從登記表自動產生（`replacement` 不是空的），每個里程碑結束時放進報告（04）。

---

## 11. 第一版要做的和之後才做的

| 項目 | 第一版（M0～M4） | 之後 |
|---|---|---|
| 載入器、驗證、重複鍵掃描、u16 索引 | ✔ | — |
| 資料改用公尺、顯示文字移出 `data/`、多語言 | ✔（M1-a3） | 之後加其他語言 |
| 語言守門測試（`data/` 和檔名沒有中文、`data/` 沒有顯示文字、語言不混用） | ✔ | — |
| 全域規則 | 出生點、名稱長度、移動速度、抵達保護、視線格網的格子 | M5 起加上儲存點、身體半徑、噪音等 |
| 地圖定義 | 2 張地圖 | 新地圖 |
| 地圖標記 | 抵達點、傳送點（包含不能過的）、安全區（M1） | 怪物生成區和生成表（M6）、NPC 位置（M8） |
| 視線格網 | ✔（M1-a2 的白模工具一起產生） | 正式素材後重新烘焙 |
| 職業 | 4 個職業的外觀（名稱在 `locale/`） | M5 起加上戰鬥欄位 |
| 物品 | 武器、盾牌、頭飾的外顯欄位（M3） | M5～M6 加上數值、消耗品、卡片 |
| 怪物 | 3 種怪物的外觀、移動速度、身體大小（M4） | M5～M6 加上戰鬥、行為、感知、掉落 |
| 怪物行為組合、感知組合、技能、狀態效果、數值表 | — | M5～M7 |
| 附加能力 | — | M6（M6-d） |
| 任務、NPC | — | M8 |
| 外觀選項 | 只有 default | 外觀自訂畫面做好時 |
| 顯示文字（locale） | 繁中和英文：第一版資料項目的名稱、基本介面文字、系統訊息 | 持續增加；之後加其他語言 |
| visual_id 和佔位外觀 | ✔ | — |
| 存檔 | 帳號、角色（位置、職業、外觀）、名稱規則、遷移框架、讀檔備援（JSON 檔） | 每次增加欄位就加一個遷移步驟（M5 起）；M9 之前改 SQLite |
| 客戶端設定檔 | 畫質、按鍵、鏡頭、語言、音量 | 連線 |
| 伺服器設定檔 | ✔（單機用預設值） | M9 專用伺服器 |
| 授權登記表和守門測試 | ✔（M0 建立；M2 起開始有內容） | — |
| 狀態檔、管理指令 | — | M9 |

---

## 12. 測試與驗收方式

**M0：**
1. 所有資料表都能載入並通過驗證。
2. 錯誤樣本：故意準備型別錯誤、未知欄位、重複 ID、同一個物件裡重複的鍵、參照不存在的 ID、每級陣列長度不對、整數欄位寫小數、重量或機率超過精度的資料。每一種都要被抓到，而且錯誤訊息指出檔案、項目和欄位。
3. 數字：重量和機率轉成整數的結果正確；距離和速度超過 2 位小數時報錯；資料裡出現 `_cells`、`_ms_per_cell` 這類舊欄位時報錯（M1-a3 起）。
4. u16 索引：同一份資料每次算出的索引都一樣；新增一筆資料後，兩邊重新算出的索引一致。
5. 顯示文字（第 7 節的驗證）：zh_TW、en 每個鍵都有；各語言的參數一致；伺服器用到的每個訊息 ID 都存在；切換語言後，用鍵取到的是新語言的文字；繁中不混英文字母（白名單除外）、英文沒有中文字元。
6. 語言守門測試：`data/` 裡出現中文字元、`name` 或 `description` 欄位，或檔名、資料夾名稱有中文字元時，測試失敗（`docs/` 和 `locale/` 的內容不檢查）。
7. 角色名稱：長度和允許的字元檢查正確；`Steven`、`steven`、`Ｓｔｅｖｅｎ` 被判定為重複。
8. 存檔：
   - 寫入再讀回，內容完全相同。
   - 第 1 版的範例檔可以讀取（之後每一版都加一份範例檔）。
   - 版本比程式新、有未知欄位、引用不存在的 ID：拒絕讀取，原檔沒有被改動。
   - 模擬寫到一半當機（只剩 .tmp；或 .tmp 是壞的）：會改用 .tmp 或 .bak，並記錄警告。
9. 客戶端設定：檔案不存在、某一項不合法、有不認識的項目時，都能用預設值啟動；按鍵的文字描述存了再讀回，結果相同。
10. 伺服器設定：環境變數蓋過 `server.cfg`，`server.cfg` 蓋過預設值；值不合法時拒絕啟動。
11. 授權守門測試：放一個沒有登記的素材檔、一筆改過的 ND 素材、一筆沒有署名的 CC-BY、一筆沒有 `non_commercial` 的 NC、一筆沒有 `replacement` 的 Gemini 素材，五種都要被抓到。
12. 資料雜湊：同樣的資料算兩次，結果相同；改一個字，結果就不同。

**M1：**
13. 兩張地圖的 logic 場景都能在伺服器上載入，不會載入任何視覺資源（01 的守門測試）。
14. 標記檢查：抵達點名稱不重複；能過的傳點的目標地圖和抵達點都存在（`open` 是 false 的不檢查目標）；抵達點不在任何傳送點的範圍裡；抵達點都在導航網格上；視線格網存在，而且大小涵蓋整張地圖。
15. 存檔位置無效時：離網格 2 m 以內會貼回網格；更遠會移到同一張地圖上隨機可以走的位置（不在傳送點範圍裡）；地圖不存在會移到預設儲存點。
16. 地圖雜湊：改動 logic 場景的標記或導航網格後，資料雜湊跟著改變。

**M3、M4：**
17. 客戶端資料測試：每個 visual_id 都找得到 `.tres`，而且裡面的場景都能載入。

**M5：**
18. 角色和怪物攻擊動作的命中點，跟資料的 `attack_hit_ms` 相差不超過 1/60 秒。

**M6：**
19. 生成表：每個 `spawn_id` 都對得上標記和地圖；整張地圖的生成不用標記。
20. 附加能力（固定亂數種子，擲 10 萬次）：1 條約 30%、2 條約 49%、3 條約 21%；沒有「有第 3 條但沒有第 2 條」；數值都在範圍內。

**M8：**
21. 任務和 NPC：交叉參照（NPC、怪物、物品、技能、任務）都存在；每個對話節點都走得到、沒有斷掉的選項；每個任務、對話的鍵在 zh_TW、en 都有文字。

---

## 13. 風險與備案

| 風險 | 影響 | 備案 |
|---|---|---|
| Godot 讀 JSON 時數字都是浮點數 | 整數欄位轉換出錯 | 依欄位定義轉成整數，有小數就報錯；所有整數都在 2⁵³ 以內 |
| Godot 遇到重複的鍵會默默蓋掉 | 欄位被吃掉卻沒發現 | 項目用陣列；另外掃描原始文字找重複的鍵（第 3.1 節） |
| Windows 上的改名不是一步完成 | 寫檔時當機可能讓存檔壞掉 | 第 8.5 節的寫入順序和讀檔備援 |
| 從 RO 的格數換算成公尺時算錯 | 射程、速度的手感跟 RO 不同 | 06 第 3 節的換算表；`ro_ref` 記原始值；M5 的數值測試照表換回去對照 |
| RO Renewal 的數值有很多版本 | 數值前後不一致 | 06 決定以哪一版為準；每個項目用 `ro_ref` 記錄對應的 RO 項目 |
| 新增資料時忘了加某個語言的文字 | 畫面上出現鍵或退回的語言 | 測試會抓到 `required` 語言缺少的鍵 |
| u16 索引在兩邊不一致 | 收到的 ID 對錯 | 連線時比對資料雜湊（02-D05），不同就拒絕連線 |
| 專用伺服器不支援 Unicode 安全檢查 | 名稱比對變寬鬆 | 退回轉小寫、全形轉半形；M9 確認 |
| 欄位越來越多 | 每次加欄位都要同時改定義類別和資料 | 資料和程式在同一個 commit 裡一起改；驗證測試保證兩者一致 |
| 存檔被手動改壞 | 角色讀不進來 | 拒絕讀取並保留原檔，log 會指出是哪一個欄位；可以從 .bak 或 `backup/` 復原 |
| 素材的授權資訊查不到 | 不能登記 | 管線停下來問你；查不到授權的素材就不用 |
| 編輯器裡的介面顯示的是文字鍵 | 排版時看不到實際的文字 | 執行時就會顯示中文；真的需要時，再做編輯器預覽 |
| 地圖變多以後，啟動時計算地圖雜湊變慢 | 客戶端啟動變慢 | 改成匯出時預先算好 |

---

## 14. 與 RO 原制不同之處（待檢視）

### 14.1 RO 的老舊做法改成現代做法（00-S14）

| 項目 | RO 原制 | 本專案 | 理由 |
|---|---|---|---|
| 資料和存檔的格式 | rAthena 的伺服器資料用 YAML，角色資料存在 MySQL | 資料用 JSON 檔；角色存檔 M9 之前一人一檔，之後 SQLite | Godot 內建 JSON；SQLite 不用另外架資料庫伺服器。玩家感受不到差別 |
| 距離和速度的單位 | 格、每格毫秒 | 公尺、公尺／秒（RO 的 1 格 ＝ 1 公尺，換算表在 06 第 3 節） | 3D 要表達身體大小、高度差和形狀；執行中本來就是公尺 |
| 顯示文字 | 名稱寫在資料和客戶端的檔案裡，各語言版本各自一套 | 資料只放 ID；所有語言都在 `locale/`，執行中可以切換 | 改文字不用動伺服器和資料雜湊 |
| NPC 和任務 | NPC 腳本（自己的腳本語言） | 任務和對話是資料，動作只有固定幾種 | 不發明腳本語言；玩家感受一樣 |
| ID | 數字 ID 加 Aegis 縮寫（例如 `SM_BASH`），劍士拼成 Swordman | 描述性的英文 ID（`bash`、`swordsman`）；RO 的名稱記在 `ro_ref` | 好讀；縮寫和拼法是舊伺服器留下來的 |
| 重量 | 資料裡 10 代表 1 | 直接寫遊戲裡顯示的重量 | 不用換算；程式內部一樣用整數 |
| 掉落率 | 萬分率（7000 代表 70%）；每隻怪物最多 10 種 | 直接寫百分比；不限種類 | 好讀；10 種是 RO 資料格式的上限，不是玩法需要 |
| 怪物 AI | AI 類型編號（01～27）加行為旗標 | 有名字的行為組合，旗標跟 RO 相同 | 編號看不出意思；行為一樣 |
| 攻擊的命中時間 | 伺服器和客戶端各用一個時間（AttackMotion、ClientAttackMotion），要另外設定才會同步 | 只有一個 `attack_hit_ms`，兩邊共用 | RO 的兩套時間是 2D sprite 時代的問題。數值用 ClientAttackMotion（RO 玩家看到傷害出現的時間），手感不變 |
| 技能欄位的寫法 | 射程寫負數表示用武器射程；段數的正負號決定顯示方式；意義不固定的 Duration2 | `"weapon"`、`damage_display`、`params` 裡有名字的數值 | 規則一樣，寫法看得懂 |
| 物品類型 | Healing、Usable、DelayConsume、Etc… | consumable、misc…，用法寫在使用效果裡 | 規則一樣，類型只分大類 |
| 裝備位置的名稱 | Right_Hand、Left_Hand、Right_Accessory、Left_Accessory | weapon、shield、accessory_1、accessory_2 | 名稱直接說明用途；雙手武器一樣佔用盾牌欄 |
| 怪物等級 | normal、boss、guardian、battlefield、event | normal、boss、mvp | 只留用得到的 |
| 地圖旗標 | 幾十種 mapflag | 只定義用得到的，名稱自己取 | 不整套照搬 |
| 狀態效果的旗標 | NoRemoveOnDead、NoSave 等 | keep_on_death、keep_on_logout 等 | 好讀；規則一樣 |
| 角色名稱 | 4～23 位元組，用客戶端的編碼計算；分大小寫 | 2～16 個字；不分大小寫、全形半形和相似字 | 位元組是舊編碼的限制；不分大小寫可以防止冒充 |

### 14.2 其他不同之處

| 項目 | RO 原制 | 本專案 | 理由 |
|---|---|---|---|
| 外觀編號 | 物品的 View 是數字，對應 2D sprite | visual_id 對應客戶端的 3D 外觀設定 | 3D 需要模型、動作、掛點等更多資料 |
| 傳送點的目的地 | 寫座標 | 寫目標地圖的抵達點名稱 | 在編輯器裡移動抵達點時，傳送點會自動跟著。玩家感受相同 |
| 怪物生成的寫法 | 寫在腳本檔裡 | 範圍在 logic 場景的標記，內容在 `data/spawns/` | 在編輯器裡直接擺範圍；調數量不用改場景。欄位（數量、基本重生時間、隨機時間、整張地圖）跟 RO 相同 |
| 傳點 | 走進去一定換圖 | 可以先放「不能過的傳點」（`open` 是 false） | 你的指示（2026-10-11）：之後開放時只改資料 |
| 附加能力的條數 | 依群組的必出格和額外格（最多 5 條） | 最多 3 條：第 1 條一定有、第 2 條 70%、第 3 條 30%（前一條有才擲） | 你的規則（2026-10-11） |
| 安全區 | 沒有安全區；城鎮裡沒有怪物，也不能 PvP | 有 `town` 旗標的地圖整張是安全區，也可以另外擺安全區 | 02 第 10 節已經定了攻擊要檢查安全區；城鎮裡的體驗跟 RO 一樣 |
| 外觀欄位 | 髮型、髮色、服裝顏色（染色） | 髮型、髮色、瞳色、臉部形狀；沒有預留服裝顏色 | 00-A10 的預留清單沒有服裝顏色（第 1 版第 9 項，已同意）。要的話，之後用遷移補上欄位即可 |

除了上兩表，本文件其他部分都照 RO：
- 欄位涵蓋的機制照 rAthena 的 Renewal 資料：職業、技能、怪物、物品、狀態效果、經驗表、屬性表、體型修正表
- 移動速度的數值照 RO（玩家預設 150 毫秒／格，換算成 6.67 m/s）
- 怪物的行為旗標
- 頭飾可以同時佔多個位置
- 技能和狀態效果的效果寫在程式裡，資料只放數值
- 沒有全域的種族修正表
- 方向從北開始逆時針
- 儲存點用座標；登入時回到上次的位置
- 存檔位置無效時移到同一張地圖的隨機位置；地圖不存在時送到預設地點
- 倉庫同帳號共用、快捷列存在伺服器（之後才做）

---

## 15. 需要修改已確認文件的地方

### 15.1 已同意並改好（跟 03 一起提交）

| 文件 | 位置 | 修改內容 | 依據 |
|---|---|---|---|
| 02 | 第 4.3 節的「遊戲資料雜湊」 | 除了 `data/` 的 JSON，再加上每張地圖 logic 場景讀出的標記資料和導航網格的頂點資料；地圖的部分用讀出來的內容計算，不受匯出格式影響。02 的狀態列已經註明修訂日期 | 第 1 版第 10 項 |

### 15.2 第 2 版新提出的（2026-10-10 你同意，已照下表改好）

依 00-S14 檢查已確認的 01、02，找到以下幾處。01、02 的狀態列都已經註明修訂日期。

| # | 文件 | 位置 | 現在的寫法 | 建議改成 | 理由 |
|---|---|---|---|---|---|
| 1 | 01 | 第 9 節目錄結構 | 沒有 `locale\` | 在 `data\` 下面加一行：`locale\  顯示文字（en、zh_TW），只有客戶端用（格式在 03）` | 03-D17 |
| 2 | 01 | 第 4.3 節守門測試 | `.gd` 檔裡沒有中文字元：「掃描所有腳本。玩家看到的文字一律放在資料檔（00-S06）」 | 說明改成「玩家看到的中文一律放在 `locale/zh_TW/`（00-S06）」，再加兩條：`data/` 裡沒有中文字元；檔名和資料夾名稱沒有中文字元 | 00-S06 的新規則 |
| 3 | 02 | 第 12.1 節帳號 | 長度照 RO：帳號 4～23 個字元（限英數字），密碼 4～32 個字元 | 帳號不變；密碼 15～64 個字元，空白和任何可列印字元都可以用 | NIST SP 800-63B-4（2025 年 8 月）：只用密碼登入時至少 15 個字元，上限至少要允許 64 個。RO 的 4 個字元太短 |
| 4 | 02 | 02-D07、第 5.4 節、第 18 節 | 帳號已在線上時，新的登入被拒絕，同時踢掉舊的連線，要再登入一次 | 新的登入接手：踢掉舊的連線，舊角色照第 5.3 節離開世界（戰鬥後 10 秒內一樣多留 10 秒），之後新的登入自動繼續；畫面顯示「正在中斷先前的連線」 | 要登入兩次是 RO 的舊伺服器架構造成的；防止逃離戰鬥的 10 秒規則保留 |
| 5 | 02 | 02-D17、第 12.2 節、第 13.3 節、第 18 節 | 每 300 秒自動存檔（每人錯開） | 每 60 秒檢查一次，只存有變動的角色（每人錯開）；`SERVER_AUTOSAVE_SEC` 的預設值改成 60 | RO 的 300 秒是當年資料庫負擔的考量；JSON 小檔案寫入很便宜，當機時最多只少 1 分鐘的進度 |

01、02 的其他部分沒有照抄 RO 舊做法的地方：tick、可視範圍、密碼雜湊、加密在 01、02 寫的時候就已經是現代做法；登出和斷線的 10 秒規則、換圖後的 3 秒保護、攻擊時站著不動屬於玩法，照 RO 保留。

### 15.3 2026-10-11 依提案修改的地方

照 `docs/proposals/`（最終決定在 `2026-10-11-replies.md`）改了本文件，同時也改了 00、01、02、04～11（各文件的狀態列註明修訂）。主要是：資料改用公尺；顯示文字移出 `data/`、`locale/` 改成多語言；新增生成表、感知組合、附加能力、任務、NPC 的資料表；物品實例和效果類型；不能過的傳點；存檔改 SQLite 的時程；授權登記表照 04 放寬。

---

## 16. 待你確認事項

### 16.1 第 1 版（2026-10-10 你回覆「全部照建議」，已定案）

| # | 事項 | 定案 |
|---|---|---|
| 1 | 距離和速度怎麼存 | 照 RO 的單位（格、每格毫秒），載入時換算 |
| 2 | 種族修正表 | 不建 |
| 3 | 地圖 ID 和顯示名稱 | `kronenberg`、`kronenberg_south_field`；中文顯示名稱是 KRONENBERG王都、王都南方草原（2026-10-11 改成克羅能堡、克羅能堡南方草原） |
| 4 | 玩家看到的文字 | 依你同時的指示改成「資料全英文、中文另外放」，做法見第 7 節（第 16.2 節第 1 項） |
| 5 | 使用者資料夾 | `%APPDATA%\RagnarokChange\` |
| 6 | 存檔有問題時 | 拒絕讀取、原檔不動 |
| 7 | 授權登記表 | 一個 JSON 檔，授權名稱用 SPDX 代碼 |
| 8 | 角色名稱長度 | 依 00-S14 改成 03-D19（第 16.2 節第 4 項） |
| 9 | 服裝顏色 | 先不預留 |
| 10 | 修改 02 第 4.3 節 | 已改好，跟 03 一起提交 |

### 16.2 第 2 版新增（2026-10-10 你回覆「全部照建議」，以下 9 項都照建議定案）

| # | 事項 | 建議 |
|---|---|---|
| 1 | 中文顯示文字的位置 | `locale/zh_TW/`；英文基準在資料的名稱和 `locale/en/`；只有客戶端讀，不算進資料雜湊（第 7 節）。2026-10-11 改成：資料不放顯示文字，每種語言都在 `locale/<語系>/` |
| 2 | 概念圖和資料用的英文名稱 | 照 `ConceptArt/README.md`：gelly、fluffy_caterpillar、young_treant、cute_bunny、adventurer_guild_staff。圖上標題用 RO 原名的（Fabre、Lunatic、Kafra）不用，改用你中文名稱的直譯 |
| 3 | RO 老舊做法改成現代做法 | 第 14.1 節全部採用 |
| 4 | 角色名稱 | 2～16 個字，不分大小寫、全形半形和相似字（03-D19） |
| 5 | 網路上的資料 ID | 一開始就用 u16 索引（03-D04） |
| 6 | 修改 01 | 第 15.2 節第 1、2 項（目錄加上 `locale`、守門測試加兩條） |
| 7 | 修改 02：密碼長度 | 15～64 個字元（NIST 2025 年的標準）。如果覺得太長，也可以改成 8～64 |
| 8 | 修改 02：重複登入 | 新的登入接手，不用登入兩次 |
| 9 | 修改 02：自動存檔 | 每 60 秒，只存有變動的角色 |

---

## 17. 留給後續文件決定的事

本文件已經預留了欄位，以下內容在對應的文件決定：

| 文件 | 事項 |
|---|---|
| 05 | `.tres` 外觀設定的內容、臉部 blendshape 的名稱清單、第一版要做哪幾種武器和盾牌（概念圖有短劍、單手劍、雙手劍、鈍器、單手杖和盾牌） |
| 06 | 以哪一版 RO Renewal 的數值為準。rAthena 目前的資料已經套用 kRO 的一轉、二轉技能平衡改版（rAthena 在 2020 年更新），例如武器的體型修正大多已改成 100%。另外還有：RO 數值的換算表、玩家的種族、攻擊各個時間（`attack_hit_ms`、`attack_lock_ms`、`hit_stun_ms`）的實際用法、技能和狀態的旗標清單、裝備效果（bonus）的種類 |
| 07 | 怪物的正式 ID 和數值（概念圖的英文名稱見 `ConceptArt/README.md`）、行為組合、可愛兔要不要放進第一版、小樹精對應哪一隻 RO 怪物 |
| 08 | 抵達點、傳送點、生成區的實際位置；導航網格怎麼烘焙；觀測點 |
| 09 | 預設按鍵、鏡頭設定的項目 |
| 10 | 介面文字的內容、致謝名單在哪裡顯示、名牌怎麼顯示 16 個字的名稱 |

---

## 18. 與 00 決策對照

| 00 決策 | 本文件對應 |
|---|---|
| 00-A02 原創換皮 | 資料只沿用 RO 的機制和數值（`ro_ref` 只記錄來源）；名稱不用 Gravity 的（第 16.2 節第 2 項），外觀是我們自己的模型 |
| 00-A04 伺服器權威、邏輯與表現分離 | 03-D12、03-D13（visual_id 和 `.tres` 分開）、03-D15（伺服器只讀 logic 場景的標記） |
| 00-A05 鏡頭 | 客戶端設定的 camera 區段（第 9.2 節，細項在 09） |
| 00-A06 分區＋傳送點 | 03-D14、03-D15 |
| 00-A07 第一版陣容 | 資料表涵蓋 4 個職業、3 種怪物（數值在 06、07） |
| 00-A09 裝備外顯 | 物品的 `locations` 可以多格、`visual_id`；頭髮顯示模式放在 `.tres` |
| 00-A10 外觀自訂預留 | 存檔的 appearance 欄位、外觀選項表（第 4.11 節） |
| 00-A11 素材授權登記 | 03-D23、第 10 節 |
| 00-S03 先做女性、預留男性 | 職業的 `visual_ids` 分 female、male；存檔有 gender |
| 00-S04 Renewal | 03-D08、第 4 節 |
| 00-S06 語言 | 03-D02（資料只放 ID 和數值、檔名全英文）、03-D17 和第 7 節（所有語言的顯示文字放在 `locale/`） |
| 00-S07 以 RO 機制為主 | 03-D08、03-D09、第 14 節 |
| 00-S12 概念圖 | 怪物、NPC 的名稱依概念圖（`ConceptArt/README.md`） |
| 00-S13 地圖名稱 | 03-D14（克羅能堡、克羅能堡南方草原） |
| 00-S16 素材以套用為主 | 03-D23、第 10 節（放寬的授權、限制標記、待替換的原因） |
| 00-S14 RO 的老舊做法不照抄 | 03-D03、03-D04、03-D06、03-D07、03-D10、03-D11、03-D19、第 14.1 節、第 15.2 節 |

其他 00 決策跟資料格式沒有直接關係，由其他文件處理。

---

## 19. 參考來源

**RO 資料結構（rAthena，只參考欄位和數值，不抄程式碼）**
- 怪物欄位（Renewal 的 Attack／Attack2 是 ATK／MATK、ClientAttackMotion、DamageMotion、掉落率萬分率、最多 10 種掉落）：https://github.com/rathena/rathena/blob/master/doc/mob_db.txt 、https://github.com/rathena/rathena/blob/master/db/re/mob_db.yml
- AI 類型和行為旗標的對照：https://github.com/rathena/rathena/blob/master/doc/mob_db_mode_list.txt
- 職業（負重、職業等級的素質加成）：https://github.com/rathena/rathena/blob/master/db/re/job_stats.yml
- 基礎 ASPD 和盾牌修正：https://github.com/rathena/rathena/blob/master/db/re/job_aspd.yml
- 經驗表、等級上限（Base 99、初心者 Job 10、一轉 Job 50）：https://github.com/rathena/rathena/blob/master/db/re/job_exp.yml
- 基礎 HP/SP 表：https://github.com/rathena/rathena/blob/master/db/re/job_basepoints.yml
- 素質點數（1 級 48 點）：https://github.com/rathena/rathena/blob/master/db/re/statpoint.yml
- 技能欄位（固定詠唱、變動詠唱、技能後延遲、冷卻、每級數值）：https://github.com/rathena/rathena/blob/master/db/re/skill_db.yml
- 技能樹：https://github.com/rathena/rathena/blob/master/db/re/skill_tree.yml
- 物品欄位（重量 10 ＝ 1、Renewal 武器的 MATK、裝備位置、View）：https://github.com/rathena/rathena/blob/master/doc/item_db.txt
- 屬性表（值的範圍 −100～200）：https://github.com/rathena/rathena/blob/master/db/re/attr_fix.yml
- 體型修正表，以及 2020 年的職業平衡改版：https://github.com/rathena/rathena/blob/master/db/re/size_fix.yml 、https://github.com/rathena/rathena/pull/4072
- 狀態效果：https://github.com/rathena/rathena/blob/master/db/re/status.yml
- 怪物生成的寫法（delay1、delay2、座標 0 表示整張地圖）：https://github.com/rathena/rathena/blob/master/doc/script_commands.txt
- 角色名稱（最少 4 個字元、大小寫視為不同）：https://github.com/rathena/rathena/blob/master/conf/char_athena.conf
- 名稱長度上限（NAME_LENGTH 為 23＋1）、預設移動速度 150：https://github.com/rathena/rathena/blob/master/src/common/mmo.hpp
- 方向編號（0 北、1 西北、2 西…）：https://github.com/rathena/rathena/blob/master/src/map/path.hpp
- 隨機選項（選項定義、群組、掉落指定群組）：https://github.com/rathena/rathena/blob/master/db/re/item_randomopt_db.yml 、https://github.com/rathena/rathena/blob/master/db/re/item_randomopt_group.yml
- 任務資料（討伐目標、時間限制、任務掉落）：https://github.com/rathena/rathena/blob/master/db/re/quest_db.yml
- 初心者的任務技能（緊急治療、裝死的條件）：https://github.com/rathena/rathena/blob/master/npc/quests/skills/novice_skills.txt
- 存檔位置無效時的處理（同地圖隨機位置、地圖不存在時送到固定地點）：https://github.com/rathena/rathena/blob/master/src/map/pc.cpp

**Godot 4.7**
- JSON（數字用 to_float 解析、結尾逗號不報錯、stringify 預設排序鍵）：https://docs.godotengine.org/en/4.7/classes/class_json.html
- JSON 解析器原始碼（數字一律是浮點數、重複的鍵直接覆蓋）：https://github.com/godotengine/godot/blob/4.7-stable/core/io/json.cpp
- Windows 的檔案改名（目標存在時先刪除再搬移）：https://github.com/godotengine/godot/blob/4.7-stable/drivers/windows/dir_access_windows.cpp
- ConfigFile：https://docs.godotengine.org/en/4.7/classes/class_configfile.html
- Translation（add_message、add_plural_message）、TranslationServer（add_translation、set_locale、偽本地化）：https://docs.godotengine.org/en/4.7/classes/class_translation.html 、https://docs.godotengine.org/en/4.7/classes/class_translationserver.html
- godot-sqlite（M9 之前查證版本）：https://github.com/2shady4u/godot-sqlite
- TextServer 的 Unicode 安全檢查（is_confusable、spoof_check）：https://docs.godotengine.org/en/4.7/classes/class_textserver.html
- 專案設定（自訂使用者資料夾、檔案 log 的位置和保留數量）：https://docs.godotengine.org/en/4.7/classes/class_projectsettings.html
- 檔案路徑（user:// 在各平台的位置）：https://docs.godotengine.org/en/4.7/tutorials/io/data_paths.html

**授權與安全**
- SPDX 授權清單：https://spdx.org/licenses/
- SPDX 自訂授權代碼（`LicenseRef-` 加英數字、`.`、`-`）：https://spdx.github.io/spdx-spec/v2.3.1/other-licensing-information-detected/
- NIST SP 800-63B-4 第 3.1.1.2 節（只用密碼時至少 15 個字元、應允許至少 64 個字元）：https://pages.nist.gov/800-63-4/sp800-63b.html
