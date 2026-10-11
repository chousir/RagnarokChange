# 04 美術與素材管線

> 狀態：已確認（2026-10-10）
> 建立日期：2026-10-10
> 依據：`docs/00-decisions.md`、`docs/01-architecture.md`、`docs/02-networking.md`、`docs/03-data-formats.md`
> 決策編號格式：`04-Dxx`
> 修訂：2026-10-10，第 11 節加上 Use Named Skins（依你的授權先照建議定案，見 05 第 16 節）
> 修訂：2026-10-11，依 `docs/proposals/`（最終決定在 `2026-10-11-replies.md`）大幅修改：素材以套用現成的免費素材為主（00-S16）、白名單擴大、授權放寬、待替換清單（04-D03、04-D19、第 5 節）；Tripo 不用了，3D 改用 Colab 的 Hunyuan3D-2（04-D04、04-D07、04-D11、第 7、9、14 節）；2D 圖和背景音樂用 Gemini；新增音訊的處理（04-D20、第 8.4 節）；畫面精緻度以 Road to Vostok 為準（04-D01）；相似清單、怪物尺寸、小樹精的骨架、第一版素材清單照新的概念圖改（第 3、4、10、13 節）

---

## 1. 目的與範圍

**本文件決定：**
- 美術方向，以及概念圖怎麼用（含跟 Gravity 等作品相似的清單）
- 素材來源和授權規則、「先套用現成的」的做法、待替換清單
- `assets/` 的目錄、投遞檔名
- 概念圖怎麼變成 3D 生成（Colab 的 Hunyuan3D-2）的輸入
- Blender 背景處理流程（清理、減面、重拓撲、LOD、貼圖、匯出、登記、報告）和音訊的處理
- 人形角色流程（共用頭部、依職業的身體、可換髮型、Mixamo 綁骨、Godot 重定向）
- 非人形怪物的骨架做法
- Godot 匯入設定
- 面數、貼圖、材質的預算
- 第一版素材清單

**不在本文件：**

| 內容 | 文件 |
|---|---|
| 角色怎麼組合、掛點、頭髮顯示模式、動作清單、外觀參數 | 05 |
| 怪物的程序化動畫、AI | 07 |
| 地圖佈局、地形、植被系統、光照、觀測點 | 08 |
| UI、特效、字型、音效的使用方式 | 10 |
| 每一批做哪些素材 | 11 |
| 提示詞（給 Gemini 和 Colab 的） | `docs/proposals/2026-10-10-art-prompts.md`（圖、3D）、`docs/proposals/2026-10-11-audio-and-quests.md` 第 2.5 節（背景音樂） |

---

## 2. 決策摘要

| 編號 | 決策 | 理由／對應 00 |
|---|---|---|
| 04-D01 | 美術方向是寫實 PBR（金屬度／粗糙度），精緻度以 Road to Vostok 的電影寫實為目標。內容和佈局以 `ConceptArt/` 為準；概念圖沒畫到的部分，質感和細節密度參考 FF14，但不複製 FF14 的設計。 | 00-S08、00-S12、00-S17。 |
| 04-D02 | 跟 Gravity（以及其他作品）相似的設計照圖做，列在第 4 節，之後再討論。 | 00-S12。 |
| 04-D03 | **素材以套用現成的免費素材為主**：場景、建築、道具、植被、圖示、音效都先找別人做好、可以合法使用的，先做出一版；之後再列出要調整或自己做的（待替換清單，04-D19）。白名單擴大成任何適合本案、可以合法取得的免費來源（第 5.1 節），每個來源第一次用之前先查條款。授權放寬：收 NC、SA；ND 只有原樣使用時才收。不收：從其他遊戲（包含 RO）抽出來的素材、來路不明的轉載、條款限定只能用在別的引擎的素材。不買付費素材。 | 00-S16（2026-10-11 改，原本是「只用少數白名單、自己生成為主」）。 |
| 04-D04 | AI 生成：3D 用你的 Colab（`chousir/colab-ImageTo3D`，Hunyuan3D-2），2D 圖（概念圖、圖示、載入畫面）和背景音樂用 Gemini（付費方案）。授權各自登記（第 5.2 節）：Hunyuan3D-2 的產出騰訊不主張權利，但有地區限制；Gemini 先當個人自用。Tripo 不用了，只留在白名單當備案。 | 00-S16；Tripo 免費方案只有 H2.5、品質不夠（你的回覆，2026-10-11）。 |
| 04-D05 | 目錄：`assets/_inbox/`（投遞，不進 Git）、`assets/_source/<類別>/<id>/`（原始檔留底，LFS）、`assets/<類別>/<id>/`（成品）。成品和原始檔用同一個 id。 | 00-A11、01 第 9 節、03 第 5 節。 |
| 04-D06 | 投遞檔名是 `<來源>-<類別>-<名稱>.<副檔名>`，全英文。檔名不對或資料不齊全，我會改名並問你缺的資訊。 | 00-S06；登記表需要來源資訊。 |
| 04-D07 | 3D 生成的輸入是一張乾淨的**正面圖**（從概念圖切出來，或用 Gemini 照概念圖生成），左、後、右由 Colab 的 MV-Adapter 自動產生；Colab 停在視角檢查，確認後才生成形狀和貼圖。 | 你只要給正面圖；Hunyuan3D-2mv 用正、左、後三張做形狀。 |
| 04-D08 | Blender 背景處理流程：匯入 → 清理 → 尺寸和方向 → 切除（角色的頭、黏在身上的配件）→ 減面（必要時重拓撲＋烘焙）→ UV 檢查 → LOD → 貼圖 → 匯出 → 登記 → 預覽圖和報告。每一步都從原始檔重做，參數寫在 `process.json`。現成素材和生成的素材走同一條管線。 | 00-A11；可以重跑，參數改了也能重新產生。 |
| 04-D09 | LOD 照你原本的決定由 Blender 產生（LOD0～LOD2），Godot 匯入時關閉自動 LOD，由匯入腳本設定可見距離。Godot 自動 LOD 的比較列在第 8.3 節，M2 用同一個模型比較後再決定要不要換。 | 00-A11。 |
| 04-D10 | 模型匯出成 glb（網格、骨架、動作、blendshape），貼圖另外存成 PNG，材質由 Godot 的 `.tres` 管理。glb 裡不嵌貼圖。 | 貼圖不會存兩份；每張貼圖可以單獨設定壓縮方式。 |
| 04-D11 | 人形角色：一個共用頭部（每個性別一個）＋依職業的身體＋可換的髮型。身體用 Colab 照概念圖生成，管線在脖子切掉頭；頭部用 MPFB2（CC0）；髮型用 MPFB2 的 CC0 髮型，或用髮型的正面圖在 Colab 生成。 | 05 的大綱已定：換職業只換 Body，頭和頭髮不變（跟 RO 一樣）。共用頭部才能做 00-A10 的 blendshape。Hunyuan3D 不會分件。 |
| 04-D12 | 綁骨照你原本的決定用 Mixamo：身體、頭、頭髮合併成一個網格上傳，下載綁好的 FBX，腳本再把骨架和權重轉回分開的網格（保留 blendshape）。Mixamo 不能用時，改用 Blender Rigify。 | 00-A11；Mixamo 只維護不開發，要有備案。 |
| 04-D13 | 所有人形骨架在 Godot 用 BoneMap＋SkeletonProfileHumanoid 統一，動作共用。Mixamo 的動作直接用 Godot 內建的 FBX 匯入，不經過 Blender。 | Godot 4.3 起內建 FBX 匯入；少一次轉檔就少一個出錯的地方。 |
| 04-D14 | 動作以 Mixamo 為主，Quaternius Universal Animation Library（CC0）為輔，也是 Mixamo 的備案。下載的動作一律留底。 | Mixamo 隨時可能無法使用。 |
| 04-D15 | 非人形怪物不用 Mixamo：腳本建立骨架（小樹精是樹幹、手臂、樹根、樹冠），或乾脆不用骨架（果凍怪用頂點變形）。細節依 07。 | 00-A11；新的小樹精概念圖不是人形。 |
| 04-D16 | 面數、貼圖、材質數量有預算表（第 12 節），暫定值在 M1～M2 實測後修正。現成素材也要符合預算，超出的由管線減面或列進待替換清單。 | 00-A03、00-S15、01 第 14 節的效能預算。 |
| 04-D17 | 每個處理完的素材都輸出轉台預覽圖和報告。我先看過，再請你看。 | 00-A13、01-D11。 |
| 04-D18 | 授權資料不齊全時，管線停下來問你，不亂填；登記表由管線寫入（03-D23）。 | 00-A11。 |
| 04-D19 | **待替換清單**：跟概念圖不同、授權限制公開或商用、品質不夠的素材，在登記表標上原因（03 第 10 節的 `replacement`）；每個里程碑結束時從登記表產生一份清單給你，之後再討論怎麼換。 | 00-S16。 |
| 04-D20 | 音訊：背景音樂你用 Gemini 生成，環境音、腳步、怪物、打擊、技能、介面的音效我找現成的（你也可以放）。全部轉成 OGG Vorbis、統一音量、做好循環（第 8.4 節）。 | 00-S16；10 的音效規劃。 |

