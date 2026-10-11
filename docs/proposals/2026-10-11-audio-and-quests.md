# 音樂、音效與任務（提案）

> 狀態：**已併入規劃書（2026-10-11）**：02、03、04、06、08、09、10、11。本文留作紀錄，以規劃書為準；第 2.5 節的音樂提示詞照樣可以用。
> **2026-10-11：使用者已全部回覆。跟本文不同的地方以 `2026-10-11-replies.md` 為準（第 8 節）。**
> 建立日期：2026-10-11
> 依據：你在對話裡的問題（地圖背景音樂你生成、其他音效我找；用冒險公會服務員做任務：學初心者技能、打怪）；10-D10（音效只預留）；06-D13、06-D14（轉職 NPC、任務技能之後才做）；03 第 4.1 節（`data/npcs/` 已預留）
> 修訂：2026-10-11，使用者全部回覆（`2026-10-11-replies.md` 第 8 節）：音樂工具是 Gemini（付費方案），第 2.3、2.5 節改成 Gemini 的檔名和提示詞
> 範圍：只有規劃，**不改程式**。你確認第 6 節後，由本機的 Claude Code 照第 5 節改規劃書；程式等到對應的批次再做。

---

## 1. 結論總覽

| # | 主題 | 建議 |
|---|---|---|
| 1 | 現在有沒有音樂 | 沒有。10-D10 只預留了匯流排和事件接口，「第一版沒有聲音」；04 的白名單也沒有音訊來源 |
| 2 | 背景音樂 | 你用 AI 音樂工具生成（提示詞第 2.5 節），丟進 `assets/_inbox/`，檔名 `<工具>-music-<地圖 ID>.wav`（第 2.3 節）；我轉檔、統一音量、做循環 |
| 3 | 其他聲音 | 環境音、怪物、打擊、技能、腳步、介面我找現成的（CC0 為主，第 2.7 節）；你也可以放，規則一樣 |
| 4 | 什麼時候有聲音 | 背景音樂和環境音提前到第一版（新批次 M2-e）；腳步、怪物的聲音跟著 M3、M4 的動作；打擊 M5、技能 M7、介面 M8 |
| 5 | 任務 | 冒險公會服務員當任務櫃台：接任務、交任務。第一批是登記、三個討伐、兩個學初心者任務技能（緊急治療、裝死，照 RO） |
| 6 | 任務系統的做法 | 任務和對話都是資料（JSON），步驟只有固定幾種（對話、討伐、收集、跑腿）；伺服器判定一切，客戶端只顯示 |
| 7 | 什麼時候做任務 | 要先有物品（M6）、技能（M7）、視窗（M8），建議放進 M8（改名「完整 UI、NPC 與任務」） |

---

## 2. 音樂和音效

### 2.1 RO 怎麼做（對照）

- 每張地圖一首背景音樂，換圖就換曲；登入、選角畫面也有。
- 怪物的攻擊、受擊、死亡等聲音跟著動作的影格播；技能、命中、升級、介面都有音效。
- 所以加上聲音是照 RO。10-D10 的「第一版沒有聲音」是當時為了縮小範圍，不是 RO 的規則；要改 10-D10 列在第 6 節第 1 項。

### 2.2 分工

| 類別 | 誰做 | 來源 |
|---|---|---|
| 背景音樂 | 你，用 AI 音樂工具生成 | 工具要先加進 04-D03 的白名單（第 6 節第 3 項） |
| 環境音（海浪和海鷗、河、風、城裡的人聲、營火、森林的鳥、沙漠的風） | 我找 | 第 2.7 節 |
| 怪物、打擊、技能、腳步、介面 | 我找；你也可以放 | 第 2.7 節；你放的請告訴我來源 |

### 2.3 投遞：放哪裡、檔名叫什麼

- 放 `assets/_inbox/`，跟模型一樣（04 第 6 節）。
- 檔名照 04-D06：`<來源>-<類別>-<名稱>.<副檔名>`，類別加上 `music`、`ambience`、`sfx`。
- 背景音樂的名稱用地圖 ID 或畫面的名稱：

