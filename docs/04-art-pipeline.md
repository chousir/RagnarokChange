# 04 美術與素材管線

> 狀態：已確認（2026-10-10）
> 建立日期：2026-10-10
> 依據：`docs/00-decisions.md`、`docs/01-architecture.md`、`docs/02-networking.md`、`docs/03-data-formats.md`
> 決策編號格式：`04-Dxx`

---

## 1. 目的與範圍

**本文件決定：**
- 美術方向，以及概念圖怎麼用（含跟 Gravity 等作品相似的清單）
- 素材來源和授權規則
- `assets/` 的目錄、投遞檔名
- 概念圖怎麼變成 Tripo 的輸入
- Blender 背景處理流程（清理、減面、重拓撲、LOD、貼圖、匯出、登記、報告）
- 人形角色流程（共用頭部、依職業的身體、可換髮型、Mixamo 綁骨、Godot 重定向）
- 非人形怪物的骨架做法
- Godot 匯入設定
- 面數、貼圖、材質的預算
- 第一版素材清單和 Tripo 的使用方式

**不在本文件：**

| 內容 | 文件 |
|---|---|
| 角色怎麼組合、掛點、頭髮顯示模式、動作清單、外觀參數 | 05 |
| 怪物的程序化動畫、AI | 07 |
| 地圖佈局、地形、植被系統、光照、觀測點 | 08 |
| UI、特效、字型的使用方式 | 10 |
| 每一批做哪些素材 | 11 |

---

## 2. 決策摘要

| 編號 | 決策 | 理由／對應 00 |
|---|---|---|
| 04-D01 | 美術方向是寫實 PBR（金屬度／粗糙度），以 `ConceptArt/` 為準；概念圖沒畫到的部分，質感和細節密度參考 FF14，但不複製 FF14 的設計。 | 00-S08、00-S12。 |
| 04-D02 | 跟 Gravity（以及其他作品）相似的設計照圖做，列在第 4 節，之後再討論。 | 00-S12。 |
| 04-D03 | 素材只用白名單來源：Poly Haven、ambientCG、MakeHuman（MPFB2 核心素材）、Quaternius、Sketchfab（只收 CC0、CC-BY）、Mixamo、Tripo、Google Fonts。其他來源先問你。 | 00-A11；授權清楚才能登記（03-D23）。 |
| 04-D04 | Tripo 免費方案的產出是公開的，Tripo 條款保留權利、不能商用；個人自用（00-A01）可以用。登記成 `LicenseRef-Tripo-Free`，付費方案登記成 `LicenseRef-Tripo-Paid`。之後要公開發佈或商用，一定要用付費方案重新產生。 | Tripo 價格頁寫 CC BY 4.0，但條款第 5.2.1 條保留免費方案產出的權利，以條款為準。 |
| 04-D05 | 目錄：`assets/_inbox/`（投遞，不進 Git）、`assets/_source/<類別>/<id>/`（原始檔留底，LFS）、`assets/<類別>/<id>/`（成品）。成品和原始檔用同一個 id。 | 00-A11、01 第 9 節、03 第 5 節。 |
| 04-D06 | 投遞檔名是 `<來源>-<類別>-<名稱>.<副檔名>`，全英文。檔名不對或資料不齊全，我會改名並問你缺的資訊。 | 00-S06；登記表需要來源資訊。 |
| 04-D07 | 概念圖是三視圖合在一張。工具會把每個物件的正面、側面、背面切成單張，給 Tripo 的多視角生成用。 | 照概念圖做（00-S12），多視角的結果比單張圖準。 |
| 04-D08 | Blender 背景處理流程：匯入 → 清理 → 尺寸和方向 → 分件 → 減面（必要時重拓撲＋烘焙）→ UV 檢查 → LOD → 貼圖 → 匯出 → 登記 → 預覽圖和報告。每一步都從原始檔重做，參數寫在 `process.json`。 | 00-A11；可以重跑，參數改了也能重新產生。 |
| 04-D09 | LOD 照你原本的決定由 Blender 產生（LOD0～LOD2），Godot 匯入時關閉自動 LOD，由匯入腳本設定可見距離。Godot 自動 LOD 的比較列在第 8.3 節，M2 用同一個模型比較後再決定要不要換。 | 00-A11。 |
| 04-D10 | 模型匯出成 glb（網格、骨架、動作、blendshape），貼圖另外存成 PNG，材質由 Godot 的 `.tres` 管理。glb 裡不嵌貼圖。 | 貼圖不會存兩份；每張貼圖可以單獨設定壓縮方式。 |
| 04-D11 | 人形角色：一個共用頭部（每個性別一個）＋依職業的身體＋可換的髮型。身體用 Tripo 照概念圖產生，再用 Tripo 的分件功能拿掉頭和頭髮；頭部用 MPFB2（CC0）；髮型用 Tripo 分件的結果或 MPFB2 的 CC0 髮型。 | 05 的大綱已定：換職業只換 Body，頭和頭髮不變（跟 RO 一樣）。共用頭部才能做 00-A10 的 blendshape。 |
| 04-D12 | 綁骨照你原本的決定用 Mixamo：身體、頭、頭髮合併成一個網格上傳，下載綁好的 FBX，腳本再把骨架和權重轉回分開的網格（保留 blendshape）。Mixamo 不能用時，改用 Tripo 的雙足自動綁骨。 | 00-A11；Mixamo 只維護不開發，要有備案。 |
| 04-D13 | 所有人形骨架在 Godot 用 BoneMap＋SkeletonProfileHumanoid 統一，動作共用。Mixamo 的動作直接用 Godot 內建的 FBX 匯入，不經過 Blender。 | Godot 4.3 起內建 FBX 匯入；少一次轉檔就少一個出錯的地方。 |
| 04-D14 | 動作以 Mixamo 為主，Quaternius Universal Animation Library（CC0）為輔，也是 Mixamo 的備案。下載的動作一律留底。 | Mixamo 隨時可能無法使用。 |
| 04-D15 | 非人形怪物不用 Mixamo：依 07 的需要，腳本自動建立簡單骨鏈，或乾脆不用骨架（頂點變形）。 | 00-A11。 |
| 04-D16 | 面數、貼圖、材質數量有預算表（第 12 節），暫定值在 M1～M2 實測後修正。管線報告會標出超出預算的素材。 | 00-A03、01 第 14 節的效能預算。 |
| 04-D17 | 每個處理完的素材都輸出轉台預覽圖和報告。我先看過，再請你看。 | 00-A13、01-D11。 |
| 04-D18 | 授權資料不齊全時，管線停下來問你，不亂填；登記表由管線寫入（03-D23）。 | 00-A11。 |

