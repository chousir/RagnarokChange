# RagnarokChange

> 狀態：依你的授權先照建議定案（2026-10-10），待你之後檢視
> 這份檔案給 Claude Code 每次開始工作時讀。內容跟 `docs/` 衝突時，以 `docs/00-decisions.md` 為準，其次是對應的規劃書。

## 專案摘要

個人自用、保留 Ragnarok Online 戰鬥手感（ASPD 連打、暴擊、華麗技能）的寫實 3D MMORPG。Godot 4.7.2（GDScript、Forward+），伺服器權威，單機先行、之後多人（headless 專用伺服器、Docker）。第一版是 M0～M4：Kronenberg 王都和王都南方草原可以走遍，所有角色和怪物的動作都能在檢視器看到，1080p ≥ 60 fps（11 第 4.6 節）。

## 文件索引

| 文件 | 內容 |
|---|---|
| `docs/00-decisions.md` | 最高依據：原始決策 00-A01～A13、補充決策 00-S01～S14 |
| `docs/01-architecture.md` | 四層架構、執行模式、tick、實體、目錄、程式規範、測試、版本、Git |
| `docs/02-networking.md` | 傳輸、協定、登入、移動同步、事件、興趣範圍、換圖、存檔時機、部署 |
| `docs/03-data-formats.md` | 資料表、ID、單位、visual_id、地圖標記、顯示文字、存檔、設定、授權登記表 |
| `docs/04-art-pipeline.md` | 素材來源和授權、投遞、Blender 管線、人形角色流程、匯入、預算、第一版素材 |
| `docs/05-characters.md` | 角色組成、掛點、頭飾、動作清單、AnimationTree、ASPD 播放、檢視器 |
| `docs/06-combat.md` | Renewal 公式、ASPD、普攻、判定、傷害、技能、狀態、回復、經驗、死亡、掉落 |
| `docs/07-monsters-ai.md` | 第一版怪物、AI、生成、程序化動畫 |
| `docs/08-maps.md` | 兩張地圖的佈局、場景結構、地形、導航網格、光照、觀測點 |
| `docs/09-camera-controls.md` | 鏡頭、移動、選目標、攻擊、按鍵、點選 |
| `docs/10-ui-vfx.md` | HUD、傷害數字、特效、字型、F3 面板、音效預留 |
| `docs/11-milestones.md` | 里程碑、批次、驗收、分支和標籤 |
| `docs/environment-setup.md` | 開發環境（你寫的，不改，只提建議） |
| `ConceptArt/README.md` | 概念圖清單和中文名稱 |

## 硬性規則

1. **伺服器權威、邏輯和表現分開**（00-A04、01-D01～D04）：分層是 shared、net、server、client、boot；client 和 server 不能互相引用；server 和 shared 不載入任何視覺資源；客戶端從不判定結果；遊戲狀態不放 autoload。
2. **機制照 RO**（00-S07）：不清楚的地方照 RO Renewal，基準是 rAthena master（06-D01）。只參考行為和數值、附上來源，**絕不抄模擬器的程式碼**。
3. **不照抄 RO 的老舊技術做法**（00-S14）：玩家感受得到的機制和手感照 RO；只因為當年技術限制才存在的做法改用現代做法。每一個偏離 RO 的地方都要列在文件的「與 RO 原制不同之處」。
4. **不擅自改已定的事**（00-S07）：覺得可以改的，列成待檢視讓使用者決定。實作中要改規劃書時，照 11-D10：列出要改的地方，改好後在該文件的狀態列註明修訂日期；改 `docs/00-decisions.md` 一定要先問。
5. **原創換皮**（00-A02、00-S12）：遊戲內容照 `ConceptArt/`；不用 Gravity 的名稱和素材；跟 Gravity（或其他作品）相似的設計照圖做，列在 04 第 4 節，之後再討論。
6. **語言**（00-S06）：規劃書用繁體中文；程式碼、註解、log、commit 訊息、所有資料（`data/` 的內容、ID）、檔名和資料夾名稱都用英文。玩家看到的中文只放在 `locale/zh_TW/`（03 第 7 節）。
7. **GDScript**（01-D12）：一律靜態型別，警告當錯誤；`.gd` 檔不能有中文字元（守門測試會擋）。
8. **資料**（03）：JSON、項目用陣列、ID 是英文小寫加底線、時間和距離的欄位帶單位後綴、規則數值是整數；伺服器只讀 `data/` 和 logic 場景。
9. **素材**（00-A11、04）：只用 04 第 5 節的白名單來源；每個素材都登記在 `assets/license_registry.json`；資料不齊全就停下來問使用者；不收 ND、NC、SA 授權。
10. **測試**（01-D10、11-D08）：每次提交前 `check.ps1` 全部通過；新功能要附測試；冒煙測試出現任何錯誤就算失敗。
11. **效能**（01 第 14 節、04 第 12 節）：1080p、高畫質、60 fps、GPU ≤ 12 ms；自動截圖的報告要列出效能。
12. **Git**（00-S05、01-D14、11 第 3 節）：只在本機提交，不 push；每個里程碑一條分支，每批打標籤；使用者確認截圖之前不合併回 main。