| 檔名 | 用在 | 第一版 |
|---|---|---|
| `gemini-music-kronenberg.mp3` | 王都 | ✔ |
| `gemini-music-kronenberg_south_field.mp3` | 南方草原 | ✔ |
| `gemini-music-title.mp3` | 標題、登入畫面 | 之後（M8～M9） |
| `gemini-music-character_select.mp3` | 選角、創角 | 之後（M8～M9） |

- 同一首有好幾版想給我比較，就加 `_a`、`_b`：`gemini-music-kronenberg_a.mp3`。
- 格式：Gemini 只能下載 MP3，直接給 MP3（不要用有封面的 MP4）。
- 一起告訴我：工具和方案（免費或付費）、歌曲頁面的網址、你用的提示詞。我記在授權登記表和 `process.json`（04 第 6 節）。
- 用中文檔名丟進來也可以，我照規則改名、問你缺的資訊。

### 2.4 我怎麼處理

| 步驟 | 內容 |
|---|---|
| 留底 | 原始檔搬到 `assets/_source/music/<id>/`（LFS） |
| 轉檔 | OGG Vorbis（品質約 6）、48 kHz；音樂和環境音是立體聲，3D 的音效是單聲道 |
| 音量 | 音樂和環境音統一到約 −16 LUFS；音效的峰值 −1 dBTP。換曲時不會忽大忽小 |
| 循環 | 切掉結尾的淡出，結尾跟循環起點做約 2 秒的交叉淡化，在 Godot 設好循環點；你不用自己剪 |
| 成品 | `assets/audio/music/<id>.ogg`、`assets/audio/ambience/<id>.ogg`、`assets/audio/sfx/<類別>/<id>.ogg` |
| 工具 | 需要 ffmpeg。`docs/environment-setup.md` 不能改，所以只建議你裝（例如 `winget install Gyan.FFmpeg`），第 6 節第 4 項 |

- 地圖的音樂和環境音是表現層，放在客戶端的 `map.tscn`（地圖的音訊節點：音樂 ID、環境音的發聲點）；伺服器不讀（01-D07）。換圖時音樂淡出、淡入約 1 秒；兩張地圖用同一首時就繼續播。
- 環境音的發聲點：港口和草原的海邊（海浪、海鷗）、北門外的河、城裡的廣場（人聲）、訓練營地（營火）、松樹林（鳥）、沙漠（風），範圍外淡出。

### 2.5 背景音樂的提示詞（Gemini）

- Gemini 沒有「風格」「排除」欄位，整段貼進對話就好；長度選最長的模式（2～3 分鐘）。
- 開頭不要太長的前奏（循環時會一直聽到）；不要放任何遊戲、作曲家、歌手的名字。
- 不滿意可以接著說「同樣的風格，旋律再明亮一點」之類的修改。

#### M-01 `kronenberg`（王都）

```text
Create an instrumental track, about 3 minutes long, with no vocals. A medieval fantasy town theme for a peaceful harbor capital city: warm and cheerful, a lute and a celtic harp, a wooden flute melody, pizzicato strings, a soft accordion, and light hand percussion with tambourine. Gentle 3/4 waltz feel, around 96 BPM, major key, nostalgic and welcoming. Keep a steady structure that can loop, with a short intro and no big ending. No electronic sounds, synths, modern drums or rock instruments.
```

#### M-02 `kronenberg_south_field`（南方草原）

```text
Create an instrumental track, about 3 minutes long, with no vocals. A bright adventurous fantasy field theme for sunny meadows by the sea: a solo wooden flute melody over acoustic guitar, light strings, glockenspiel accents, and a soft snare with a shaker. Around 112 BPM, major key, hopeful and carefree. Keep a steady structure that can loop, with a short intro and no big ending. No electronic sounds, synths, heavy drums or rock instruments.
```