---

## 3. 美術方向

**依據：** `ConceptArt/` 的 23 張圖（2026-10-10 看過全部；中文名稱見 `ConceptArt/README.md`）。

| 項目 | 方向 |
|---|---|
| 整體 | 寫實的 PBR 材質（皮革、布、金屬都有磨損和髒污），人物比例寫實、五官略為理想化，跟概念圖一樣 |
| 角色 | 照四個職業的三視圖。概念圖是 A 字姿勢，模型也維持 A 字姿勢 |
| 怪物 | 照魔物三視圖：寫實的材質（果凍的半透明、毛絨的毛髮、樹皮）配上可愛的造型 |
| 武器、盾牌 | 每種各有 4 款（學徒、衛兵、聖騎士或神職、皇家），圖上標了實際尺寸（例如短劍 35～45 公分、單手劍 85～95 公分、盾牌 30～105 公分），模型照這個尺寸 |
| 地圖、建築 | 地圖圖是佈局（08 用），建築圖是氣氛和細節的參考 |
| 概念圖沒畫到的 | 質感和細節密度參考 FF14，造型不複製 FF14 |

**尺寸基準（1 單位 ＝ 1 公尺，03-D16）：**

| 物件 | 尺寸 | 備註 |
|---|---|---|
| 女性角色 | 身高約 1.65 m | 05 可以依職業微調（例如初心者看起來比較年輕） |
| 男性角色 | 身高約 1.78 m | 00-S03 只預留 |
| 武器、盾牌 | 照概念圖標的尺寸 | 沒標的照同類型推算 |
| 怪物 | 07 定 | 果凍怪、毛絨蟲、可愛兔都比膝蓋矮；小樹精大約到腰 |

---

## 4. 跟 Gravity 等作品相似的地方（之後討論）

依 00-S12，下表的設計先照圖做，之後再跟你討論要不要改、怎麼改。我不會自己改造型。

| 概念圖 | 相似的對象 | 說明 |
|---|---|---|
| `building-kronenberg.jpg` | RO 的普隆德拉（Prontera）廣場 | 圖上的標題就是「Prontera Square」，還寫了「FF14 x RO」；噴水池、騎士像、水上的城堡 |
| `map-kronenberg.jpg` | 普隆德拉的城市配置 | 城堡在北邊、中央是噴水池廣場、有教堂、南門通往南方的野外 |
| `monster-gelly.jpg` | RO 的波利（Poring） | 水滴形、尖頂的果凍怪 |
| `monster-fluffy_caterpillar.jpg` | RO 的 Fabre | 圖上的標題就是 Fabre |
| `monster-cute_bunny.jpg` | RO 的 Lunatic | 圖上的標題就是 Lunatic |
| `monster-young_treant.jpg` | RO 的 Elder Willow；Marvel 的 Baby Groot | 標題寫 Young Elder Willow；外型跟 Baby Groot 很像（不是 Gravity，但一樣是別人的作品） |
| `npc-adventurer_guild_staff.jpg` | RO 的卡普拉職員（Kafra） | 圖上的標題就是 Kafra Service Staff，女僕裝的服務員 |

- 遊戲裡的名稱不用 Gravity 的名字，已經改成你的中文名稱直譯（`ConceptArt/README.md`）。
- 角色、武器、盾牌的概念圖沒有看到明顯照搬的設計，沒有列入。

---

## 5. 素材來源與授權

| 來源 | 用途 | 授權代碼（03 第 10 節） | 規則 | 2026 年的狀況 |
|---|---|---|---|---|
| Poly Haven | HDRI 天空、材質貼圖、部分模型 | `CC0-1.0` | 可以自由使用和修改 | — |
| ambientCG | 材質貼圖 | `CC0-1.0` | 同上 | — |
| MakeHuman（MPFB2 外掛） | 共用頭部、眼睛、睫毛、牙齒，部分髮型 | `CC0-1.0`（核心素材） | 只用核心素材；第三方素材包另外判斷 | MPFB 2.0.17（2026-07），支援 Blender 4.2 以上。外掛本身是 GPL，只是工具，不影響產出 |
| Quaternius | 動作（Universal Animation Library） | `CC0-1.0` | 免費版只有一部分動作，完整版要付費 | — |
| Sketchfab | 暫代素材 | 只收 `CC0-1.0`、`CC-BY-4.0` | 不收 NC（不能商用）、ND（不能改作）、SA（改作要用同授權）；CC-BY 要記下作者和署名 | 2024 年起付費商店移到 Fab；2026 年 8 月的資料顯示免費的 CC 下載還能用，但隨時可能停止，所以下載後一定留底 |
| Mixamo | 人形自動綁骨、動作 | `LicenseRef-Mixamo` | 可以用在遊戲裡，不能把原始檔再散布（03 的 `no_source_redistribution`） | Adobe 只維護不開發；2025 年 6 月起偶爾登入或下載失敗 |
| Tripo | 職業服裝、怪物、武器、盾牌、頭飾、道具、建築 | 免費：`LicenseRef-Tripo-Free`；付費：`LicenseRef-Tripo-Paid` | 見下方 | 價格在 2026 年調整過，以官網為準 |
| Google Fonts | Noto Sans TC | `OFL-1.1` | 字型檔放在 `assets/fonts/` | — |
| 自製 | 腳本產生的貼圖、Blender 程序化模型、佔位外觀 | `LicenseRef-Original` | — | — |

**Tripo 的授權（04-D04）：**

| 項目 | 免費方案 | 付費方案 |
|---|---|---|
| 模型可見性 | 公開 | 私人 |
| 權利 | 價格頁寫 CC BY 4.0；但服務條款第 5.2.1 條寫 Tripo 保留免費使用者輸入和輸出的所有權利，也不授權商用 | 使用者可以使用、修改、散布、商用 |
| 本專案的用法 | 個人自用可以；登記時加上 `public_output`、`non_commercial` 限制 | 要公開發佈或商用時用 |
| 每月額度 | 第三方資料寫約 200～300 點，大約 8 個模型；分件功能每次另外扣點 | 依方案 |

