# 開發環境準備

> 專案：RO 手感寫實 3D MMORPG（Godot 4）
> 適用：Windows 原生開發（WSL 僅留給之後的多人伺服器）
> 引擎版本固定：**Godot 4.7.2 標準版**（升級引擎需另開分支評估）

---

## 1. 下載清單

### 1.1 軟體

| # | 軟體 | 版本 | 下載 | 備註 |
|---|---|---|---|---|
| 1 | NVIDIA 驅動 | 最新 Game Ready 或 Studio | https://www.nvidia.com/drivers | Godot Forward+ 走 Vulkan，舊驅動容易出問題 |
| 2 | Git for Windows | 最新版 | https://git-scm.com/downloads/win | 安裝時勾選 **Git LFS**；Claude Code 會使用其中的 Git Bash |
| 3 | Godot Engine | **4.7.2 標準版**（非 .NET） | https://godotengine.org/download/windows/ | 免安裝，解壓縮即可 |
| 4 | Blender | 最新穩定版 | https://www.blender.org/download/ | 用 Python 腳本自動處理模型 |
| 5 | VS Code | 最新版 | https://code.visualstudio.com/ | 直接開 Windows 資料夾，不要用 Remote-WSL |
| 6 | Claude Code | 最新版 | PowerShell 執行：`irm https://claude.ai/install.ps1 \| iex` | 需要 Pro / Max 等付費方案 |

### 1.2 VS Code 擴充

| 擴充 | ID | 用途 |
|---|---|---|
| godot-tools | `geequlim.godot-tools` | GDScript 語法、補全、除錯 |

### 1.3 帳號

| 服務 | 網址 | 用途 | 費用 |
|---|---|---|---|
| Mixamo | https://www.mixamo.com | 人形自動綁骨＋動作庫 | 免費（Adobe 帳號） |
| Tripo | https://www.tripo3d.ai | AI 生成 3D 模型（主力） | 免費額度：每月約 300 credits、15 次下載，輸出不可商用 |
| Sketchfab | https://sketchfab.com | 找 CC 授權的暫代素材 | 免費 |

不需要帳號：Poly Haven（https://polyhaven.com）、ambientCG（https://ambientcg.com），兩者都是 CC0 授權。

---

## 2. 目錄規劃

```
D:\godot\        # Godot 4.7.2 解壓縮位置
D:\RagnarokChange\         # 專案根目錄（Git repo）
```

路徑請避免中文和空白。

---

## 3. 安裝與設定步驟

### 3.1 Godot 加入 PATH

1. 把 Godot 解壓縮到 `D:\godot\`，資料夾內應該有：
   - `Godot_v4.7.2-stable_win64.exe`（編輯器）
   - `Godot_v4.7.2-stable_win64_console.exe`（命令列版，會輸出 log）
2. 在同一個資料夾建立 `godot.cmd`，內容如下（**不要改 exe 的檔名**，console 版靠檔名找主程式）：
   ```bat
   @"%~dp0Godot_v4.7.2-stable_win64_console.exe" %*
   ```
3. 把 `D:\godot` 加入使用者環境變數 `Path`。

### 3.2 Blender 加入 PATH

把 Blender 的安裝資料夾加入 `Path`，例如：
```
D:\blender
```

### 3.3 Git 設定

PowerShell：
```powershell
git config --global user.name  "Steven"
git config --global user.email "你的 email"
git config --global init.defaultBranch main
git lfs install
```

`.gitattributes`（決定 LFS 追蹤哪些檔案、換行規則）和 `.gitignore`（排除 `.godot/` 快取）由 Claude Code 在第一個里程碑建立。

### 3.4 Godot 外部編輯器改用 VS Code

Godot → 編輯器 → 編輯器設定 → 文字編輯器 → 外部：
- 使用外部編輯器：開啟
- 執行檔路徑：`C:\Users\steven\AppData\Local\Programs\Microsoft VS Code\Code.exe`
- 執行參數：`{project} --goto {file}:{line}:{col}`

---

## 4. 環境驗證

開一個**新的** PowerShell，逐行執行，每一行都要印出版本號：

```powershell
git --version
git lfs version
godot --version        # 應顯示 4.7.2.stable...
blender --version
claude --version
```

---

## 5. 建立專案

```powershell
mkdir D:\RagnarokChange
cd D:\RagnarokChange
git init
git lfs install
mkdir docs
# 把本文件複製到 docs\environment-setup.md
code .
```

在 VS Code 開啟終端機（PowerShell）：
```powershell
claude
```

進入 Claude Code 後：
1. 執行 `/model`，選擇規劃用的模型（見第 6 節）
2. 先貼：「請依 docs/environment-setup.md 第 4 節驗證環境，回報結果，不要修改任何檔案。」
3. 驗證通過後，再貼「開工指令」（決策摘要＋規劃書順序）

---

## 6. 模型使用建議

| 工作 | 建議模型 | 理由 |
|---|---|---|
| 規劃書（特別是 01 技術架構、02 網路與多人） | 可用清單中最強的模型（Opus 5.5） | 架構決策影響整個專案，值得用最強的模型 |
| 里程碑實作（系統、戰鬥、網路） | Opus 5.5 | 跨檔案修改、除錯 |
| 單純批次工作（素材登記、資料表填寫、改名） | Sonnet 5.5 | 速度快、省額度 |

實際可用的模型以 `/model` 列出的清單為準。

---

## 7. 開發循環（每個里程碑）

1. `git switch -c m<N>-<名稱>` 開分支
2. 指令範例：「依 docs/11 實作 M1」
3. Claude Code 寫程式 → 跑 headless 檢查和測試 → commit
4. 在 Godot 按 F5 看畫面 → 截圖回報問題
5. 確認後合併回 `main`

---

## 8. 素材流程（你要做的部分）

1. 從 docs/04 取得模型的提示詞和規格
2. 到 Tripo 用 image-to-3D 生成 → 下載 `.glb`
3. 放進 `D:\RagnarokChange\assets\_inbox\`
4. 人形角色：之後依指示上傳到 Mixamo 綁骨、下載動作
5. 告訴 Claude Code「處理 _inbox」，後續的減面、LOD、匯入、授權登記由它自動完成