#### M-03 `title`（標題、登入畫面，之後才用）

```text
Create an instrumental track, about 2 minutes long. A majestic yet gentle fantasy main theme: full orchestra, a french horn melody, soaring strings, harp arpeggios, a soft wordless choir, and timpani swells. Around 80 BPM, nostalgic and grand. No lyrics, no electronic sounds or synths.
```

#### M-04 `character_select`（選角、創角，之後才用）

```text
Create an instrumental track, about 2 minutes long, with no vocals. Calm fantasy menu music: solo piano and harp, soft warm strings, and music box accents. Around 70 BPM, gentle and nostalgic, easy to loop. No drums, no electronic sounds or synths.
```

### 2.6 第一版要的聲音

| 類別 | 內容 | 批次（建議） |
|---|---|---|
| 背景音樂 | 王都、南方草原 | M2-e（新批次，在投遞管線 M2-a 之後） |
| 環境音 | 第 2.4 節的發聲點 | M2-e |
| 腳步 | 石板、草地、沙、木板（碼頭、棧橋）、泥土；跟著 M3-c 的腳步標記，依地面材質換 | M3-c |
| 怪物 | 每隻怪：攻擊、受擊、死亡、移動；跟著動作的標記播，檢視器也聽得到 | M4-a、M4-b |
| 打擊 | 揮擊（6 種武器）、命中（依目標：肉、木頭、果凍）、暴擊、升級 | M5（之後） |
| 技能 | 詠唱、施放、命中 | M7（之後） |
| 介面 | 點擊、開關視窗、錯誤、撿取、裝備 | M8（之後） |

### 2.7 我找音效的來源（要加進 04 第 5 節的白名單）

| 來源 | 授權代碼（03 第 10 節） | 規則 |
|---|---|---|
| Kenney | `CC0-1.0` | 介面、打擊、腳步的音效包 |
| Freesound | 只收 `CC0-1.0`、`CC-BY-4.0` | CC-BY 要記作者；不收 NC、Sampling+ |
| OpenGameArt | 只收 `CC0-1.0`、`CC-BY-4.0` | 同上，每個檔案的授權各自確認 |
| Sonniss 的 GDC 免費音效包 | `LicenseRef-Sonniss-GDC`，加 `no_source_redistribution` | 免版稅、可以用在遊戲裡；原始檔不能再散布。登記前我再核對一次條款 |
| 你的 AI 音樂工具 | 查過條款再定（例如 `LicenseRef-<工具>-Free`） | 跟 Tripo 一樣記下方案；免費方案通常不能商用，個人自用可以 |
| 你自己放的音效 | 依來源 | 告訴我來源網址 |

- 規則照 04 第 5 節：只用白名單；原始檔留底；每個檔案登記在 `assets/license_registry.json`；資料不齊就停下來問你。

---

## 3. 任務

### 3.1 RO 怎麼做（對照，只參考行為）

- **任務技能**：初心者的「緊急治療」（First Aid）和「裝死」（Play Dead）是跟 NPC 對話學的，不是用技能點學（rAthena 的 `npc/quests/skills/novice_skills.txt`）：
  - 緊急治療：初心者 Job 等級 4 以上，或 Base 等級 12 以上；交 3 個紅色藥草（Red Herb）、3 個幸運草（Clover）給 NPC 就學會（對話裡還提到繃帶，但實際只檢查前兩種）。
  - 裝死：初心者 Job 等級 7 以上、學過緊急治療；先到城堡找另一個 NPC 拿「初心者名牌」，再交給教你的 NPC。
  - 基本技能（Basic Skill）照 RO 用技能點學，不是任務（06 第 8.3 節）。
- **任務系統**：rAthena 的 `db/re/quest_db.yml` 定義每個任務的 ID、標題、時間限制、討伐目標（怪物、數量、地圖；也可以用種族、體型、屬性、等級範圍篩選）和任務專用的掉落；客戶端的任務視窗顯示進度。對話、條件和獎勵寫在 NPC 腳本裡。
- **卡普拉職員**在 RO 是儲存點、倉庫、傳送服務，不給任務。

