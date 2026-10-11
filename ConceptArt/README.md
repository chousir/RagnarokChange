# 概念圖清單

這個資料夾是遊戲的目標樣貌（00-S12）。檔名一律用英文（00-S06），格式是 `<類別>-<名稱>.jpg`：

- 類別：`character`（角色）、`monster`（魔物）、`npc`、`weapon`（武器）、`armor`（防具）、`headgear`（頭飾）、`hair`（髮型）、`face`（臉）、`prop`（道具）、`map`（地圖）、`building`（建築）、`vfx`（特效）、`ui`（介面）
- 名稱：英文小寫加底線，盡量跟遊戲資料的 ID 一樣；角色依性別加 `_female`、`_male`；同一組有好幾張時加兩位數序號，例如 `building-kronenberg_house_kit_01.jpg`

你新增圖片時可以照舊用中文檔名，我會改成英文，並把中文名稱登記在下表。中文名稱就是遊戲畫面上預定顯示的名稱（顯示文字的放法見 03 第 7 節，用語照 `docs/glossary.md`）。

- `ConceptArt/` 是參考圖，不是遊戲素材，不用登記授權（03 第 10.2 節）。
- 佈局照地圖，外觀（材質、顏色、建築樣式、光線）照鳥瞰圖和建築圖（08-D02）。概念圖之間有誤差很正常，以遊戲內容為主。
- 跟 Gravity 等作品相似的地方列在 04 第 4 節，之後再討論。

> 2026-10-10：依你的指示換了 8 張圖（四隻魔物、兩張地圖、王都建築、冒險公會服務員），原因是舊圖可能有版權疑慮。
> 2026-10-11：南方草原地圖、王都地圖、王都鳥瞰圖又各換了一次。新舊差異見 `docs/proposals/2026-10-10-concept-art-update.md` 第 3 節；規劃書已經照新圖改好（04、07、08）。

## 角色

| 檔名 | 中文名稱 | 說明 |
|---|---|---|
| character-novice_female.jpg | 初心者（女） | 職業 `novice` |
| character-novice_male.jpg | 初心者（男） | 男性依 00-S03 只預留 |
| character-swordsman_female.jpg | 劍士（女） | 職業 `swordsman` |
| character-swordsman_male.jpg | 劍士（男） | 男性依 00-S03 只預留 |
| character-thief_female.jpg | 盜賊（女） | 職業 `thief` |
| character-thief_male.jpg | 盜賊（男） | 男性依 00-S03 只預留 |
| character-acolyte_female.jpg | 服事（女） | 職業 `acolyte` |
| character-acolyte_male.jpg | 服事（男） | 男性依 00-S03 只預留 |

## 魔物

正式的 ID 和數值在 07 定。遊戲裡不用 Gravity 的名稱（00-A02），英文名稱用你的中文名稱直譯。

| 檔名 | 中文名稱 | 英文名稱 | 說明 |
|---|---|---|---|
| monster-gelly.jpg | 果凍怪 | Gelly | 第一版的果凍類。圓球形、半透明、體內有發光核心；移動是彈跳加滾動，攻擊是滾動衝撞（07 第 7.1 節）。圖上的標題 Rolling Orb Glop 不用 |
| monster-fluffy_caterpillar.jpg | 毛絨蟲 | Fluffy Caterpillar | 第一版的毛蟲類 |
| monster-young_treant.jpg | 小樹精 | Young Treant | 第一版的植物類。不是人形：樹樁身體、樹根當腳、樹枝當手、頭頂一圈枝葉；用上排的造型，下排的斷樁版本不做（07 第 7.3 節） |
| monster-cute_bunny.jpg | 可愛兔 | Cute Bunny | 不在第一版陣容（07-D03） |

## NPC

| 檔名 | 中文名稱 | 英文名稱 | 說明 |
|---|---|---|---|
| npc-adventurer_guild_staff.jpg | 冒險公會服務員 | Adventurer Guild Staff | `adventurer_guild_staff`，M8。任務櫃台，之後也當儲存點和倉庫。披肩上的「Caldwell」是服務組織的名稱，中文是「卡德威爾」；位置在雅典娜神像旁和南門內側 |
| （還沒有圖） | 訓練營地的教官 | Training Instructor | `training_instructor`，M8。先用服務員的模型；之後要的話再生成概念圖 |

## 武器

| 檔名 | 中文名稱 | 對應的武器種類（03 第 3.5 節） |
|---|---|---|
| weapon-dagger.jpg | 短劍類 | `dagger` |
| weapon-one_handed_sword.jpg | 單手劍類 | `one_handed_sword` |
| weapon-two_handed_sword.jpg | 雙手劍類 | `two_handed_sword` |
| weapon-mace.jpg | 鈍器類 | `one_handed_mace`、`two_handed_mace` |
| weapon-one_handed_staff.jpg | 單手杖類 | `one_handed_staff` |

## 防具

| 檔名 | 中文名稱 | 對應的裝備位置（03 第 3.5 節） |
|---|---|---|
| armor-shield.jpg | 盾牌類 | `shield` |

## 地圖與建築

| 檔名 | 中文名稱 | 說明 |
|---|---|---|
| map-kronenberg.jpg | 克羅能堡 | 地圖 `kronenberg` 的佈局（08 第 4 節）。河口的港口城市：北邊城外是河（往東流進海），東邊是海和港口；城堡和銅色圓頂的宮殿在東北的海邊高地，前面是新月形城門和中央廣場；西邊是大教堂和教堂廣場（雅典娜神像）；三座城門（南門開放，西南門、北門是不能過的傳點） |
| map-kronenberg_south_field.jpg | 克羅能堡南方草原 | 地圖 `kronenberg_south_field` 的佈局（08 第 5 節）。北邊是城牆和城門，西北是劍士訓練營地，西邊和西南是松樹林，中央是草地和路網，東邊是海（漁村和碼頭、跨海大橋、水井），東南是沙漠 |
| building-kronenberg.jpg | 克羅能堡的建築 | 寫實的鳥瞰圖（圖上標題是 Kronenberg Design），佈局跟王都地圖一樣；建築的材質、顏色和光線照這張 |
| building-kronenberg_south_field.jpg | 克羅能堡南方草原的建築 | 南門外的氣氛圖。圖上的城門是方形門樓，跟王都的兩張圖（雙圓塔）不同；兩張地圖共用一座南門（雙圓塔、平頂城垛），這張當氣氛參考 |

## 之後會加的圖

提示詞在 `docs/proposals/2026-10-10-art-prompts.md` 第 7 節（P-80～P-102），清單在 `docs/proposals/2026-10-10-art-asset-guide.md` 第 7.1 節。例如：

| 預定的檔名 | 中文名稱 | 提示詞 |
|---|---|---|
| building-kronenberg_house_kit_01.jpg | 王都的建築模組 | P-81 |
| building-kronenberg_wall_kit_01.jpg | 城牆和圓塔的模組 | P-82 |
| building-kronenberg_temple_statue.jpg | 雅典娜神像 | P-101 |
| building-kronenberg_harbor.jpg | 王都的港口 | P-102 |
| face-head_female_01.jpg | 共用頭部的臉 | P-97 |