## 常用指令

M0 之前這些腳本還不存在；用途見 01 第 11.2 節。

| 指令 | 用途 | 什麼時候有 |
|---|---|---|
| `powershell -File tools/scripts/check.ps1` | 匯入資源、跑全部的 headless 測試（單元、整合、冒煙、守門） | M0-a |
| `powershell -File tools/scripts/shots.ps1 <腳本名>` | 自動截圖，輸出到 `artifacts/` | M0-f |
| `powershell -File tools/scripts/inbox.ps1` | 處理 `assets/_inbox/` 的素材（Blender 背景模式） | M2-a |
| `powershell -File tools/scripts/server.ps1` | 本機啟動 headless 專用伺服器 | M9 |
| `godot --path . -- --viewer` | 動作檢視器 | M3-d |

## 工作流程

- **開始工作前**：讀這份檔案和 `docs/11-milestones.md`，確認目前在哪個里程碑、哪一批；看 `git status`。
- **一批的流程**（11 第 3 節）：寫程式和測試 → `check.ps1` → 自動截圖自檢 → 提交（`類型(批次): 摘要`，例如 `feat(m1-a): add map white-box`）→ 打標籤 `m<N>-<字母>` → 把要給使用者看的截圖和報告放在 `artifacts/review/<批次>/`。
- **失敗時**：先存成備份分支，再退回上一個標籤（11-D06）。
- **需要使用者動手的步驟**（Tripo、Mixamo、截圖確認）：先做其他不需要使用者的部分，把需要的東西準備好（11 第 6 節）。
- **概念圖**：使用者會一直新增圖片、改檔名。常看 `git -c core.quotepath=false status`；新的中文檔名改成英文 `<類別>-<名稱>.jpg` 並登記在 `ConceptArt/README.md`（00-S06）。
- **使用者用截圖回報畫面**（00-A13）：給使用者看之前，自己先看過自動截圖。

## 模型使用建議

| 工作 | 建議 |
|---|---|
| 架構、網路、戰鬥、跨檔案的實作和除錯 | 可用清單中最強的模型（Opus 5.5） |
| 單純的批次工作（素材登記、資料表填寫、改名） | Sonnet 5.5 |

實際可用的模型以 `/model` 列出的為準（environment-setup 第 6 節）。

## 禁止事項

- 抄 rAthena 或其他模擬器的程式碼（只參考行為和數值，附上來源）。
- 使用 Gravity 的名稱、圖片、模型、音效。
- 在 server 或 shared 載入模型、貼圖、材質、動畫。
- 在客戶端判定命中、傷害、掉落、經驗、冷卻。
- 把遊戲狀態放進 autoload。
- 在程式碼、資料、檔名裡寫中文。
- 加入 RO 沒有的機制而不列在「與 RO 原制不同之處」（例如打擊停頓、鏡頭震動、Miss 動作）。
- 未經同意修改 `docs/00-decisions.md`、`docs/environment-setup.md`。
- push、合併到 main 而沒有經過使用者確認、把祕密（密碼、金鑰）放進 repo。