### 3.2 冒險公會服務員（Caldwell）

| 項目 | 建議 |
|---|---|
| 角色 | 冒險公會的櫃台：接任務、交任務。之後可以再加儲存點和倉庫（RO 卡普拉的功能），第 6 節第 9 項 |
| 位置 | 大教堂廣場的神像旁（新角色一出生就看到）；南門內側一位（出城打怪、回來交任務方便）。之後訓練營地也可以放一位 |
| 模型 | 一個模型（`adventurer_guild_staff`，概念圖已經有），擺在不同位置 |
| 互動 | 點她（09 的點選）；太遠就自動走過去，2 m 內打開對話視窗 |

### 3.3 第一批任務（建議）

| ID | 名稱 | 種類 | 接的條件 | 內容 | 獎勵 |
|---|---|---|---|---|---|
| `guild_registration` | 冒險者登記 | 對話 | 新角色 | 跟神像旁的服務員說話，登記成冒險者；順便介紹任務視窗 | 少量回復藥（物品在 M6 定） |
| `hunt_gelly` | 討伐果凍怪 | 討伐 | 登記完 | 在南方草原打倒 10 隻果凍怪，回去找任一位服務員 | Base、Job 經驗 |
| `hunt_fluffy_caterpillar` | 討伐毛絨蟲 | 討伐 | `hunt_gelly` 完成 | 打倒 10 隻毛絨蟲 | 經驗 |
| `hunt_young_treant` | 討伐小樹精 | 討伐 | `hunt_fluffy_caterpillar` 完成 | 打倒 5 隻小樹精 | 經驗、物品 |
| `learn_first_aid` | 學習緊急治療 | 收集 → 學技能 | 照 RO：初心者，Job 4 以上或 Base 12 以上 | 交 3 個草藥類、3 個幸運草類的材料（第一版怪物的掉落，M6 定） | 技能 `first_aid` 1 級 |
| `learn_play_dead` | 學習裝死 | 跑腿 → 學技能 | 照 RO：初心者，Job 7 以上，學過緊急治療 | 到南方草原的劍士訓練營地找教官拿「初心者名牌」，交給服務員 | 技能 `play_dead` 1 級 |

- 經驗、物品的數值在 M6～M7 依 RO 的升級速度再定；RO 的任務技能本身不給經驗，照 RO。
- `learn_play_dead` 要一位訓練營地的教官（RO 是城堡裡的 NPC），順便帶玩家去營地。教官還沒有概念圖，第 6 節第 8 項。
- 之後可以加：劍士轉職（06-D13 的轉職 NPC，放在訓練營地很合適）、其他職業的任務技能（06-D14 的撒沙等）、收集材料的任務。

### 3.4 系統的做法

| 項目 | 做法 |
|---|---|
| 伺服器權威 | 接任務、進度、完成、獎勵都在伺服器判定，客戶端只顯示（CLAUDE.md 第 1 條） |
| 任務資料 | `data/quests/`：步驟只有固定幾種（`talk`、`kill`、`collect`、`deliver`），條件和獎勵是欄位，不是腳本 |
| NPC 和對話 | `data/npcs/`（03 已預留）：NPC 的種類、外觀、對話樹；對話的節點只能做固定幾種動作（接任務、交任務、學技能、給物品、之後的儲存和倉庫） |
| 顯示文字 | 任務名稱、說明、對話都放 `locale/`，鍵是 `quest.<id>.name`、`npc.<id>.name`、`dialog.<npc>.<節點>`（03 第 7 節）；伺服器只送鍵 |
| 位置 | logic 場景的 NpcSpot 標記（03 第 6.2 節已預留）放 NPC 的 ID 和面向 |
| 存檔 | 角色檔加 `quests`：進行中的任務和每一步的進度、完成過的任務和時間（03 第 8.3 節，存檔版本加 1、寫遷移） |
| 網路 | 加幾個訊息：點 NPC、伺服器送對話節點、選選項、任務進度更新、任務清單（02） |
| 討伐的計算 | 打倒怪物的玩家計數；組隊時怎麼分，到 M9 照 rAthena 再定 |
| 介面 | 對話視窗（NPC 名字、文字、選項）、任務視窗（RO 的 Alt+U：進行中、完成、進度）；畫面右側的任務追蹤列，第 6 節第 10 項 |