---

## 3. 美術方向

**依據：** `ConceptArt/` 的 23 張圖（2026-10-10、2026-10-11 換過幾張：魔物、NPC、兩張地圖、王都鳥瞰圖；中文名稱見 `ConceptArt/README.md`）。

| 項目 | 方向 |
|---|---|
| 整體 | 電影寫實（00-S17）：寫實的 PBR 材質（皮革、布、金屬、石頭、木頭都有磨損和髒污），寫實的光影和大氣（08），人物比例寫實、五官略為理想化，跟概念圖一樣 |
| 角色 | 照四個職業的三視圖。概念圖是 A 字姿勢，模型也維持 A 字姿勢 |
| 怪物 | 照魔物三視圖：寫實的材質（果凍的半透明和發光核心、毛絨的毛、樹皮和青苔）配上可愛的造型 |
| 武器、盾牌 | 每種各有 4 款（學徒、衛兵、聖騎士或神職、皇家），圖上標了實際尺寸（例如短劍 35～45 公分、單手劍 85～95 公分、盾牌 30～105 公分），模型照這個尺寸 |
| 地圖、建築 | 地圖圖是佈局（08 用），建築圖是氣氛和細節的參考；第一版的外觀先用現成素材，跟圖不同的列進待替換清單 |
| 現成素材 | 挑最接近概念圖、寫實程度夠的；混用不同來源時，用共用的材質、顏色校正和光照讓整體一致 |
| 概念圖沒畫到的 | 質感和細節密度參考 FF14 和 Road to Vostok，造型不複製 |

**尺寸基準（1 單位 ＝ 1 公尺，03-D16）：**

| 物件 | 尺寸 | 備註 |
|---|---|---|
| 女性角色 | 身高約 1.65 m | 05 可以依職業微調（例如初心者看起來比較年輕） |
| 男性角色 | 身高約 1.78 m | 00-S03 只預留 |
| 武器、盾牌 | 照概念圖標的尺寸 | 沒標的照同類型推算 |
| 怪物 | 果凍怪直徑約 0.5 m；毛絨蟲長約 0.8 m、高約 0.4 m；小樹精高約 1.3 m（樹冠頂端）；可愛兔之後再定 | 07 第 3 節 |

---

## 4. 跟 Gravity 等作品相似的地方（之後討論）

依 00-S12，下表的設計先照圖做，之後再跟你討論要不要改、怎麼改。我不會自己改造型。「程度」是我的主觀判斷（2026-10-11 依新的概念圖更新）。

| 概念圖 | 相似的對象 | 程度 | 說明 |
|---|---|---|---|
| `map-kronenberg.jpg` | RO 的普隆德拉 | 低 | 「北邊城堡、南門通往野外、西邊教堂」的大方向還在；但改成河口的港口城市，形狀、街道、地標都不一樣 |
| `map-kronenberg_south_field.jpg` | RO 的普隆德拉南邊野外（prt_fild08）和往依斯魯得的橋 | 中 | 「王都南門外的草原、東邊跨海的大橋通往另一座城市、南邊接沙漠」跟 RO 的地理配置很接近；劍士訓練營地也會讓人聯想到 RO 劍士公會所在的港口城市。路網、高台、漁村、營地的細節是新的 |
| `building-kronenberg.jpg` | — | 移除 | 舊圖的 Prontera Square 標題、噴水池、騎士像都沒有了 |
| `monster-gelly.jpg` | RO 的波利（Poring） | 低 | 「粉紅色、有臉的果凍」這個大類還在；造型改成圓球、半透明、發光核心、嘟嘴 |
| `monster-fluffy_caterpillar.jpg` | RO 的 Fabre | 低 | 綠色毛毛蟲是常見題材，標題也不是 Fabre 了 |
| `monster-cute_bunny.jpg` | RO 的 Lunatic | 低 | 兔子是常見題材；垂耳、葉冠、鈴鐺是新的設計 |
| `monster-young_treant.jpg` | RO 的 Willow；Marvel 的 Baby Groot | 中（Willow）／解除（Baby Groot） | 「有臉的樹樁怪」是很常見的題材，但 RO 的 Willow 也是樹幹加上臉和頭頂的枝葉，同一類；跟 Baby Groot 已經不像 |
| `npc-adventurer_guild_staff.jpg` | RO 的卡普拉職員（Kafra） | 中高 | 藍色洋裝加白圍裙加頭飾的配色和輪廓接近；之後服務員也當儲存點和倉庫，功能也跟卡普拉一樣。披肩、皮帶、鑰匙、沙漏徽章和組織名稱「卡德威爾」是新的。想再拉開距離的話，可以換主色（例如墨綠或酒紅）或把圍裙改成罩袍 |

- 遊戲裡的名稱不用 Gravity 的名字（`ConceptArt/README.md`），這部分不變。
- 角色、武器、盾牌的概念圖沒有看到明顯照搬的設計，沒有列入。
- 現成素材也照這個原則：不用從其他遊戲抽出來的素材，也不用明顯模仿 RO 的造型。

---

## 5. 素材來源與授權

### 5.1 來源（白名單）

任何適合本案、可以合法取得的**免費**來源都可以加進來（00-S16）。下表是目前查過的；新來源第一次用之前，我先查條款，把授權代碼和規則補進這張表（加表不用另外問你，但會在報告裡列出）。