**通用規則：**
- 只用上表的來源。其他來源（例如 Fab 的免費素材、itch.io）先問你。
- 下載的原始檔一律放進 `_source/` 留底（LFS），來源網站之後不見了也能重新處理。
- `ConceptArt/` 是參考圖，不是遊戲素材，不用登記（03 第 10.2 節）。

---

## 6. 目錄與投遞

### 6.1 目錄

```text
assets/
  _inbox/                     投遞區（.gdignore，不進 Git，只留一個佔位檔）
  _source/<類別>/<id>/        原始檔留底（.gdignore，LFS），加上 process.json（處理參數）
  characters/<id>/            職業服裝（身體）、共用頭部、髮型、NPC
  equipment/<id>/             武器、盾牌、頭飾
  monsters/<id>/
  environment/<id>/           建築、城牆、大型地形物件
  props/<id>/                 小道具
  animations/<組>/            動作庫（例如 human_common、weapon_dagger）
  textures/<id>/              共用的材質貼圖（Poly Haven、ambientCG）
  materials/                  共用材質（.tres）
  vfx/  ui/  fonts/  audio/
  license_registry.json       授權登記表（03 第 10 節）
```

- 類別資料夾照 01 第 9 節。NPC 也是人形，放在 `characters/`。
- 一個成品資料夾的內容（以怪物為例）：

```text
assets/monsters/gelly/
  gelly.glb                 網格（含 LOD）、骨架、動作；不含貼圖
  gelly_albedo.png          基本色（含透明度時放在 alpha）
  gelly_normal.png          法線（OpenGL 方向，Y 朝上）
  gelly_orm.png             R＝AO、G＝粗糙度、B＝金屬度
  gelly.material.tres       Godot 材質
  gelly.visual.tres         外觀設定（03 第 5 節）
```

### 6.2 投遞檔名（04-D06）

格式：`<來源>-<類別>-<名稱>.<副檔名>`，全部英文小寫加底線；名稱就是成品的 id。

| 來源 | 類別 | 例子 |
|---|---|---|
| tripo、mixamo、mpfb、polyhaven、ambientcg、sketchfab、quaternius、googlefonts、original | character、equipment、monster、environment、prop、animation、texture、hdri、font | `tripo-character-novice_female.glb`、`tripo-equipment-initiate_dagger.glb`、`mixamo-animation-sit_down.fbx`、`polyhaven-texture-<名稱>.zip` |

- 你可以照舊用中文或其他檔名丟進來，我會照規則改名，並問你缺的資訊。
- 每種來源需要的資訊：

| 來源 | 需要你告訴我的 |
|---|---|
| Tripo | 用的是免費還是付費方案 |
| Sketchfab | 模型頁面的網址（作者和授權我從頁面查） |
| Poly Haven、ambientCG | 不用，我從檔名查 |
| Mixamo | 不用 |

- 處理完的原始檔搬到 `_source/<類別>/<id>/`，`_inbox/` 清空。

---

## 7. 概念圖變成 Tripo 的輸入（04-D07）

```text
ConceptArt/character-novice_female.jpg（三視圖合在一張）
      │  工具依切圖設定切開
      ▼
artifacts/tripo_inputs/novice_female/front.png、side.png、back.png
      │  你上傳到 Tripo 的多視角生成
      ▼
Tripo 產生模型 →（角色）分件 → 下載 glb → 投遞到 _inbox
```

- **切圖設定**：每張概念圖要切哪些物件、每個視角的範圍，記在 `tools/concept_crops.json`（英文）。我第一次處理某張圖時建好設定，之後重切只要再跑一次。
- **切圖工具**：用 Blender 背景模式（Blender 內建的 Python 可以讀寫圖片），不需要額外安裝東西。
- **左右對稱的物件**：Tripo 需要另一側的圖時，工具把側面鏡像當作另一側。
- **武器、盾牌的圖**：一張圖有 4 款，每一款分別切出正面、側面、頂面。
- **建築圖**：不是三視圖，只切出圖上的局部特寫（例如觀象台、教堂正面、城門）。整張場景由 08 規劃。

---

## 8. Blender 處理流程（04-D08）

### 8.1 步驟

用 `blender -b`（背景模式）執行，由 01 第 11.2 節的 `tools/scripts/inbox.ps1` 呼叫。

| # | 步驟 | 內容 |
|---|---|---|
| 1 | 匯入 | glb、gltf、fbx、obj。記錄原始檔的面數、貼圖和尺寸 |
| 2 | 清理 | 套用變換；合併重疊頂點（0.1 mm）；重新計算法線方向；刪掉孤立的點和邊、零面積的面；刪掉沒用到的材質 |
| 3 | 尺寸和方向 | 單位是公尺，縮放到 `process.json` 指定的尺寸（例如身高 1.65 m）。正面朝向 Blender 的 −Y，匯出後是 Godot 的 +Z（Godot 人形設定檔的標準方向）。原點規則見下表 |
| 4 | 分件 | 角色：依 Tripo 分件的名稱分成身體、頭、頭髮、頭飾、武器等，留下需要的部分（第 9 節）。其他物件通常不用分 |
| 5 | 減面 | 減到預算（第 12 節）。保留 UV 接縫和外輪廓 |
| 6 | 重拓撲＋烘焙（必要時） | 原始網格太亂、會影響變形時（例如很多細碎的面、非流形），用 QuadriFlow 重建四邊面網格 → 重新展 UV → 從原始模型烘焙基本色、法線、AO、粗糙度、金屬度 |
| 7 | UV 檢查 | 檢查重疊和貼圖密度（texel density），寫進報告 |
| 8 | LOD | 產生 LOD1、LOD2（比例見第 12 節），命名 `<物件>_LOD1`、`<物件>_LOD2` |
| 9 | 貼圖 | 縮放到預算；打包 ORM（R＝AO、G＝粗糙度、B＝金屬度）；法線一律轉成 OpenGL 方向（Y 朝上，Godot 和 glTF 的慣例）；存成 PNG |
| 10 | 匯出 | glb（Y 朝上、套用修改器、含骨架和 blendshape、不嵌貼圖）＋貼圖 PNG |
| 11 | 材質和外觀設定 | 用 Godot 的 headless 工具腳本產生 `.material.tres` 和 `.visual.tres`（內容由 05、07 定） |
| 12 | 登記 | 寫入 `license_registry.json`（03 第 10 節） |
| 13 | 預覽和報告 | 轉台預覽圖（8 個角度加特寫）和報告：各級 LOD 的面數、尺寸、貼圖大小、超出預算的項目、警告。放在 `artifacts/assets/<id>/`（不進 Git） |