任務資料的樣子（實際欄位在 03 定）：

```json
[
  {
    "id": "learn_first_aid",
    "giver": "adventurer_guild_staff",
    "requires": [
      { "job": "novice", "job_level_min": 4 },
      { "job": "novice", "base_level_min": 12 }
    ],
    "steps": [
      { "type": "collect", "item": "healing_herb", "count": 3 },
      { "type": "collect", "item": "lucky_clover", "count": 3 }
    ],
    "rewards": { "skills": [{ "id": "first_aid", "level": 1 }] },
    "repeatable": false,
    "ro_ref": "npc/quests/skills/novice_skills.txt (First Aid)"
  },
  {
    "id": "hunt_gelly",
    "giver": "adventurer_guild_staff",
    "requires": [{ "quests_done": ["guild_registration"] }],
    "steps": [{ "type": "kill", "monster": "gelly", "count": 10, "map": "kronenberg_south_field" }],
    "rewards": { "base_exp": 0, "job_exp": 0, "items": [] },
    "repeatable": false
  }
]
```

- `requires` 是「任一組成立就可以接」；物品 ID（`healing_herb`、`lucky_clover`）只是例子，M6 定掉落時再決定，不用 RO 的名稱（00-A02）。

---

## 4. 與 RO 原制不同之處（待檢視）

| 項目 | RO 原制 | 本專案 | 理由 |
|---|---|---|---|
| NPC 和任務的寫法 | NPC 腳本（自己的腳本語言） | 任務和對話是資料，動作只有固定幾種 | 00-S14：不照抄老舊的技術做法；跟 03 第 4.4 節「技能不另外發明腳本語言」一致。玩家感受一樣 |
| 任務的給予者 | 各地不同的 NPC；卡普拉不給任務 | 冒險公會服務員是任務櫃台 | 你的指示；服務員本來就是原創的組織 |
| 任務追蹤列（如果採用） | 只有任務視窗 | 畫面右側另外顯示進行中的任務 | 參考 FF14（00-S08）；第 6 節第 10 項 |
| 地圖的環境音 | 有，但不多 | 每張地圖都放 | 寫實 3D 需要（00-A03） |

- 背景音樂、怪物音效、技能音效、打擊音效本身都是照 RO。

---

## 5. 要改的規劃書（你確認後執行）

| 文件 | 位置 | 改成 |
|---|---|---|
| 10 | 10-D10、第 10 節 | 「第一版沒有聲音」改成「第一版有背景音樂、環境音、腳步、怪物的聲音」；加上第 2.4、2.6 節的內容（循環、音量、換圖淡出淡入、環境音發聲點） |
| 10 | 新的一節 | 對話視窗、任務視窗、（採用的話）任務追蹤列（第 3.4 節） |
| 04 | 第 5 節白名單 | 加第 2.7 節的音訊來源（第 6 節第 2、3 項你同意的） |
| 04 | 第 6.1、6.2 節 | 目錄加 `assets/audio/music/`、`ambience/`、`sfx/`；投遞的類別加 `music`、`ambience`、`sfx`，來源加你的音樂工具 |
| 04 | 新的一節 | 音訊管線（第 2.4 節） |
| 03 | 第 4.1 節、新的一節 | `data/quests/` 的格式；`data/npcs/` 從「預留」改成正式的格式（第 3.4 節） |
| 03 | 第 6.2 節 | NpcSpot 的參數：NPC ID、面向 |
| 03 | 第 7 節 | 鍵加 `quest.<id>.*`、`dialog.<npc>.<節點>` |
| 03 | 第 8.3、8.4 節 | 角色檔加 `quests`；存檔版本加 1 |
| 02 | 訊息清單 | NPC 互動、對話、任務進度、任務清單的訊息 |
| 06 | 06-D14、第 8 節 | 緊急治療、裝死：「之後」改成「M8，用任務學」，條件照第 3.1 節 |
| 09 | 選目標 | 點 NPC：走到 2 m 內打開對話 |
| 11 | 11-D02、第 4.3～4.5 節、第 5 節 | M2 加 M2-e（背景音樂和環境音）；M3-c 加腳步聲；M4-a、M4-b 加怪物的聲音；M8 改名「完整 UI、NPC 與任務」，加批次（NPC 和對話、任務、任務技能） |
| `ConceptArt/README.md` | NPC 表 | 加訓練營地的教官（第 6 節第 8 項你同意的話） |