| 來源 | 用途 | 授權代碼（03 第 10 節） | 規則 |
|---|---|---|---|
| Poly Haven | HDRI 天空、材質貼圖、模型（樹、石頭、道具） | `CC0-1.0` | 可以自由使用和修改 |
| ambientCG | 材質貼圖 | `CC0-1.0` | 同上 |
| MakeHuman（MPFB2 外掛） | 共用頭部、眼睛、睫毛、牙齒、髮型 | `CC0-1.0`（核心素材） | 只用核心素材；第三方素材包另外判斷。外掛本身是 GPL，只是工具 |
| Quaternius | 動作（Universal Animation Library）、部分模型 | `CC0-1.0` | 免費版只有一部分動作 |
| Kenney | 介面、圖示、音效、部分模型 | `CC0-1.0` | — |
| Sketchfab | 模型（建築、道具、植被、場景） | 照模型頁：`CC0-1.0`、`CC-BY-4.0`、`CC-BY-NC-4.0`、`CC-BY-SA-4.0` 等 | 只收免費下載的；記下作者和署名；下載後一定留底（Sketchfab 的免費下載隨時可能停止） |
| Fab（Epic） | 模型、材質（包含掃描素材） | 照素材頁的授權 | 只收免費的；標成只能用在 Unreal 的不收；登記前查該素材的授權條款 |
| BlenderKit | 模型、材質 | 照素材頁（例如 Royalty Free、`CC0-1.0`） | 只收免費的 |
| CGTrader、itch.io | 模型、圖示、音效包 | 照素材頁 | 只收免費、授權寫清楚的 |
| OpenGameArt | 模型、圖示、音效 | 照每個檔案：`CC0-1.0`、`CC-BY-*`、`CC-BY-SA-*` 等 | 每個檔案各自確認 |
| game-icons.net | 圖示 | `CC-BY-3.0` | 要署名 |
| Freesound | 音效、環境音 | 照每個音效：`CC0-1.0`、`CC-BY-4.0`、`CC-BY-NC-4.0` | 不收 Sampling+；CC-BY 記作者 |
| Sonniss 的 GDC 免費音效包 | 音效 | `LicenseRef-Sonniss-GDC` | 可以用在遊戲裡；原始檔不能再散布（`no_source_redistribution`）；登記前再核對一次條款 |
| Mixamo | 人形自動綁骨、動作 | `LicenseRef-Mixamo` | 可以用在遊戲裡，不能把原始檔再散布 |
| Colab 的 Hunyuan3D-2 | 照概念圖生成 3D 模型 | `LicenseRef-Tencent-Hunyuan3D-2-Community` | 見第 5.2 節 |
| Gemini（付費方案） | 概念圖、正面圖、2D 素材（圖示、載入畫面）、背景音樂 | `LicenseRef-Google-Gemini` | 見第 5.2 節 |
| Tripo（備案） | 3D 生成 | `LicenseRef-Tripo-Free`、`LicenseRef-Tripo-Paid` | 不再是主要工具；真的要用時用付費方案（第 5.2 節） |
| Google Fonts | Noto Sans TC（之後的其他語言字型） | `OFL-1.1` | 字型檔放在 `assets/fonts/` |
| 自製 | 腳本產生的貼圖、Blender 程序化模型、佔位外觀 | `LicenseRef-Original` | — |

**授權的規則（2026-10-11 放寬）：**

| 授權 | 收不收 | 登記的限制標記（03 第 10 節） | 待替換 |
|---|---|---|---|
| CC0、CC-BY、OFL、各來源的免費商用授權 | 收 | CC-BY 要記作者和署名 | 不用 |
| NC（不可商用） | 收 | `non_commercial` | 標 `license_blocks_release`（公開或商用前要換） |
| SA（改作要用同授權） | 收 | `share_alike` | 公開時改作也要用同授權；個人自用沒影響 |
| ND（不可改作） | 只有原樣使用（不減面、不改貼圖）時才收；管線一般會改作，所以很少用 | `no_derivatives` | — |

**不收的：**
- 從其他遊戲抽出來的素材，包含 RO 的圖示、圖片、模型、音效（00-A02、00-S16）。
- 來路不明的轉載（例如把付費素材免費放出來的網站）。
- 條款限定只能用在別的引擎的素材。
- 付費素材（00-S16：不買）。

### 5.2 AI 工具的授權（04-D04）

| 工具 | 授權代碼 | 條款的重點 | 本專案的用法 |
|---|---|---|---|
| Colab 的 Hunyuan3D-2（Tencent Hunyuan 3D 2.0 Community License；產生視角用的 MV-Adapter 是 Apache-2.0，底層的 SDXL 是 CreativeML Open RAIL++-M） | `LicenseRef-Tencent-Hunyuan3D-2-Community` | 騰訊不主張產出的權利；不能用產出改進其他 AI 模型；條款不適用於歐盟、英國、韓國（產出也不能在這些地區使用或展示）；月活躍使用者超過 100 萬要另外申請 | 你在台灣自用可以。登記加 `territory_excludes_eu_uk_kr` 和 `generation`（Colab 輸出的 `.json`：模型版本、種子），待替換標 `license_blocks_release`（要在歐盟、英國、韓國公開時才要換） |
| Gemini（付費方案） | `LicenseRef-Google-Gemini` | 音樂只能下載 MP3；Google 沒有公開的商用說明（2026-10 查詢） | 先當個人自用：登記加 `personal_use_only`、方案、`generation`（提示詞），待替換標 `license_blocks_release`。要公開前再查條款 |
| Tripo（備案） | `LicenseRef-Tripo-Free`、`LicenseRef-Tripo-Paid` | 免費方案的產出公開、條款保留權利、不能商用（服務條款第 5.2.1 條）；付費方案可以商用 | 不再用；真的要用時用付費方案，登記方案等級 |

### 5.3 先套用現成的（04-D03）

每需要一個物件，照這個順序：

```text
1. 找現成的免費素材（第 5.1 節的來源）
     先找 CC0（Poly Haven、ambientCG、Quaternius、Kenney），再找其他（Sketchfab、Fab、BlenderKit、CGTrader、itch.io、OpenGameArt）
     挑最接近概念圖、寫實程度夠、面數和貼圖做得到預算的
2. 找不到，或跟概念圖差太多 → 用 Colab 生成（你用 Gemini 生成正面圖，或從概念圖切）
3. 可以重複組合的東西（城牆段、房屋的牆和屋頂、棧橋）找不到合適的套件 → 用 Blender 腳本做模組
4. 不管哪一種，跟概念圖不同的地方都列進待替換清單（第 5.4 節）
```

- 需要登入才能下載的來源（Fab、Sketchfab、BlenderKit 等）：我列出要下載的清單（網址、選哪個檔案），你下載後丟進 `assets/_inbox/`；不用登入的我直接下載。
- 角色、怪物、武器、頭飾這類照概念圖、幾乎不可能找到現成的，直接走第 2 步。
- 每個素材的成品一樣走第 8 節的管線、一樣要符合第 12 節的預算。

### 5.4 待替換清單（04-D19）

| 項目 | 做法 |
|---|---|
| 標記 | 登記表的 `replacement`（03 第 10 節）：`differs_from_concept`（跟概念圖不同）、`license_blocks_release`（授權限制公開或商用）、`quality`（品質不夠）。管線處理時我依情況標上；你看截圖覺得不行的，我也標上 |
| 產生 | 每個里程碑結束時，從登記表自動產生 `artifacts/review/<里程碑>/replacement_list.md`：素材、原因、建議的做法（換別的現成素材、Colab 生成、Gemini、Blender 腳本）、優先順序 |
| 討論 | 清單給你看，之後再一起決定要換哪些、什麼時候換（11） |

### 5.5 通用規則

- 只用第 5.1 節的來源；新來源查過條款再加進表裡。
- 下載的原始檔一律放進 `_source/` 留底（LFS），來源網站之後不見了也能重新處理。
- `ConceptArt/` 是參考圖，不是遊戲素材，不用登記（03 第 10.2 節）；給 Colab 的正面圖和自動產生的視角圖存在 `_source/<類別>/<id>/views/`，跟模型一起登記。
- 提示詞不能出現遊戲、公司、作品、角色、畫家的名字（`docs/proposals/2026-10-10-art-asset-guide.md` 第 3.3 節）；生成的結果很像某個知名作品時不用。

---

## 6. 目錄與投遞

### 6.1 目錄