**原點規則：**

| 類別 | 原點 |
|---|---|
| 角色、怪物、道具、建築 | 底部中央（腳底） |
| 武器 | 握把的握持點 |
| 盾牌 | 手把的握持點 |
| 頭飾 | 頭部的掛點（細節在 05） |

### 8.2 處理參數（`process.json`）

每個素材在 `_source/<類別>/<id>/process.json` 記錄處理參數，內容是英文。改參數後重跑，就能從原始檔重新產生成品，不用手動調。

| 欄位 | 內容 |
|---|---|
| id、category | 成品 id 和類別 |
| sources | 原始檔清單 |
| target_size_m | 目標尺寸（身高、長度或最大邊） |
| tri_budget、lod_ratios | 面數預算、各級 LOD 的比例（沒寫就用第 12 節的預設值） |
| texture_size | 貼圖大小 |
| parts | 角色分件：Tripo 的部件名稱對應到身體、頭、頭髮、頭飾、刪除 |
| retopology | 要不要重拓撲（auto、always、never） |
| origin | 原點規則（沒寫就照類別） |

### 8.3 LOD 的兩種做法（04-D09）

照你原本的決定先用 Blender 產生。Godot 匯入時也能自動產生 LOD，比較如下，M2 用同一個模型實際比較後再決定要不要換：

| 項目 | Blender 產生（目前採用） | Godot 匯入時自動產生 |
|---|---|---|
| 怎麼產生 | 管線用減面產生各級網格 | 匯入時用 meshoptimizer 自動產生，預設開啟 |
| 控制 | 每一級可以單獨調整，遠處可以整個拿掉小零件 | 全自動，品質由演算法決定 |
| 切換 | 要設可見距離（由匯入腳本自動設），可以淡入淡出 | 依畫面上的像素誤差自動選，會考慮視角和解析度，不用設定 |
| 骨架網格 | 每一級都要綁同一副骨架 | 官方文件說偶爾會在骨架網格上出問題，可以個別關閉 |
| 檔案 | 多個網格 | 一個網格內含多級 |
| 匯入時間 | 快 | 複雜的網格會比較慢 |

---

## 9. 人形角色流程

### 9.1 組成（04-D11）

```text
Skeleton3D（每個職業的身體各自綁一副，骨頭名稱統一）
  ├─ Body   依職業：novice_female、swordsman_female…（Tripo）
  ├─ Head   共用：head_female_01（MPFB2）
  ├─ Hair   可換：hair_twin_tails、hair_long_straight…
  └─ 掛點   頭飾上中下、右手武器、左手盾牌（05）
```

- 換職業只換 Body，頭和頭髮不變，跟 RO 一樣（05 的大綱）。
- 概念圖上每個職業的臉和髮型都不一樣。遊戲裡的臉是共用的，四種髮型做成可以選的髮型。
- 頭和頭髮只綁在脖子和頭的骨頭上，所以可以套在任何一個職業的身體上。

### 9.2 流程

```text
1. 概念圖 → 切圖 → Tripo 多視角生成 → Tripo 分件（頭、頭髮、身體、頭飾、武器…）→ 下載 glb → 投遞
2. Blender：留下身體，拿掉頭、頭髮、武器、劍鞘；頭飾另外存成頭飾素材
3. Blender：身體縮放到同一個身高、對齊脖子的位置，在脖子切齊共用頭部的接合處
4. Blender：身體＋共用頭部＋預設髮型合併成一個網格，匯出 FBX
5. 你：上傳到 Mixamo 自動綁骨（標記下巴、手腕、手肘、膝蓋、鼠蹊），下載 FBX（含骨架）→ 投遞
6. Blender：把骨架和權重從合併的網格轉回分開的網格（身體、頭、頭髮），保留 blendshape → 匯出 glb
7. Godot：BoneMap＋SkeletonProfileHumanoid；模型是 A 字姿勢，開啟 Fix Silhouette → 共用動作庫
```

- **為什麼要先合併再拆開**：Mixamo 一次只能綁一個角色，而且會丟掉 blendshape。所以先合併上傳，再把權重轉回原本分開的網格（大綱已定的做法）。
- **共用頭部（MPFB2）**：
  - 眼睛、睫毛、眉毛、牙齒都是分開的網格，拓撲固定，之後做眨眼、表情和臉型 blendshape（00-A10）都比較容易。
  - 臉照概念圖調整成寫實的年輕女性。皮膚材質可以用 MakeHuman 的 CC0 貼圖，或照概念圖重新烘焙。
- **髮型**：先用 Tripo 分件出來的頭髮；看起來太像一整塊時，改用 MPFB2 的 CC0 髮片髮型。髮色用材質參數調整，所以頭髮的貼圖要先去色（05）。
- **先做一個試做**：M2 先用初心者（女）走完整個流程，檢查脖子的接縫、變形和膚色。如果共用頭部的做法行不通，退回「每個職業的頭跟著身體」，先告訴你再改。

### 9.3 Mixamo 不能用時（04-D12）

| 備案 | 做法 | 缺點 |
|---|---|---|
| Tripo 自動綁骨（雙足） | Tripo 產生骨架和權重，骨頭名稱不同，用 BoneMap 對應 | 要扣 Tripo 點數 |
| Blender Rigify | 腳本放骨架、自動計算權重 | 權重品質要人工檢查 |

### 9.4 動作（04-D13、04-D14）

- **Mixamo**：下載設定是 FBX Binary、Without Skin、30 fps、不做關鍵影格簡化。走路和跑步選 In Place（原地），因為移動由程式控制（01-D08）。
- **匯入**：Godot 4.3 起內建 FBX 匯入（ufbx），Mixamo 的動作直接匯入成 AnimationLibrary，套用同一個 BoneMap。Mixamo 每個動作檔裡的動作都叫同一個名字，匯入腳本會依檔名改名。
- **Quaternius Universal Animation Library**（CC0）：有自己的人形骨架，一樣用 BoneMap 對應。免費版只有一部分動作，完整版要不要買由你決定（第 18 節）。
- 動作清單（普攻、暴擊、詠唱、坐下、撿東西、表情等，依武器分）在 05 定。

---

