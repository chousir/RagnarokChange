# 提案

> 這個資料夾放雲端的 Claude 提出的修改提案和你的回覆。`docs/00`～`11` 是規劃書；提案確認後，由雲端的 Claude 整合進規劃書（11-D12），本機的 Claude Code 合併後照規劃書做。提案留作紀錄。
> 規則照 CLAUDE.md：不擅自改已定的事（00-S07）；要改 `docs/00-decisions.md` 一定要先問（第 4 條）。
> **2026-10-11：全部提案都已經回覆，並整合進 `docs/00`～`11`、`docs/glossary.md`、CLAUDE.md、`ConceptArt/README.md`（分支 `claude/concept-art-design-review`）。本機的 Claude Code 從第 2 節開始。**

---

## 1. 清單

| 檔案 | 內容 | 狀態 |
|---|---|---|
| `2026-10-11-replies.md` | 回覆總表：全部提案的最終決定 | 已併入規劃書 |
| `2026-10-10-concept-art-update.md` | 概念圖換新、兩張地圖的新佈局 | 已併入規劃書（04、07、08、11） |
| `2026-10-10-design-review.md` | 多語言、資料解耦和公尺、附加能力、存檔、多人和分流、二連擊暴擊 | 已併入規劃書 |
| `2026-10-10-review-round-2.md` | 怪物感知、出生點（雅典娜神像）、附加能力 | 已併入規劃書 |
| `2026-10-11-audio-and-quests.md` | 音樂和音效、任務和 NPC | 已併入規劃書；第 2.5 節的音樂提示詞照樣用 |
| `2026-10-10-art-asset-guide.md` | 要做哪些圖和模型、交件清單 | 已併入規劃書；清單和交件表照樣用（Tripo 的地方改成 Colab） |
| `2026-10-10-art-prompts.md` | 給 Gemini 的提示詞（正面圖、概念圖、2D 素材） | 參考用，仍在使用 |

---

## 2. 給本機 Claude Code 的下一步

### 第 1 步：把規劃書合併進里程碑分支

```text
git status                                   ← 工作區要是乾淨的
git fetch origin
git checkout m1-map-walk
git merge --ff-only origin/claude/concept-art-design-review
   （本機的 m1-map-walk 之後如果又有新的提交，ff-only 會失敗；
     改用 git merge --no-ff origin/claude/concept-art-design-review，提交訊息用英文）
git lfs pull
git lfs ls-files -I "ConceptArt/*"           ← 23 張 jpg 都要列出來
powershell -File tools/scripts/check.ps1     ← 只改了文件，應該照樣全部通過
```

- `check.ps1` 沒過就停下來，把錯誤告訴使用者，不要動程式去湊。
- 照 00-S05：本機只提交、不 push。
- 合併後重新讀 CLAUDE.md（第 6、8、9、11、12 條和禁止事項都改了）。

### 第 2 步：照 11 做調整批次

順序照 `docs/11-milestones.md` 第 4.2 節：**M1-a2 → M1-a3 → M1-b → …**。每一批一樣是「寫程式和測試 → `check.ps1` → 自動截圖自檢 → 提交 → 打標籤 → `artifacts/review/<批次>/`」。

| 批次 | 內容 | 規劃書 |
|---|---|---|
| M1-a2 | 照新的概念圖重做兩張地圖的白模；Warp 加 `open`；視線格網；觀測點換新 ID；兩張俯視圖跟概念圖並排 | 08 第 4～7、9.2、11 節；03 第 6.2、6.3 節 |
| M1-a3 | 資料改公尺（拿掉 `cell_size_m`）；顯示文字移出 `data/`；`locale/locales.json`、語言切換、`--lang`；語言和授權的守門測試照新規則 | 03 第 3.3、7、10 節；01 第 4.3 節；04 第 5、16 節 |
| M1-b～M1-e | 照原本的批次，加上：M1-d 的地圖實例編號、不能過的傳點的處理和訊息、語言選項；M1-e 的新觀測點 | 11 第 4.2 節；02 第 11 節第 9、10 項 |

之後的里程碑也改了，做到時照 11 第 4、5 節：M2-e（背景音樂和環境音）、M3-c 的腳步聲、M4 的怪物聲音和小樹精的自建骨架、M5 的二連擊暴擊和邊緣到邊緣的射程、M6-a 的感知、M6-d 的附加能力、M8 的 NPC 和任務、M9 的 SQLite 和壓力測試、M11 的社交與分流。

### 第 3 步：本機留著的東西

| 東西 | 怎麼處理 |
|---|---|
| `m1-a` 和 M0 的標籤 | 保留，當紀錄；不用退回（11-D12） |
| `maps/*/terrain/` 的地形區塊檔 | M1-a2 重新產生；檔名跟新的不同的舊檔要刪掉，避免留下沒用的 LFS 檔 |
| 舊的觀測點 ID | M1-a2 換成 08 第 9.2 節的新 ID；自動截圖的腳本和測試一起改 |
| `tests/guards/license_checker.gd` | 寫死了 Tripo 和 CC0／CC-BY；M1-a3 照 04 第 5 節、03 第 10.2 節改 |
| 開發用的存檔（使用者資料夾） | M1-a3 不改存檔的欄位；舊的開發存檔讀不進來時可以直接刪掉重建（還沒有正式玩家） |
| `artifacts/` | 保留（M1-a 的報告和截圖是舊佈局的紀錄） |
| `.godot/` | 匯入快取；出現奇怪的匯入錯誤時可以刪掉，Godot 會重建 |
| `main`、`m0-skeleton` 分支 | 不動 |

### 第 4 步：使用者可以同時做的（不用等程式）

| 事情 | 放哪裡 | 什麼時候處理 |
|---|---|---|
| 用 Gemini 生成兩首背景音樂（`2026-10-11-audio-and-quests.md` 第 2.5 節），檔名 `gemini-music-kronenberg.mp3`、`gemini-music-kronenberg_south_field.mp3` | `assets/_inbox/`，並告訴我用的提示詞 | M2-e |
| 用 Gemini 生成初心者（女）的正面圖（`art-prompts` 的 P-11F），在 Colab 試做 | Colab 的輸出 `hunyuan3d2-character-novice_female.glb`、`.json` 放 `assets/_inbox/` | M2-c |
| 補充概念圖，例如雅典娜神像（P-101）、港口（P-102）、建築模組（P-81、P-82） | `ConceptArt/`（中文檔名也可以，我會改名並登記） | 隨時 |

---

## 3. 之後的提案

- 雲端的 Claude 提新提案時放在這裡，檔名 `<日期>-<主題>.md`；使用者回覆後，由雲端整合進規劃書並 push 到 `claude/*` 分支，本機照第 2 節第 1 步的方式合併。
- 本機實作時發現規劃書要改：照 11-D10 直接改並註明修訂日期；重大的改變先問使用者。

## 4. 雲端和本機的分工

| 項目 | 雲端（對話裡的 Claude） | 本機（Claude Code） |
|---|---|---|
| 規劃、提案、改規劃書 | 可以，push 到 `claude/*` 分支（00-S05） | 可以（11-D10） |
| LFS 檔案（圖片、模型、導航網格） | 可以下載來看 | 可以 |
| Godot 測試、自動截圖、Blender、ffmpeg | 不跑（沒有使用者的 GPU 和工具） | 可以 |
| push | 只 push 到 `claude/*` | 不 push（使用者要 push 時自己 push） |