```text
assets/
  _inbox/                     投遞區（.gdignore，不進 Git，只留一個佔位檔）
  _source/<類別>/<id>/        原始檔留底（.gdignore，LFS），加上 process.json（處理參數）；生成的素材另外有 views/（正面圖和視角圖）
  characters/<id>/            職業服裝（身體）、共用頭部、髮型、NPC
  equipment/<id>/             武器、盾牌、頭飾
  monsters/<id>/
  environment/<id>/           建築、城牆、大型地形物件、船
  props/<id>/                 小道具
  animations/<組>/            動作庫（例如 human_common、weapon_dagger）
  textures/<id>/              共用的材質貼圖（Poly Haven、ambientCG）
  materials/                  共用材質（.tres）
  vfx/  ui/  fonts/
  audio/
    music/<id>.ogg            背景音樂（地圖 ID、title、character_select）
    ambience/<id>.ogg         環境音
    sfx/<類別>/<id>.ogg       音效（footstep、monster、combat、skill、ui）
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
| 跟登記表的 `origin` 一樣（03 第 10.1 節）：hunyuan3d2（Colab，登記成 `hunyuan3d`）、gemini、mixamo、makehuman、polyhaven、ambientcg、sketchfab、fab、blenderkit、cgtrader、itchio、opengameart、kenney、quaternius、freesound、sonniss、game_icons、google_fonts、tripo、original | character、equipment、monster、environment、prop、animation、texture、hdri、font、ui、vfx、music、ambience、sfx | `hunyuan3d2-character-novice_female.glb`（Colab 的輸出本來就是這個格式，加上同名的 `.json`）、`gemini-music-kronenberg.mp3`、`gemini-ui-skill_bash.png`、`sketchfab-environment-<名稱>.glb`、`mixamo-animation-sit_down.fbx`、`polyhaven-texture-<名稱>.zip`、`kenney-sfx-<名稱>.zip` |

- 同一個東西有好幾版想給我比較，就加 `_a`、`_b`，例如 `gemini-music-kronenberg_a.mp3`。
- 你可以照舊用中文或其他檔名丟進來，我會照規則改名，並問你缺的資訊。
- 每種來源需要的資訊：

| 來源 | 需要你告訴我的 |
|---|---|
| Colab（Hunyuan3D-2） | 不用：輸出的 `.json` 有模型版本和種子；正面圖和視角圖（Colab 的 `in/` 裡 `used-` 開頭的檔案）一起丟進來 |
| Gemini | 用的提示詞（音樂、圖都要） |
| Sketchfab、Fab、BlenderKit、CGTrader、itch.io、OpenGameArt、Freesound | 素材頁面的網址（作者和授權我從頁面查） |
| Poly Haven、ambientCG、Kenney、Quaternius | 不用，我從檔名查 |
| Mixamo | 不用 |
| 其他 | 網址和你知道的授權資訊；查不到授權就不用 |

- 處理完的原始檔搬到 `_source/<類別>/<id>/`，`_inbox/` 清空。`_inbox/` 不進 Git，請另外備份一份。

---

## 7. 概念圖變成 3D 的輸入（04-D07）

```text
ConceptArt/character-novice_female.jpg（三視圖合在一張）
      │  我用切圖工具切出正面；或你用 Gemini 照概念圖生成一張乾淨的正面圖（提示詞在 art-prompts）
      ▼
正面圖 character-novice_female-front.png（Colab 的檔名規則：<類別>-<id>-front.png）
      │  放進 Google Drive 的 MyDrive/RagnarokChange/hunyuan3d/in/
      ▼
Colab：區塊 5 自動產生左、後、右 → 停下來給你檢查 → 換種子重來，或確認
      │  區塊 6 形狀（Hunyuan3D-2mv，用正、左、後）→ 區塊 7 貼圖 → 區塊 8 下載
      ▼
hunyuan3d2-<類別>-<id>.glb ＋ .json ＋ 視角圖 → 投遞到 assets/_inbox/
```

- **正面圖的要求**：只有一個物件、沒有文字和標籤、純色背景（透明 PNG 最好）、整個物件都在畫面裡；角色用 A 字姿勢、手指微張、不拿東西、不揹武器；光線平均，沒有強烈的高光和陰影。檢查清單和提示詞在 `docs/proposals/2026-10-10-art-asset-guide.md` 第 4.3 節和 `2026-10-10-art-prompts.md`。
- **切圖設定**：每張概念圖要切哪些物件、範圍，記在 `tools/concept_crops.json`（英文）；切圖工具用 Blender 背景模式。概念圖的正面常有文字、配件、漸層背景，所以通常用 Gemini 生成的乾淨正面圖效果比較好。
- **視角檢查**：Colab 自動產生的左、後、右跟概念圖不一致（例如配件跑到另一邊、背面糊掉）時，換種子重生；還是不行就用 P-02～P-04 的提示詞在 Gemini 生成，在 `in/` 裡取代 `used-<類別>-<id>-left.jpg`、`-back.jpg`、`-right.jpg`（區塊 6 讀這三個檔），再跑區塊 6。
- **武器、盾牌**：一張概念圖有 4 款，每一款分別做一張正面圖。
- **建築**：先找現成的（第 5.3 節）；獨一無二的地標（城門、大教堂、神像等）才用 Colab。

---

## 8. 處理流程（04-D08、04-D20）

### 8.1 步驟

用 `blender -b`（背景模式）執行，由 01 第 11.2 節的 `tools/scripts/inbox.ps1` 呼叫。現成素材和生成的素材走同一條。

| # | 步驟 | 內容 |
|---|---|---|
| 1 | 匯入 | glb、gltf、fbx、obj、blend。記錄原始檔的面數、貼圖和尺寸 |
| 2 | 清理 | 套用變換；合併重疊頂點（0.1 mm）；重新計算法線方向；刪掉孤立的點和邊、零面積的面；刪掉沒用到的材質 |
| 3 | 尺寸和方向 | 單位是公尺，縮放到 `process.json` 指定的尺寸（例如身高 1.65 m）。正面朝向 Blender 的 −Y，匯出後是 Godot 的 +Z（Godot 人形設定檔的標準方向）。原點規則見下表 |
| 4 | 切除 | 角色：在脖子的高度切掉頭（`process.json` 的 `neck_cut_height_m`），換成共用頭部（第 9 節）；黏在身上的武器、劍鞘、盾牌用包圍盒切掉，切不乾淨就請你重新生成正面圖。現成素材：拿掉不需要的部分（例如展示用的底座） |
| 5 | 減面 | 減到預算（第 12 節）。保留 UV 接縫和外輪廓 |
| 6 | 重拓撲＋烘焙（必要時） | 原始網格太亂、會影響變形時（AI 生成的角色、怪物通常需要），用 QuadriFlow 重建四邊面網格 → 重新展 UV → 從原始模型烘焙基本色、法線、AO |
| 7 | UV 檢查 | 檢查重疊和貼圖密度（texel density），寫進報告 |
| 8 | LOD | 產生 LOD1、LOD2（比例見第 12 節），命名 `<物件>_LOD1`、`<物件>_LOD2` |
| 9 | 貼圖 | 縮放到預算；打包 ORM（R＝AO、G＝粗糙度、B＝金屬度）；法線一律轉成 OpenGL 方向（Y 朝上）；存成 PNG。Hunyuan3D-2 只產生顏色貼圖：法線從原始網格烘焙，粗糙度和金屬度用 `process.json` 依材質區域給預設值（例如皮革 0.7、金屬 0.35／1.0） |
| 10 | 匯出 | glb（Y 朝上、套用修改器、含骨架和 blendshape、不嵌貼圖）＋貼圖 PNG |
| 11 | 材質和外觀設定 | 用 Godot 的 headless 工具腳本產生 `.material.tres` 和 `.visual.tres`（內容由 05、07 定） |
| 12 | 登記 | 寫入 `license_registry.json`（03 第 10 節），包含限制標記和待替換的原因 |
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
| cuts | 角色的 `neck_cut_height_m`；要切掉的部分（包圍盒） |
| material_defaults | 只有顏色貼圖時，各材質區域的粗糙度、金屬度 |
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

### 8.4 音訊的處理（04-D20）

由 `tools/scripts/inbox.ps1` 呼叫 ffmpeg（你已經安裝）：

| 步驟 | 內容 |
|---|---|
| 留底 | 原始檔搬到 `assets/_source/<music、ambience、sfx>/<id>/`（LFS），Gemini 的提示詞記在 `process.json` |
| 轉檔 | OGG Vorbis（品質約 6）、48 kHz；音樂和環境音是立體聲，3D 定位的音效是單聲道 |
| 音量 | 音樂和環境音統一到約 −16 LUFS；音效的峰值 −1 dBTP。換曲時不會忽大忽小 |
| 循環 | 背景音樂和環境音：切掉結尾的淡出，結尾跟循環起點做約 2 秒的交叉淡化，在 Godot 設好循環點（`loop_offset`）；你不用自己剪 |
| 登記 | 寫入登記表（Gemini 的音樂加 `personal_use_only`） |
| 報告 | 長度、音量、循環點；我先聽過循環的接縫 |

- 背景音樂第一版兩首：王都（`kronenberg`）、南方草原（`kronenberg_south_field`）；標題和選角之後。提示詞在 `docs/proposals/2026-10-11-audio-and-quests.md` 第 2.5 節。
- 環境音、音效的清單在第 13.7 節。

---

## 9. 人形角色流程

### 9.1 組成（04-D11）

```text
Skeleton3D（每個職業的身體各自綁一副，骨頭名稱統一）
  ├─ Body   依職業：novice_female、swordsman_female…（Colab 生成）
  ├─ Head   共用：head_female_01（MPFB2）
  ├─ Hair   可換：hair_twin_tails、hair_long_straight…（MPFB2 或 Colab）
  └─ 掛點   頭飾上中下、右手武器、左手盾牌（05）