## 10. 非人形怪物（04-D15）

| 怪物 | 骨架的做法（細節在 07） |
|---|---|
| gelly（果凍怪） | 不用骨架，用頂點變形做彈跳和擠壓 |
| fluffy_caterpillar（毛絨蟲） | 腳本沿著身體自動建一串體節骨頭，加上腳 |
| young_treant（小樹精） | 外型是人形，可以用 Mixamo 綁骨，也可以用腳本建簡單骨架；07 依動作需要決定 |
| cute_bunny（可愛兔） | 07 決定要不要放進第一版，再定骨架 |

- 自動建立的骨架用 Blender 的自動權重，報告會附上變形測試的截圖。

---

## 11. Godot 匯入設定

| 項目 | 設定 | 理由 |
|---|---|---|
| 網格格式 | glb | 00-A11 |
| 自動產生 LOD | 關閉（用 Blender 的 LOD，04-D09） | — |
| 陰影網格 | 開啟 | 陰影計算比較省 |
| 網格壓縮 | 開啟（預設） | 省顯示記憶體 |
| 切線 | 開啟 | 法線貼圖需要 |
| 光照烘焙 | 角色、怪物：動態；建築：08 決定 | — |
| 人形骨架 | BoneMap＋SkeletonProfileHumanoid、重新命名骨頭、A 字姿勢開 Fix Silhouette | 動作共用（04-D13） |
| 貼圖 | VRAM 壓縮（高品質）、產生 mipmap；法線貼圖用法線專用的壓縮格式 | 畫質和記憶體的平衡 |
| 材質 | 有 ORM 貼圖時用 ORMMaterial3D；頭髮用 alpha scissor 或 alpha hash，避免透明排序問題；布料和葉子可以雙面 | — |
| 點選用的碰撞 | 匯入腳本自動加上簡單的膠囊或方塊，放在客戶端專用的碰撞層（09） | 01 第 7.4 節 |
| 匯入腳本 | 每個類別一支 `EditorScenePostImport` 腳本（放在 `tools/import/`）：設定 LOD 的可見距離、對應材質、加碰撞、改名 | 不用手動在匯入視窗設定 |

---

## 12. 預算（04-D16，暫定）

### 12.1 面數（三角形，LOD0）

| 類別 | LOD0 上限 | LOD1 | LOD2 | 備註 |
|---|---|---|---|---|
| 職業身體（含服裝） | 30,000 | 50% | 25% | |
| 共用頭部 | 8,000 | 50% | 25% | 含眼睛、牙齒 |
| 髮型 | 12,000 | 50% | 25% | 髮片 |
| 頭飾 | 3,000 | 50% | — | |
| 單手武器、短劍、杖 | 3,000 | 50% | — | |
| 雙手武器 | 5,000 | 50% | — | |
| 盾牌 | 3,000 | 50% | — | |
| 小型怪物（果凍怪、毛絨蟲、可愛兔） | 10,000 | 50% | 25% | |
| 中型怪物（小樹精） | 20,000 | 50% | 25% | |
| 大型建築（城堡、教堂、城門） | 150,000（整棟，分模組） | 50% | 15% | 遠處的簡化做法在 08 |
| 一般房屋 | 30,000 | 50% | 15% | |
| 道具 | 5,000 | 50% | — | |
| 樹 | 25,000 | 50% | 遠處用替身（08） | |

**對照 01 第 14 節（畫面內 ≤ 400 萬個三角形）：** 一個完整的角色（身體、頭、頭髮、頭飾、武器、盾牌）約 6 萬個三角形；20 名玩家都在近處約 120 萬，加上 30 隻怪物約 30 萬、場景約 200 萬，還在預算內。實際數字在 M1～M2 量測。

### 12.2 貼圖

| 類別 | 解析度 | 貼圖 |
|---|---|---|
| 職業身體 | 2048 | 基本色、法線、ORM |
| 共用頭部 | 2048 | 基本色、法線、ORM |
| 髮型 | 1024～2048 | 基本色（含 alpha）、法線、ORM |
| 武器、盾牌、頭飾 | 1024 | 同上 |
| 小型怪物 | 1024～2048 | 同上 |
| 中型怪物 | 2048 | 同上 |
| 建築 | 可重複的材質 2048，加上裝飾用的貼圖 | 08 細定 |
| 道具 | 512～1024 | 同上 |
| 地形材質 | 2048 | 來自 Poly Haven、ambientCG |

- 貼圖密度：角色約每公尺 1024 像素，場景和道具約每公尺 512 像素。
- 原始檔（例如 Tripo 的 4K 貼圖）留在 `_source`，成品縮小到上表的大小。
- 一個角色（身體、頭、頭髮）的貼圖約佔 40 MB 顯示記憶體，比 01 第 14 節的 6 GB 預算小很多。

### 12.3 材質數量

| 類別 | 上限 | 理由 |
|---|---|---|
| 職業身體 | 2 個 | 每個材質就是一次 draw call |
| 頭部 | 3 個（皮膚、眼睛、睫毛和眉毛） | — |
| 髮型、武器、盾牌、頭飾、怪物 | 1～2 個 | — |

---

## 13. 第一版素材清單

ID 是暫定，正式的 ID 由 05、07 定，資料用的 ID 照 03 的規則。

### 13.1 人形角色（女性，00-S03）

| ID | 內容 | 來源 | 概念圖 |
|---|---|---|---|
| `head_female_01` | 共用女性頭部（含眼睛、睫毛、眉毛、牙齒） | MPFB2 | 四張女性角色圖的臉（取共同的特徵） |
| `novice_female` | 初心者服裝 | Tripo | `character-novice_female.jpg` |
| `swordsman_female` | 劍士服裝 | Tripo | `character-swordsman_female.jpg` |
| `thief_female` | 盜賊服裝 | Tripo | `character-thief_female.jpg` |
| `acolyte_female` | 服事服裝 | Tripo | `character-acolyte_female.jpg` |
| `hair_twin_tails` | 低雙馬尾 | Tripo 分件或 MPFB2 | 初心者 |
| `hair_long_straight` | 長直髮 | 同上 | 劍士 |
| `hair_ponytail` | 長馬尾 | 同上 | 盜賊 |
| `hair_short_tied` | 短髮綁小馬尾 | 同上 | 服事 |

