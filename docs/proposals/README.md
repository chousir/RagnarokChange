# 提案（待確認）

> 這個資料夾放「還沒定案的提案」。`docs/00`～`11` 是已確認的規劃書；提案要等你確認後，才由本機的 Claude Code 照提案裡的「執行步驟」去改規劃書和程式。改完後，提案的狀態列改成「已執行（日期）」，留著當紀錄。
> 規則照 CLAUDE.md：不擅自改已定的事（00-S07）；要改 `docs/00-decisions.md` 一定要先問（第 4 條）。

---

## 1. 清單

| 檔案 | 內容 | 狀態 | 要你決定的事 |
|---|---|---|---|
| `2026-10-10-concept-art-update.md` | 8 張概念圖換新後的差異、對 04／07／08／11 的影響、兩張地圖白模的新佈局和重做步驟 | 待確認 | 第 11 節，18 項 |
| `2026-10-10-design-review.md` | 你提的討論項目 2～7：中英切換和多語言、靜態資料和動態狀態解耦、3D 標準單位、隨機屬性、擴充性和存檔、多人規模和分流和私人房間、二連擊暴擊 | 待確認 | 第 9 節，24 項 |
| `2026-10-10-art-asset-guide.md` | 你要生成哪些圖、哪些用 Tripo、怎麼生成、一個一個的流程、交件方式 | 待確認 | 第 8 節，8 項 |
| `2026-10-10-art-prompts.md` | 可以直接複製的生圖提示詞（給 AI 生圖工具和 Tripo） | 參考用 | — |

建議的閱讀順序：先看 `concept-art-update` 和 `design-review` 的「待你確認事項」，回覆後我（或本機的 Claude Code）再照執行步驟改；`art-asset-guide` 和 `art-prompts` 可以同時開始用，不用等。

---

## 2. 給本機 Claude Code 的執行順序

### 第 1 步：取得分支，換上 8 張概念圖（不用等你確認）

雲端的 Claude 不能上傳 Git LFS 的檔案（GitHub 的 LFS 儲存位址被雲端環境的網路政策擋下），所以這個分支只有文字。8 張新圖在對話裡的 `concept-art-2026-10-10.zip`（檔名已經改好，附 `SHA256SUMS.txt`）。

```text
git fetch origin
git checkout m1-map-walk
git merge --ff-only origin/claude/concept-art-design-review
   （本機的 m1-map-walk 如果已經有新的提交，ff-only 會失敗；那就改用 git merge --no-ff，提交訊息用英文）
把 zip 解壓到 ConceptArt/，覆蓋同名的 8 個檔案
在 ConceptArt/ 裡用 SHA256SUMS.txt 核對雜湊值（PowerShell：Get-FileHash -Algorithm SHA256）
SHA256SUMS.txt 不要提交
git add ConceptArt/*.jpg
git lfs status           ← 8 個 jpg 都要顯示 LFS
check.ps1                ← 概念圖不影響程式，照規則一樣要跑
git commit -m "docs(concept-art): replace eight concept images"
```

- 這一步不改任何規劃書，只是讓 `ConceptArt/README.md` 的說明跟圖對得上。
- 照 00-S05，本機的提交不 push。

### 第 2 步：等你回覆兩份提案的「待你確認事項」

- 你回覆之前，不改 `docs/00`～`11`，也不改程式。
- 你可以在任何一邊回覆（雲端這個對話，或本機的 Claude Code）。在本機回覆時，請 Claude Code 把你的回覆記在對應提案的「待你確認事項」表裡（加一欄「你的回覆」），一起提交。

### 第 3 步：改規劃書

- 照提案的「要改的規劃書」表一項一項改，每份文件的狀態列加上修訂日期和依據（11-D10），例如「修訂：2026-10-xx，依 `docs/proposals/2026-10-10-concept-art-update.md`（你確認的第 1～18 項）…」。
- 改 `docs/00-decisions.md` 的地方要有你明確的同意（提案裡有標）。
- 一份規劃書一個提交，訊息用英文，例如 `docs(08): rework map layouts after the new concept art`。

### 第 4 步：改程式（依批次）

| 批次（建議） | 內容 | 依據 |
|---|---|---|
| M1-a2 | 兩張地圖的白模依新概念圖重做（佈局、標記、觀測點、導航網格、截圖） | `concept-art-update` 第 7～9 節 |
| M1-a3 | 資料單位改成公尺；顯示文字移出 `data/`；中英切換的架構 | `design-review` 第 2、3 節 |
| 之後的批次 | 隨機屬性（M6）、效果系統（M5～M6）、分流和私人房間（M9 之後）、二連擊暴擊（M5） | `design-review` 第 4～8 節 |

- 批次流程照 11 第 3 節：寫程式和測試 → `check.ps1` → 自動截圖自檢 → 提交 → 打標籤 → `artifacts/review/<批次>/`。
- M1-a2、M1-a3 是新加的批次，要先照提案改好 11 第 4.2 節的批次表。

### 第 5 步：提案狀態改成「已執行」

每份提案做完後，狀態列改成「已執行（日期）」，並列出對應的提交。

---

## 3. 雲端和本機的分工

| 項目 | 雲端（這個對話） | 本機（Claude Code） |
|---|---|---|
| 規劃、提案、文字修改 | 可以，push 到 `claude/*` 分支 | 可以 |
| LFS 檔案（圖片、模型、導航網格） | 不能上傳（網路政策擋下） | 可以 |
| Godot 測試、自動截圖、Blender 管線 | 沒有你的 GPU 和工具，結果不能代表你的機器 | 可以 |
| push | 依你的指示 push 到 `claude/*` 分支 | 照 00-S05 不 push |

- CLAUDE.md 第 12 條和 00-S05 寫的是「只在本機提交，不 push」。這次是你在對話裡要求 push 到新分支，所以雲端照做；要不要把「雲端可以 push 到 `claude/*` 分支」寫進 00-S05，列在 `design-review` 第 9 節第 24 項。