```

- 換職業只換 Body，頭和頭髮不變，跟 RO 一樣（05 的大綱）。
- 概念圖上每個職業的臉和髮型都不一樣。遊戲裡的臉是共用的，四種髮型做成可以選的髮型。
- 頭和頭髮只綁在脖子和頭的骨頭上，所以可以套在任何一個職業的身體上。

### 9.2 流程

```text
1. 正面圖（A 字姿勢、頭髮盤起或短髮、不拿武器）→ Colab 生成身體 → 投遞
2. Blender：在脖子切掉頭；切掉黏在身上的武器、劍鞘、盾牌；必要時重拓撲＋烘焙
3. Blender：身體縮放到同一個身高、對齊脖子的位置，在脖子切齊共用頭部的接合處
4. Blender：身體＋共用頭部＋預設髮型合併成一個網格，匯出 FBX
5. 你：上傳到 Mixamo 自動綁骨（標記下巴、手腕、手肘、膝蓋、鼠蹊），下載 FBX（含骨架）→ 投遞
6. Blender：把骨架和權重從合併的網格轉回分開的網格（身體、頭、頭髮），保留 blendshape → 匯出 glb
7. Godot：BoneMap＋SkeletonProfileHumanoid；模型是 A 字姿勢，開啟 Fix Silhouette → 共用動作庫
```

- **為什麼要先合併再拆開**：Mixamo 一次只能綁一個角色，而且會丟掉 blendshape。所以先合併上傳，再把權重轉回原本分開的網格。
- **共用頭部（MPFB2）**：
  - 眼睛、睫毛、眉毛、牙齒都是分開的網格，拓撲固定，之後做眨眼、表情和臉型 blendshape（00-A10）都比較容易。
  - 臉照概念圖調整成寫實的年輕女性。皮膚材質可以用 MakeHuman 的 CC0 貼圖，或照概念圖重新烘焙。
- **髮型**：先用 MPFB2 的 CC0 髮片髮型（最穩定、可以上色）；跟概念圖差太多時，用髮型的正面圖（戴在灰色假人頭上，P-20～P-24）在 Colab 生成，管線拿掉假人頭。髮色用材質參數調整，所以頭髮的貼圖要先去色（05）。
- **配件**：初心者的背包、頭盔這類身上的配件，正面圖裡不畫，另外生成一個道具或頭飾，在 Blender 裝回去。
- **先做一個試做**：M2 先用初心者（女）走完整個流程，檢查脖子的接縫、變形和膚色。如果共用頭部的做法行不通，退回「每個職業的頭跟著身體」，先告訴你再改。

### 9.3 Mixamo 不能用時（04-D12）

| 備案 | 做法 | 缺點 |
|---|---|---|
| Blender Rigify | 腳本放骨架、自動計算權重 | 權重品質要人工檢查 |
| Tripo 自動綁骨（付費，最後的備案） | Tripo 產生骨架和權重，骨頭名稱不同，用 BoneMap 對應 | 要付費 |

### 9.4 動作（04-D13、04-D14）

- **Mixamo**：下載設定是 FBX Binary、Without Skin、30 fps、不做關鍵影格簡化。走路和跑步選 In Place（原地），因為移動由程式控制（01-D08）。
- **匯入**：Godot 4.3 起內建 FBX 匯入（ufbx），Mixamo 的動作直接匯入成 AnimationLibrary，套用同一個 BoneMap。Mixamo 每個動作檔裡的動作都叫同一個名字，匯入腳本會依檔名改名。
- **Quaternius Universal Animation Library**（CC0）：有自己的人形骨架，一樣用 BoneMap 對應。免費版只有一部分動作。
- 動作清單（普攻、暴擊、詠唱、坐下、撿東西、表情等，依武器分）在 05 定。

---

## 10. 非人形怪物（04-D15）

| 怪物 | 骨架的做法（細節在 07） |
|---|---|
| gelly（果凍怪） | 不用骨架，用頂點變形做彈跳、滾動和擠壓；半透明外殼、發光核心、體內的光點用材質和著色器做 |
| fluffy_caterpillar（毛絨蟲） | 腳本沿著身體自動建一串體節骨頭（頭加 5 節身體），加上觸角和每節的短腳；毛用貼圖加外殼（shell）著色器 |
| young_treant（小樹精） | **不是人形**：腳本建立骨架（樹幹 3 節、兩隻手各 3 節、4 條主根各 3 節、樹冠 4～6 條彈簧骨，短根不動）；移動時主根用 IK 輪流踏步。用概念圖上排的造型（下排的斷樁版本不做）；生成時樹根和手臂要分開，不要黏在樹幹上 |
| cute_bunny（可愛兔） | 不在第一版；之後做的時候用小型的兩足骨架，耳朵和鈴鐺用彈簧骨 |

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
| 網格的骨架綁定 | 開啟 Use Named Skins（用骨頭名稱綁定） | 頭和頭髮才能套到任何一副身體骨架上（05-D02） |
| 貼圖 | VRAM 壓縮（高品質）、產生 mipmap；法線貼圖用法線專用的壓縮格式 | 畫質和記憶體的平衡 |
| 材質 | 有 ORM 貼圖時用 ORMMaterial3D；頭髮用 alpha scissor 或 alpha hash，避免透明排序問題；布料和葉子可以雙面 | — |
| 點選用的碰撞 | 匯入腳本自動加上簡單的膠囊或方塊，放在客戶端專用的碰撞層；半徑照資料的 `body_radius_m`＋0.15 m（09） | 01 第 7.4 節、03 第 4.5 節 |
| 音訊 | OGG Vorbis；背景音樂和環境音開循環、設循環點 | 第 8.4 節 |
| 匯入腳本 | 每個類別一支 `EditorScenePostImport` 腳本（放在 `tools/import/`）：設定 LOD 的可見距離、對應材質、加碰撞、改名 | 不用手動在匯入視窗設定 |

---

## 12. 預算（04-D16，暫定）

目標顯卡是 RTX 4060（8 GB，00-S15、01 第 14 節）。現成素材也要符合預算，超出的由管線減面；減面後品質不夠的列進待替換清單。

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
| NPC | 跟角色相同 | | | 身體、頭、頭髮分開算 |
| 大型建築（城門、大教堂、城堡、宮殿） | 150,000（整棟，分模組） | 50% | 15% | 遠處的簡化做法在 08 |
| 一般房屋 | 30,000 | 50% | 15% | |
| 船（大帆船） | 40,000 | 50% | 15% | 帆和繩索用平面和貼圖 |
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
- 原始檔（例如現成素材的 4K、8K 貼圖）留在 `_source`，成品縮小到上表的大小；「電影」畫質（01 第 14 節）可以用比較大的貼圖，之後再定。
- 一個角色（身體、頭、頭髮）的貼圖約佔 40 MB 顯示記憶體，比 01 第 14 節的 6 GB 預算小很多。

### 12.3 材質數量

| 類別 | 上限 | 理由 |
|---|---|---|
| 職業身體 | 2 個 | 每個材質就是一次 draw call |
| 頭部 | 3 個（皮膚、眼睛、睫毛和眉毛） | — |
| 髮型、武器、盾牌、頭飾、怪物 | 1～2 個 | — |
| 現成的建築、道具 | 盡量換成共用材質（第 3 節） | 整體一致、draw call 少 |

---

## 13. 第一版素材清單

ID 是暫定，正式的 ID 由 05、07 定，資料用的 ID 照 03 的規則。各項的提示詞和生成注意事項在 `docs/proposals/2026-10-10-art-asset-guide.md` 第 6、7 節（寫 Tripo 的地方改用 Colab）。

### 13.1 人形角色（女性，00-S03）

| ID | 內容 | 來源 | 概念圖 |
|---|---|---|---|
| `head_female_01` | 共用女性頭部（含眼睛、睫毛、眉毛、牙齒） | MPFB2 | 四張女性角色圖的臉（取共同的特徵） |
| `novice_female` | 初心者服裝 | Colab | `character-novice_female.jpg` |
| `swordsman_female` | 劍士服裝 | Colab | `character-swordsman_female.jpg` |
| `thief_female` | 盜賊服裝 | Colab | `character-thief_female.jpg` |
| `acolyte_female` | 服事服裝 | Colab | `character-acolyte_female.jpg` |
| `hair_twin_tails` | 低雙馬尾 | MPFB2 或 Colab | 初心者 |
| `hair_long_straight` | 長直髮 | 同上 | 劍士 |
| `hair_ponytail` | 長馬尾 | 同上 | 盜賊 |
| `hair_short_tied` | 短髮綁小馬尾 | 同上 | 服事 |

- 身體服裝保留衣服、腰帶、腰包；初心者的背包另外做成道具裝回去；拿掉武器、劍鞘、盾牌和頭上的東西（RO 也不顯示收起來的武器）。
- 男性的概念圖（四張）先不做，骨架和資料格式已經預留（00-S03）。
- NPC（冒險公會的服務員 `adventurer_guild_staff`）在 M8 做，流程跟角色一樣；訓練營地的教官先用同一個模型。

### 13.2 頭飾

| ID | 內容 | 來源 | 概念圖 |
|---|---|---|---|
| `novice_helmet` | 初心者的鐵盔（頭飾上段） | Colab | 初心者 |
| `bandana` | 頭巾（頭飾上段） | Colab | 盜賊（女） |
| `ribbon` | 緞帶（頭飾上段） | Colab | 服事（女） |

### 13.3 武器和盾牌

每種武器先做概念圖上的第 1 款，再加上服事概念圖拿的權杖；其他款之後再做。也可以先找接近的現成武器模型，跟概念圖不同就列待替換。

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
| `gelly` | 果凍怪 | `monster-gelly.jpg` | 果凍類；生成時用不透明的版本（核心和光點在 Godot 做） |
| `fluffy_caterpillar` | 毛絨蟲 | `monster-fluffy_caterpillar.jpg` | 毛蟲類 |
| `young_treant` | 小樹精 | `monster-young_treant.jpg` | 植物類；用上排的造型，樹根和手臂分開 |
| `cute_bunny` | 可愛兔 | `monster-cute_bunny.jpg` | 不在第一版陣容 |

### 13.5 場景（細節在 08）

先找現成的（第 5.3 節），找不到的獨特地標才用 Colab；城牆、房屋找不到合適的套件時用 Blender 腳本做模組。

| 地圖 | 主要素材 |
|---|---|
| 克羅能堡 | 城牆和圓塔（尖頂、平頂城垛）、南門（雙圓塔，兩張地圖共用）、西南門、北門和門外的石橋、新月形城門和王室旗幟、城堡和銅色圓頂的宮殿（遠景）、哥德式大教堂、雅典娜神像、細石柱、半木造房屋（模組）、港口（石砌碼頭、木棧橋、倉庫、吊車、港口大屋、兩艘大帆船、划船）、市集攤位、路燈、水井、石板路；城外的河和海 |
| 克羅能堡南方草原 | 地形材質（草地、泥土路、岩石、懸崖、沙地、沙丘）、松樹和闊葉樹、灌木、草、乾草叢、劍士訓練營地（帳篷、訓練假人、武器架、吊環訓練架、營火、圓木）、漁村（漁屋、木棧橋、漁網、划船、帆船）、跨海的大橋和橋頭石像、水井、路標、立石（砂岩）、礁石、海 |

- 上一版的噴水池、騎士像、觀象台、廢棄瞭望塔、小屋、洞穴入口、水晶遺跡、老樹、風車、石拱橋、商隊營地、發光植物都不做了。
- M1 先用 Poly Haven、ambientCG 的材質加上簡單的幾何（白模）把地圖做起來，M2 管線完成後再換成正式素材（批次安排在 11）。

### 13.6 其他

| 項目 | 來源 |
|---|---|
| 人形動作（共用和依武器） | Mixamo、Quaternius（清單在 05） |
| 天空 HDRI | Poly Haven（08） |
| 字型 Noto Sans TC | Google Fonts（10） |
| 圖示（技能、狀態、物品、介面） | 先找現成的（game-icons.net、Kenney、OpenGameArt 等），不夠的用 Gemini；物品圖示也可以從 3D 模型渲染（10） |
| 載入畫面 | Gemini（10） |
| 佔位外觀（`placeholder_weapon` 等，03 第 5 節） | 自製（M0） |

### 13.7 音訊（04-D20、10）

| 類別 | 內容 | 來源 | 批次 |
|---|---|---|---|
| 背景音樂 | 克羅能堡、克羅能堡南方草原 | 你用 Gemini 生成 | M2-e |
| 環境音 | 港口和草原海邊的海浪和海鷗、北門外的河、城裡廣場的人聲、訓練營地的營火、松樹林的鳥、沙漠的風 | 現成（Freesound、Sonniss、Kenney 等） | M2-e |
| 腳步 | 石板、草地、沙、木板（碼頭、棧橋）、泥土 | 現成 | M3-c |
| 怪物 | 每隻怪的攻擊、受擊、死亡、移動 | 現成 | M4-a、M4-b |
| 打擊、技能、介面 | 揮擊（6 種武器）、命中（依目標：肉、木頭、果凍）、暴擊、升級；詠唱、施放、命中；點擊、視窗、錯誤、撿取、裝備 | 現成 | M5、M7、M8 |

---

## 14. Colab（Hunyuan3D-2）的使用方式

### 14.1 共通設定

筆記本：`chousir/colab-ImageTo3D` 的 `hunyuan3d2_colab_t4.ipynb`（Google Colab T4，模型權重快取在 Google Drive）。

| 項目 | 設定 |
|---|---|
| 視角模型 | `VIEW_QUALITY = "sdxl"`（T4 顯存不夠時改 `sd21`） |
| 形狀模型 | `hunyuan3d-dit-v2-mv-turbo`；細節不夠時改完整模型 |
| 貼圖模型 | `hunyuan3d-paint-v2-0`（完整模型，預設值） |
| 面數上限（`PRESETS`） | 用筆記本的預設值（角色 6 萬、怪物 4 萬、裝備和道具 1.5 萬、場景 10 萬個面），都比第 12 節的預算高，由管線減面 |
| 貼圖解析度（`TEXTURE_SIZE`） | 2048 |
| 種子 | 視角不滿意就換 `VIEW_SEED`；記在輸出的 `.json` |

### 14.2 每個物件的輸入

| 物件 | 正面圖 | 注意事項 |
|---|---|---|
| novice_female | A 字姿勢，頭髮盤起、不戴頭盔、不揹背包、不拿武器 | 頭盔另外做成 `novice_helmet`；背包另外做成道具 |
| swordsman_female | 同上 | 拿掉劍和劍鞘；長髮蓋住背部的話改成盤髮，頭髮另外做 |
| thief_female | 同上 | 頭巾另外做成 `bandana`；露出的腰部是身體網格的一部分 |
| acolyte_female | 同上 | 緞帶另外做成 `ribbon`；腰上的書和十字墜飾屬於服裝 |
| gelly | 不透明的版本（沒有核心、光點、葉子） | 半透明、發光核心在 Godot 用材質做 |
| fluffy_caterpillar | 側面看得到每節的腳 | 毛在 Godot 用外殼著色器補 |
| young_treant | 上排的造型 | 樹根和手臂要跟樹幹分開，不要黏在一起 |
| 7 件武器和盾牌 | 各款一張正面 | 照圖上標的尺寸縮放 |
| 3 件頭飾 | 單獨一個物件（頭巾戴在灰色假人頭上） | 管線拿掉假人頭 |
| 獨特的地標（城門、大教堂、神像、大帆船等） | 一張正面 | 先找現成的，找不到才生成 |

### 14.3 沒有概念圖時

先找現成的（第 5.3 節）。真的找不到，才用 Gemini 生成一張正面圖，再丟進 Colab。提示詞用英文，不放任何遊戲、公司、作品、角色、畫家的名字。

**範本**（後面接 `docs/proposals/2026-10-10-art-prompts.md` 的 P-01，負面提示詞用 P-05）：
`Orthographic FRONT view of a single {物件}, realistic medieval European fantasy style, PBR-like realistic materials, worn and weathered, {材質說明}, about {尺寸} tall, no base, no text.`

**例子：**

| 物件 | `{物件}` | `{材質說明}` |
|---|---|---|
| 市集攤位 | `wooden market stall with striped canvas roof` | `weathered oak planks, faded red and cream canvas` |
| 路燈 | `wrought iron street lamp with glass lantern` | `dark iron, aged brass details` |
| 木桶 | `oak barrel with iron hoops` | `dark oak staves, rusty iron hoops` |
| 水井 | `stone water well with wooden roof and bucket` | `mossy fieldstone, old timber` |
| 圍籬 | `rustic split-rail wooden fence segment` | `grey weathered wood` |

### 14.4 時間的安排

- Colab 沒有點數限制，但免費的 GPU 時間有限，一次執行可能被中斷；模型權重快取在 Drive，重開後不用重新下載。
- 第一版約 20 多個生成模型（4 套服裝、3 隻怪物、7 件武器和盾牌、3 件頭飾、幾個獨特的地標），角色要重拓撲和綁骨，花的時間比怪物和武器多。
- 先做試做（初心者、新手短劍、果凍怪），確認正面圖的做法和管線都對，再做其他的。

---

## 15. 第一版要做的和之後才做的

| 項目 | 第一版（M0～M4） | 之後 |
|---|---|---|
| 目錄、投遞規則、授權登記、待替換清單 | ✔（M0 建立目錄；M2 起開始有內容） | — |
| 切圖工具、Blender 管線、音訊管線、報告和預覽 | ✔（M2） | 持續改進 |
| 人形角色（女性 4 套服裝、共用頭部、4 種髮型） | ✔（M2～M3） | 男性 |
| 頭飾 3 件、武器和盾牌 7 件 | ✔（M3） | 其他款 |
| 怪物 3 隻 | ✔（M4） | 更多怪物 |
| 場景素材 | M1 白模加 CC0 材質；M2 之後換成現成素材和生成的地標 | 持續增加、照待替換清單換 |
| 背景音樂、環境音、腳步、怪物的聲音 | ✔（M2-e、M3-c、M4） | — |
| 打擊、技能、介面的音效 | — | M5、M7、M8 |
| NPC（冒險公會服務員） | — | M8 |
| blendshape（表情、臉型） | 只保留網格裡已有的 | 外觀自訂時 |

---

## 16. 測試與驗收方式

**M0：**
1. 目錄建好；`_inbox/` 和 `_source/` 有 `.gdignore`，`_inbox/` 的內容不會被 Git 追蹤。
2. 授權守門測試（03 第 10.2 節）在空的登記表上通過，並能抓到刻意放進去的未登記檔案。

**M2（管線）：**
3. 用 1 個 CC0 測試模型（Poly Haven）跑完整個流程：成品的面數、尺寸、原點、貼圖大小都符合 `process.json`；登記表多了一筆正確的紀錄；報告和預覽圖都產生。
4. 同一個素材重跑兩次，成品完全相同（可重現）。
5. 試做初心者（女）的完整人形流程（Colab 生成 → 切頭 → 共用頭部 → Mixamo）：Godot 能正確播放 Mixamo 的走路動作；共用頭部的脖子接縫在預覽圖上看不出來（我先看，再請你確認）。
6. LOD 比較：同一個模型用 Blender LOD 和 Godot 自動 LOD 各跑一次，比較畫面和效能，結果給你決定（第 8.3 節）。

**M3、M4：**
7. 每個角色、頭飾、武器、怪物都通過預算檢查；超出的項目有說明。
8. 冒煙測試（01 第 11.1 節）載入每一個角色和怪物場景，沒有錯誤。
9. 動作檢視器的截圖：每個職業、每種武器、每隻怪物都看得到，再請你確認。

**2026-10-11 加的（編號接在後面，其他文件引用的編號不變）：**
10. M1-a3：授權守門測試照第 5 節的新規則更新（03 第 10.2 節第 3、4、4a 條）：NC 沒有 `non_commercial`、Gemini 沒有 `personal_use_only`、Hunyuan3D 沒有地區限制，或有這些限制卻沒有標 `license_blocks_release` 的，都要被抓到。
11. M2-e：一首背景音樂轉成 OGG，音量在 −16 LUFS ±1，循環的接縫聽不出來（我先聽，再請你確認）；登記表有正確的限制標記。
12. 每個里程碑結束時：待替換清單跟登記表的 `replacement` 一致（第 5.4 節）。

---

## 17. 風險與備案

| 風險 | 影響 | 備案 |
|---|---|---|
| Mixamo 無法使用 | 不能綁骨、不能下載動作 | 動作下載後都留底；綁骨改用 Blender Rigify；動作改用 Quaternius |
| 免費下載的網站停止或下架素材 | 少一個來源 | 原始檔都留底；改用其他來源 |
| 現成素材的風格不一致 | 畫面看起來東拼西湊 | 共用材質、顏色校正、統一的光照（08）；不一致的列待替換 |
| 現成素材跟概念圖不同 | 不是目標樣貌 | 列待替換清單，之後再討論（04-D19） |
| Colab 的 GPU 時間不夠或執行中斷 | 生成變慢 | 模型權重快取在 Drive；一次處理一個；必要時換 Colab 的付費方案（你決定） |
| Hunyuan3D-2 的品質不夠（背面糊掉、細節不清楚） | 模型難看 | 換種子、改完整模型、改善正面圖；不行就在 Blender 修，或列待替換 |
| AI 模型的拓撲很亂 | 變形難看、減面後破洞 | 重拓撲＋烘焙（第 8.1 節第 6 步）；仍然不行就重新生成 |
| Hunyuan3D-2 只產生顏色貼圖 | 質感不夠 | 法線從原始網格烘焙；粗糙度、金屬度依材質區域給值 |
| 共用頭部和身體的接縫、膚色對不上 | 脖子看得出接縫 | M2 先試做；不行就退回每個職業自帶頭部（第 9.2 節） |
| 半透明的果凍 | 生成工具做不出透明材質 | 在 Godot 用材質做（07） |
| 授權的地區、商用限制 | 不能在某些地區公開或商用 | 登記表標記；待替換清單列出公開前要換的 |
| Godot 匯入 FBX 動作有問題 | 動作不能用 | 改用 Blender 轉成 glb |
| Blender 5.2 的 Python API 變動 | 腳本出錯 | M2 先跑一次測試模型 |
| LFS 的容量越來越大（現成素材的原始檔很大） | 硬碟和遠端空間 | 原始檔一定留，成品縮小；GitHub 的 LFS 接近上限時再換遠端或加購（01 第 13.5 節） |
| 跟 Gravity 或其他作品太像 | 版權疑慮 | 第 4 節的清單之後討論；個人自用 |

---

## 18. 待你確認事項

> 2026-10-10 你回覆「全部照建議」，以下 10 項都照建議定案。2026-10-11 依提案和你的回覆修改的地方，標在「之後的修改」。

| # | 事項 | 建議 | 之後的修改 |
|---|---|---|---|
| 1 | 共用頭部的來源 | 用 MPFB2（CC0）。理由是眼睛、睫毛、牙齒分開、拓撲固定，之後才做得了表情和臉型 | — |
| 2 | 髮型 | 四張女性概念圖的髮型做成 4 種可以選的髮型，換職業不換髮型（跟 RO 一樣）；第一版預設哪一種由 05 定 | 來源改成 MPFB2 或 Colab |
| 3 | 概念圖上的配件 | 頭盔、頭巾、緞帶做成頭飾；身體上的武器、劍鞘、盾牌拿掉 | — |
| 4 | Tripo 方案 | 先用免費方案 | 2026-10-11：Tripo 不用了，改用 Colab 的 Hunyuan3D-2（04-D04） |
| 5 | LOD | 照原決定由 Blender 產生；M2 跟 Godot 自動 LOD 比較後再決定（第 8.3 節） | — |
| 6 | 貼圖和 glb 分開存 | glb 只放網格、骨架、動作，貼圖是獨立的 PNG，材質是 Godot 的 `.tres`（04-D10） | — |
| 7 | 動作的匯入 | Mixamo 的 FBX 動作直接用 Godot 內建的匯入，不經過 Blender | — |
| 8 | 第一版的武器和盾牌 | 每種先做第 1 款，加上服事的神聖權杖和學徒圓盾，共 7 件（第 13.3 節） | — |
| 9 | Quaternius 完整版（付費） | 先用免費版 | 2026-10-11：不買付費素材（00-S16） |
| 10 | 預算數字 | 照第 12 節，M1～M2 實測後修正 | 目標顯卡改成 RTX 4060 |

2026-10-11 另外定的（`docs/proposals/2026-10-11-replies.md`）：素材以套用現成的免費素材為主、白名單擴大、授權放寬（第 5 節）；待替換清單（第 5.4 節）；Gemini（付費方案）做 2D 圖和背景音樂；音效的來源（Kenney、Freesound、OpenGameArt、Sonniss）；房屋、城牆的模組找不到現成的就用 Blender 腳本做；視角圖由 Colab 產生；`ConceptArt/` 加新的類別（`ConceptArt/README.md`）。

---

## 19. 需要修改已確認文件的地方

2026-10-10 你同意後，03 已照下表改好，狀態列也註明了修訂日期。

| 文件 | 位置 | 現在的寫法 | 建議改成 | 理由 |
|---|---|---|---|---|
| 03 | 第 10.1 節 `origin` 的值 | polyhaven、ambientcg、mixamo、sketchfab、tripo、quaternius、google_fonts、original、other | 加上 `makehuman` | 共用頭部和髮型來自 MPFB2（MakeHuman） |
| 03 | 第 10.2 節第 3 條（允許的授權） | 「…以及 04 查證後加入的 Tripo 授權」 | 寫明 `LicenseRef-Tripo-Free`、`LicenseRef-Tripo-Paid` | 04-D04 查證的結果；03 原本就預留給 04 填 |

2026-10-11 依提案修改了 00、01、03（授權登記表和守門測試的規則），各文件的狀態列都有註明。

`docs/environment-setup.md` 不是規劃書，以下只是建議（照計畫，不直接修改）：
- Tripo 的部分改成：3D 生成用 Colab 的 `chousir/colab-ImageTo3D`（Google Drive 要留約 24 GB 給模型權重）；Tripo 只是備案。
- 加上 ffmpeg（你已經安裝，音訊管線用）。
- 素材流程改成：先找現成的免費素材；要生成時給正面圖，用 Colab 生成，下載的檔案照 04 第 6.2 節的檔名投遞。

---

## 20. 與 RO 原制不同之處（待檢視）

本文件只處理美術和素材流程，沒有改變 RO 的機制：
- 角色是寫實 3D 模型，不是 RO 的 2D sprite，這是 00-A01 的前提。
- 造型照概念圖（00-S12、00-A02 原創換皮），不照 RO 的 sprite；相似的地方列在第 4 節。
- 換職業只換服裝、頭和髮型不變，跟 RO 一樣。
- 身上不顯示收起來的武器，跟 RO 一樣。
- 背景音樂、怪物和技能的音效照 RO 一樣有；地圖的環境音比 RO 多（10）。

---

## 21. 與 00 決策對照

| 00 決策 | 本文件對應 |
|---|---|
| 00-A02 原創換皮 | 第 4 節（相似清單）；名稱不用 Gravity 的；不用從其他遊戲抽出來的素材 |
| 00-A03 寫實、1080p/60；00-S15 RTX 4060；00-S17 電影寫實 | 04-D01、04-D16、第 3、12 節 |
| 00-A07 第一版陣容 | 第 13 節 |
| 00-A08 動作 | 04-D13、04-D14（來源；清單在 05） |
| 00-A09 裝備外顯 | 第 13.2、13.3 節 |
| 00-A10 外觀自訂預留 | 04-D11、第 9 節（共用頭部、可換髮型、保留 blendshape） |
| 00-A11 素材；00-S16 素材以套用為主 | 全文；04-D03、04-D04、04-D19、第 5 節 |
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

**AI 工具**
- 你的 Colab 筆記本（Hunyuan3D-2、MV-Adapter）：https://github.com/chousir/colab-ImageTo3D
- Tencent Hunyuan 3D 2.0 Community License（地區、產出的權利、不能改進其他模型）：https://github.com/Tencent-Hunyuan/Hunyuan3D-2/blob/main/LICENSE
- MV-Adapter（Apache-2.0）：https://github.com/huanngzh/MV-Adapter
- Gemini 的音樂生成（Lyria 3）：https://blog.google/innovation-and-ai/products/gemini-app/lyria-3/
- Tripo（備案）的授權：https://www.tripo3d.ai/help/privacy-policy/how-to-use-tripo-models-commercially

**素材來源與授權**
- Poly Haven 授權（CC0）：https://polyhaven.com/license
- ambientCG 授權（CC0）：https://docs.ambientcg.com/license/
- MakeHuman 授權（核心素材 CC0）：https://static.makehumancommunity.org/about/license.html
- MPFB 常見問題（可以用在不開源的遊戲裡）：https://static.makehumancommunity.org/mpfb/faq/use_in_closed_source.html
- MPFB 版本（2.0.17，支援 Blender 4.2 以上）：https://extensions.blender.org/add-ons/mpfb/versions/
- Quaternius Universal Animation Library（CC0）：https://quaternius.com/packs/universalanimationlibrary.html
- Kenney（CC0）：https://kenney.nl/
- Sketchfab 移轉到 Fab 的說明：https://sketchfab.com/blogs/community/sketchfab-update-what-you-need-to-know-now-that-fabs-live/
- Sketchfab 下載 API 的規範（CC 授權、署名）：https://sketchfab.com/developers/download-api/guidelines
- game-icons.net（CC BY 3.0）：https://game-icons.net/
- OpenGameArt：https://opengameart.org/
- Freesound：https://freesound.org/
- godot-sqlite 等其他工具見 01 第 12 節
- Mixamo 常見問題（Adobe）：https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html
- Noto Sans TC（OFL）：https://fonts.google.com/noto/specimen/Noto+Sans+TC

**Godot 4.7**
- 3D 場景的匯入設定（LOD、陰影網格、切線、匯入腳本、動作庫、貼圖的處理方式）：https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/importing_3d_scenes/import_configuration.html
- 網格 LOD（meshoptimizer、預設開啟、骨架網格偶爾出問題）：https://docs.godotengine.org/en/4.7/tutorials/3d/mesh_lod.html
- 骨架重定向（BoneMap、SkeletonProfileHumanoid、A 字姿勢要開 Fix Silhouette）：https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/retargeting_3d_skeletons.html
- Godot 4.3 起內建的 FBX 匯入（ufbx）：https://godotengine.org/article/introducing-the-improved-ufbx-importer-in-godot-4-3/
- 音訊的匯入和循環：https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/importing_audio_samples.html

**Blender**
- Blender 5.0 的 Python API 變動：https://developer.blender.org/docs/release_notes/5.0/python_api/