- 身體服裝保留衣服、腰帶、腰包、初心者的背包；拿掉武器、劍鞘、盾牌和頭上的東西（RO 也不顯示收起來的武器）。
- 男性的概念圖（四張）先不做，骨架和資料格式已經預留（00-S03）。

### 13.2 頭飾

| ID | 內容 | 概念圖 |
|---|---|---|
| `novice_helmet` | 初心者的鐵盔（頭飾上段） | 初心者 |
| `bandana` | 頭巾（頭飾上段） | 盜賊（女） |
| `ribbon` | 緞帶（頭飾上段） | 服事（女） |

### 13.3 武器和盾牌

每種武器先做概念圖上的第 1 款，再加上服事概念圖拿的權杖；其他款之後再做。

| ID | 武器種類（03 第 3.5 節） | 概念圖 |
|---|---|---|
| `initiate_dagger` | dagger | `weapon-dagger.jpg` 01 |
| `apprentice_iron_sword` | one_handed_sword | `weapon-one_handed_sword.jpg` 01 |
| `initiate_greatsword` | two_handed_sword | `weapon-two_handed_sword.jpg` 01 |
| `initiate_club` | one_handed_mace | `weapon-mace.jpg` 01 |
| `apprentice_oak_wand` | one_handed_staff | `weapon-one_handed_staff.jpg` 01 |
| `cleric_holy_scepter` | one_handed_staff | `weapon-one_handed_staff.jpg` 03（服事概念圖拿的權杖） |
| `apprentice_buckler` | 盾牌 | `armor-shield.jpg` 01 |

- 第一版實際要做哪幾種武器的模型和動作，由 05 決定（至少徒手、短劍、單手劍、鈍器）。

### 13.4 怪物

| ID | 中文名稱 | 概念圖 | 備註 |
|---|---|---|---|
| `gelly` | 果凍怪 | `monster-gelly.jpg` | 果凍類 |
| `fluffy_caterpillar` | 毛絨蟲 | `monster-fluffy_caterpillar.jpg` | 毛蟲類 |
| `young_treant` | 小樹精 | `monster-young_treant.jpg` | 植物類（07 確認） |
| `cute_bunny` | 可愛兔 | `monster-cute_bunny.jpg` | 不在第一版陣容，07 確認 |

### 13.5 場景（細節在 08）

| 地圖 | 主要素材 | 來源 |
|---|---|---|
| Kronenberg | 城牆和城門、半木造房屋（模組）、噴水池和騎士像、觀象台、教堂、遠處的城堡、市集攤位、旗幟、路燈、石板路 | Tripo（照建築圖的局部特寫）、Poly Haven／ambientCG 的材質 |
| 南方草原 | 地形材質（草地、泥土路、岩石、峭壁）、樹（松樹、闊葉樹）、灌木、草、岩石、河流、木橋、廢棄瞭望塔、小屋、農地圍籬、帳篷、洞穴入口 | Poly Haven／ambientCG、Tripo、Sketchfab（CC0、CC-BY） |

- M1 先用 Poly Haven、ambientCG 的材質加上簡單的幾何（白模）把地圖做起來，M2 管線完成後再換成正式素材（批次安排在 11）。

### 13.6 其他

| 項目 | 來源 |
|---|---|
| 人形動作（共用和依武器） | Mixamo、Quaternius（清單在 05） |
| 天空 HDRI | Poly Haven（08） |
| 字型 Noto Sans TC | Google Fonts（10） |
| 佔位外觀（`placeholder_weapon` 等，03 第 5 節） | 自製（M0） |

---

## 14. Tripo 的使用方式

### 14.1 共通設定

| 項目 | 設定 |
|---|---|
| 模型版本 | 當時最新的版本（2026 年是 3.x） |
| 輸入 | 多視角：第 7 節切好的正面、側面、背面 |
| 貼圖 | 開啟 PBR，解析度選最高 |
| 拓撲 | 角色和怪物（要變形的）選四邊面；武器、道具、建築選三角面 |
| 面數上限 | 約預算的 2 倍，留給管線減面 |
| 分件 | 角色才要。分件結果是一個 glb 裡面有多個有名字的部件 |
| 下載 | glb |

### 14.2 每個物件的輸入

| 物件 | 概念圖和視角 | 分件 | 注意事項 |
|---|---|---|---|
| novice_female | 正面、側面、背面 | 要 | 頭盔另外做成 `novice_helmet`；拿掉短劍、劍鞘、盾牌 |
| swordsman_female | 同上 | 要 | 拿掉劍和劍鞘；長髮蓋住背部，分件時要確認頭髮和披肩分開 |
| thief_female | 同上 | 要 | 頭巾另外做成 `bandana`；露出的腰部是身體網格的一部分 |
| acolyte_female | 同上 | 要 | 緞帶另外做成 `ribbon`；腰上的書屬於服裝 |
| gelly、fluffy_caterpillar、young_treant、cute_bunny | 魔物三視圖 | 不用 | 果凍的半透明在 Godot 用材質做，Tripo 的貼圖只當基本色 |
| 7 件武器和盾牌 | 各款的正面、側面、頂面 | 不用 | 照圖上標的尺寸縮放 |
| 3 件頭飾 | 從角色圖切出頭部的特寫 | 不用 | 頭盔可以用多視角；頭巾和緞帶只有局部可以參考 |

### 14.3 沒有概念圖時的文字提示詞

給 Tripo 的文字轉 3D 使用。提示詞用英文，生成效果比較好。

**範本：**
`<物件>, realistic medieval European fantasy style, game-ready 3D asset, PBR materials, worn and weathered, <材質說明>, about <尺寸> tall, single isolated object, no base, no text`

**例子：**

| 物件 | 提示詞的 `<物件>` 和 `<材質說明>` |
|---|---|
| 市集攤位 | `wooden market stall with striped canvas roof` / `weathered oak planks, faded red and cream canvas` |
| 路燈 | `wrought iron street lamp with glass lantern` / `dark iron, aged brass details` |
| 旗幟 | `hanging heraldic banner, blue cloth with a white winged emblem` / `heavy woven fabric, gold trim`（照建築圖上的旗幟） |
| 木桶、木箱 | `oak barrel with iron hoops` / `rough wooden crate with rope handles` |
| 水井 | `stone water well with wooden roof and bucket` / `mossy fieldstone, old timber` |
| 圍籬 | `rustic split-rail wooden fence segment` / `grey weathered wood` |
| 帳篷 | `canvas camping tent for travelers` / `stained beige canvas, wooden poles` |