每份文件改完後，狀態列加上「修訂：2026-10-xx，依 `docs/proposals/2026-10-11-audio-and-quests.md`…」（11-D10）。

---

## 6. 待你確認事項

| # | 事項 | 我的建議 |
|---|---|---|
| 1 | 第一版要不要有聲音（改 10-D10） | 要：背景音樂、環境音、腳步、怪物的聲音放進第一版；打擊、技能、介面跟著 M5、M7、M8 |
| 2 | 音效的來源（加進 04 白名單） | Kenney、Freesound（只收 CC0、CC-BY）、OpenGameArt（同上）、Sonniss 的 GDC 免費音效包 |
| 3 | 你用哪一個 AI 音樂工具、哪個方案 | 請告訴我（例如 Suno、Udio），我先查使用條款再加進白名單、定授權代碼 |
| 4 | ffmpeg | 請你在電腦上裝（例如 `winget install Gyan.FFmpeg`）；`environment-setup` 是你寫的，我不改，只建議加一行 |
| 5 | 背景音樂的首數 | 第一版兩首（王都、南方草原）；標題和選角之後再生成 |
| 6 | 冒險公會服務員的角色 | 任務櫃台（接、交任務）；位置在神像旁和南門內側 |
| 7 | 第一批任務 | 第 3.3 節的 6 個 |
| 8 | 訓練營地的教官 | 新的 NPC，`learn_play_dead` 用得到（RO 是城堡裡的 NPC）。需要一張概念圖（你生成，我可以給提示詞）；沒有的話先用服務員的模型代替 |
| 9 | 服務員之後要不要也當儲存點和倉庫 | 建議要（像 RO 的卡普拉）；但功能和外型都接近卡普拉，04 第 4 節的相似清單要更新。之後再決定也可以 |
| 10 | 任務追蹤列 | 要（參考 FF14），可以在設定裡關掉 |
| 11 | 討伐任務可不可以重複接 | 第一批不可以；之後再加可以重複的討伐（例如每天一次） |
| 12 | 任務放在哪個里程碑 | M8（改名「完整 UI、NPC 與任務」）；另一個選項是新增一個里程碑 |
| 13 | 任務對話的文字 | 我先寫中文草稿放 `locale/zh_TW/`，你再改 |

---

## 7. 參考來源

- RO 的初心者任務技能（緊急治療、裝死的條件；只參考行為）：https://github.com/rathena/rathena/blob/master/npc/quests/skills/novice_skills.txt
- RO 的任務資料格式（討伐目標、時間限制、任務掉落；只參考行為）：https://github.com/rathena/rathena/blob/master/db/re/quest_db.yml
- Godot 的音訊匯流排和循環設定：https://docs.godotengine.org/en/4.7/tutorials/audio/audio_buses.html
- 現有的預留：10 第 10 節（匯流排、事件接口）、03 第 9.2 節（音量設定）、03 第 4.1 節（`data/npcs/`）、03 第 6.2 節（NpcSpot）