### 14.4 額度的安排

- 第一版約 20 多個 Tripo 模型（4 套服裝、4 隻怪物、7 件武器和盾牌、3 件頭飾、幾個建築局部），角色還要分件。
- 免費方案每月大約只能做 8 個模型，第一版的模型要分 3 個月左右才做得完。要不要改用付費方案，由你決定（第 18 節）。
- 生成失敗的模型（例如手指黏在一起、背面糊掉）重新生成也會扣點，所以先切好清楚的視角圖。

---

## 15. 第一版要做的和之後才做的

| 項目 | 第一版（M0～M4） | 之後 |
|---|---|---|
| 目錄、投遞規則、授權登記 | ✔（M0 建立目錄；M2 起開始有內容） | — |
| 切圖工具、Blender 管線、報告和預覽 | ✔（M2） | 持續改進 |
| 人形角色（女性 4 套服裝、共用頭部、4 種髮型） | ✔（M2～M3） | 男性 |
| 頭飾 3 件、武器和盾牌 7 件 | ✔（M3） | 其他款 |
| 怪物 3～4 隻 | ✔（M4） | 更多怪物 |
| 場景素材 | M1 白模加 CC0 材質；M2 之後換成正式素材 | 持續增加 |
| NPC（冒險公會服務員） | — | 之後 |
| blendshape（表情、臉型） | 只保留網格裡已有的 | 外觀自訂時 |

---

## 16. 測試與驗收方式

**M0：**
1. 目錄建好；`_inbox/` 和 `_source/` 有 `.gdignore`，`_inbox/` 的內容不會被 Git 追蹤。
2. 授權守門測試（03 第 10.2 節）在空的登記表上通過，並能抓到刻意放進去的未登記檔案。

**M2（管線）：**
3. 用 1 個 CC0 測試模型（Poly Haven）跑完整個流程：成品的面數、尺寸、原點、貼圖大小都符合 `process.json`；登記表多了一筆正確的紀錄；報告和預覽圖都產生。
4. 同一個素材重跑兩次，成品完全相同（可重現）。
5. 試做初心者（女）的完整人形流程：Godot 能正確播放 Mixamo 的走路動作；共用頭部的脖子接縫在預覽圖上看不出來（我先看，再請你確認）。
6. LOD 比較：同一個模型用 Blender LOD 和 Godot 自動 LOD 各跑一次，比較畫面和效能，結果給你決定（第 8.3 節）。

**M3、M4：**
7. 每個角色、頭飾、武器、怪物都通過預算檢查；超出的項目有說明。
8. 冒煙測試（01 第 11.1 節）載入每一個角色和怪物場景，沒有錯誤。
9. 動作檢視器的截圖：每個職業、每種武器、每隻怪物都看得到，再請你確認。

---

## 17. 風險與備案

| 風險 | 影響 | 備案 |
|---|---|---|
| Mixamo 無法使用 | 不能綁骨、不能下載動作 | 動作下載後都留底；綁骨改用 Tripo 自動綁骨或 Blender Rigify；動作改用 Quaternius |
| Sketchfab 停止免費下載 | 少一個暫代素材來源 | 原始檔都留底；改用其他 CC0 來源 |
| Tripo 免費額度不夠 | 素材做得慢 | 分批做；或改用付費方案（你決定） |
| Tripo 免費方案的權利 | 不能商用或公開發佈 | 只個人自用；要公開時用付費方案重新產生 |
| AI 模型的拓撲很亂 | 變形難看、減面後破洞 | 重拓撲＋烘焙（第 8.1 節第 6 步）；仍然不行就重新生成 |
| 共用頭部和身體的接縫、膚色對不上 | 脖子看得出接縫 | M2 先試做；不行就退回每個職業自帶頭部（第 9.2 節） |
| Tripo 的頭髮像一整塊 | 不夠寫實 | 改用 MPFB2 的髮片髮型 |
| 半透明的果凍 | Tripo 做不出透明材質 | 在 Godot 用材質做（07） |
| Godot 匯入 FBX 動作有問題 | 動作不能用 | 改用 Blender 轉成 glb |
| Blender 5.2 的 Python API 變動 | 腳本出錯 | M2 先跑一次測試模型；Blender 5.0 的變動主要在 UV 選取、骨頭選取、渲染通道名稱，跟管線關係不大 |
| LFS 的容量越來越大 | 硬碟空間 | 原始檔一定留，成品縮小；遠端備份之後再設（01 第 13.5 節） |
| 跟 Gravity 或其他作品太像 | 版權疑慮 | 第 4 節的清單之後討論；個人自用 |

---

## 18. 待你確認事項

> 2026-10-10 你回覆「全部照建議」，以下 10 項都照建議定案。

| # | 事項 | 建議 |
|---|---|---|
| 1 | 共用頭部的來源 | 用 MPFB2（CC0）。00-A11 寫的是「Tripo 等 AI 工具」，MPFB2 不是 AI 工具；理由是眼睛、睫毛、牙齒分開、拓撲固定，之後才做得了表情和臉型。也可以全部用 Tripo，但每個職業的臉會跟著身體，換職業就換臉 |
| 2 | 髮型 | 四張女性概念圖的髮型做成 4 種可以選的髮型，換職業不換髮型（跟 RO 一樣）；第一版預設哪一種由 05 定 |
| 3 | 概念圖上的配件 | 頭盔、頭巾、緞帶做成頭飾；身體上的武器、劍鞘、盾牌拿掉 |
| 4 | Tripo 方案 | 先用免費方案（個人自用可以）；額度不夠時再考慮付費。要公開發佈或商用前，一定用付費方案重新產生 |
| 5 | LOD | 照原決定由 Blender 產生；M2 跟 Godot 自動 LOD 比較後再決定（第 8.3 節） |
| 6 | 貼圖和 glb 分開存 | glb 只放網格、骨架、動作，貼圖是獨立的 PNG，材質是 Godot 的 `.tres`（04-D10） |
| 7 | 動作的匯入 | Mixamo 的 FBX 動作直接用 Godot 內建的匯入，不經過 Blender |
| 8 | 第一版的武器和盾牌 | 每種先做第 1 款，加上服事的神聖權杖和學徒圓盾，共 7 件（第 13.3 節） |
| 9 | Quaternius 完整版（付費） | 先用免費版；Mixamo 不能用、動作不夠時再決定 |
| 10 | 預算數字 | 照第 12 節，M1～M2 實測後修正 |

---

## 19. 需要修改已確認文件的地方

2026-10-10 你同意後，03 已照下表改好，狀態列也註明了修訂日期。

| 文件 | 位置 | 現在的寫法 | 建議改成 | 理由 |
|---|---|---|---|---|
| 03 | 第 10.1 節 `origin` 的值 | polyhaven、ambientcg、mixamo、sketchfab、tripo、quaternius、google_fonts、original、other | 加上 `makehuman` | 共用頭部和髮型來自 MPFB2（MakeHuman） |
| 03 | 第 10.2 節第 3 條（允許的授權） | 「…以及 04 查證後加入的 Tripo 授權」 | 寫明 `LicenseRef-Tripo-Free`、`LicenseRef-Tripo-Paid` | 04-D04 查證的結果；03 原本就預留給 04 填 |

另外，`docs/environment-setup.md` 不是規劃書，以下只是建議（照計畫，不直接修改）：
- 第 1.3 節的 Tripo 免費額度（「每月約 300 credits、15 次下載」）改成「以官網為準（2026 年約每月 200～300 點）；免費方案的模型公開、不能商用」。
- 第 8 節第 2～3 步改成：先請我切好概念圖的視角圖（04 第 7 節），用多視角生成，角色要分件，下載的檔案照 04 第 6.2 節的檔名投遞。

---

## 20. 與 RO 原制不同之處（待檢視）

本文件只處理美術和素材流程，沒有改變 RO 的機制：
- 角色是寫實 3D 模型，不是 RO 的 2D sprite，這是 00-A01 的前提。
- 造型照概念圖（00-S12、00-A02 原創換皮），不照 RO 的 sprite；相似的地方列在第 4 節。
- 換職業只換服裝、頭和髮型不變，跟 RO 一樣。
- 身上不顯示收起來的武器，跟 RO 一樣。

---

## 21. 與 00 決策對照

| 00 決策 | 本文件對應 |
|---|---|
| 00-A02 原創換皮 | 第 4 節（相似清單）；名稱不用 Gravity 的 |
| 00-A03 寫實、3070 Ti 1080p/60 | 04-D01、04-D16、第 12 節 |
| 00-A07 第一版陣容 | 第 13 節 |
| 00-A08 動作 | 04-D13、04-D14（來源；清單在 05） |
| 00-A09 裝備外顯 | 第 13.2、13.3 節 |
| 00-A10 外觀自訂預留 | 04-D11、第 9 節（共用頭部、可換髮型、保留 blendshape） |
| 00-A11 素材 | 全文；共用頭部的來源見第 18 節第 1 項 |
| 00-A12 Git LFS | 04-D05、第 6 節 |
| 00-S03 先做女性 | 第 13.1 節 |
| 00-S06 全英文 | 04-D06（投遞檔名）、`process.json`、切圖設定、提示詞 |
| 00-S08 FF14 參考 | 04-D01 |
| 00-S09、00-S11 版本 | Blender 5.2.2 LTS；MPFB 2.0.17（支援 Blender 4.2 以上）；Godot 4.7.2 內建 FBX 匯入 |
| 00-S12 概念圖 | 第 3、4、7、13、14 節 |
| 00-S14 不照抄 RO 舊做法 | 本文件沒有沿用 RO 的技術做法 |

其他 00 決策跟素材管線沒有直接關係，由其他文件處理。

---

## 22. 參考來源

**素材來源與授權**
- Tripo 官方功能頁（免費方案模型公開、標示 CC BY 4.0；付費方案私人）：https://www.tripo3d.ai/features/image-to-3d-model
- Tripo 說明文件：免費方案的產出權利保留給 Tripo（服務條款第 5.2.1 條）、付費方案可以商用：https://www.tripo3d.ai/help/privacy-policy/how-to-use-tripo-models-commercially
- Tripo 部件分割（輸出一個 glb、內含有名字的部件）：https://developers.tripo3d.com/en/docs/mesh-segment.md
- Tripo 價格（第三方整理，2026 年 5 月和 8 月調整過）：https://costbench.com/software/ai-3d-generation/tripo-ai/
- Mixamo 常見問題（Adobe）：https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html
- Mixamo 在 2026 年的狀況（第三方整理：只維護、2025 年 6 月起偶爾故障）：https://app.cinevva.com/guides/free-character-animations-rigging
- Sketchfab 移轉到 Fab 的說明：https://sketchfab.com/blogs/community/sketchfab-update-what-you-need-to-know-now-that-fabs-live/
- Sketchfab 下載 API 的規範（CC 授權、署名）：https://sketchfab.com/developers/download-api/guidelines
- Poly Haven 授權（CC0）：https://polyhaven.com/license
- ambientCG 授權（CC0）：https://docs.ambientcg.com/license/
- MakeHuman 授權（核心素材 CC0）：https://static.makehumancommunity.org/about/license.html
- MPFB 常見問題（可以用在不開源的遊戲裡）：https://static.makehumancommunity.org/mpfb/faq/use_in_closed_source.html
- MPFB 版本（2.0.17，支援 Blender 4.2 以上）：https://extensions.blender.org/add-ons/mpfb/versions/
- Quaternius Universal Animation Library（CC0）：https://quaternius.com/packs/universalanimationlibrary.html
- Noto Sans TC（OFL）：https://fonts.google.com/noto/specimen/Noto+Sans+TC

**Godot 4.7**
- 3D 場景的匯入設定（LOD、陰影網格、切線、匯入腳本、動作庫、貼圖的處理方式）：https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/importing_3d_scenes/import_configuration.html
- 網格 LOD（meshoptimizer、預設開啟、骨架網格偶爾出問題）：https://docs.godotengine.org/en/4.7/tutorials/3d/mesh_lod.html
- 骨架重定向（BoneMap、SkeletonProfileHumanoid、A 字姿勢要開 Fix Silhouette）：https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/retargeting_3d_skeletons.html
- Godot 4.3 起內建的 FBX 匯入（ufbx）：https://godotengine.org/article/introducing-the-improved-ufbx-importer-in-godot-4-3/
- Godot 4.7 版本重點（沒有匯入相關的變動）：https://godotengine.org/releases/4.7/

**Blender**
- Blender 5.0 的 Python API 變動：https://developer.blender.org/docs/release_notes/5.0/python_api/
