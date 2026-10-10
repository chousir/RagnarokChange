# 概念圖清單

這個資料夾是遊戲的目標樣貌（00-S12）。檔名一律用英文（00-S06），格式是 `<類別>-<名稱>.jpg`：

- 類別：`character`（角色）、`monster`（魔物）、`npc`、`weapon`（武器）、`armor`（防具）、`map`（地圖）、`building`（建築）
- 名稱：英文小寫加底線，盡量跟遊戲資料的 ID 一樣；角色依性別加 `_female`、`_male`

你新增圖片時可以照舊用中文檔名，我會改成英文，並把中文名稱登記在下表。中文名稱就是遊戲畫面上預定顯示的名稱（顯示文字的放法見 03 第 7 節）。

> 2026-10-10：依你的指示換了 8 張圖（四隻魔物、兩張地圖、王都建築、冒險公會服務員），原因是舊圖可能有版權疑慮。新舊差異、對規劃書和地圖白模的影響，見 `docs/proposals/2026-10-10-concept-art-update.md`（提案，待你確認）。
> 圖片檔是在本機用 Git LFS 換上的（雲端環境不能上傳 LFS，見 `docs/proposals/README.md` 第 1 步）；如果這裡的說明跟資料夾裡的圖對不上，就是那一步還沒做。

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

正式的 ID 和數值在 07 定。遊戲裡不用 Gravity 的名稱（00-A02），英文名稱用你的中文名稱直譯。2026-10-10 換的新圖，標題都不是 RO 的原名了。

| 檔名 | 中文名稱 | 圖上的英文標題 | 說明 |
|---|---|---|---|
| monster-gelly.jpg | 果凍怪 | Rolling Orb Glop | 第一版的果凍類。2026-10-10 換新圖：圓球形、半透明、體內有發光核心，圖上標了「滾動攻擊」。英文顯示名稱要用 Gelly 還是 Glop，列在提案待確認 |
| monster-fluffy_caterpillar.jpg | 毛絨蟲 | Fluffy Caterpillar | 第一版的毛蟲類。2026-10-10 換新圖：造型跟舊圖相近，細節（眼睛、口器、觸角、背刺）比較清楚 |
| monster-young_treant.jpg | 小樹精 | Young Treant | 第一版的植物類（07）。2026-10-10 換新圖：不再是人形，改成樹樁身體、樹根當腳、樹枝當手、頭頂一圈枝葉。下排有一隻沒有樹冠的斷樁版本，跟上排不一致，處理方式列在提案待確認 |
| monster-cute_bunny.jpg | 可愛兔 | Cute Bunny | 不在第一版陣容（07-D03）。2026-10-10 換新圖：垂耳、站立、戴葉子頭冠和鈴鐺項圈 |

## NPC

| 檔名 | 中文名稱 | 圖上的英文標題 | 說明 |
|---|---|---|---|
| npc-adventurer_guild_staff.jpg | 冒險公會服務員 | Caldwell Servants | 之後才做。2026-10-10 換新圖：藍色背心裙、米色圍裙、披肩上有「Caldwell」字樣和帶翅膀的沙漏徽章。要不要把 Caldwell 當成組織名稱，列在提案待確認 |

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
| map-kronenberg.jpg | KRONENBERG王都 | 地圖 `kronenberg` 的佈局。2026-10-10 換新圖：城裡沒有河，北邊是城堡和新月形的城門，西邊是大教堂，五座城門（東南主城門、西南門、東門、北門、西北小門），南邊和東邊是雙層城牆 |
| map-kronenberg_south_field.jpg | 王都南方草原 | 地圖 `kronenberg_south_field` 的佈局。2026-10-10 換新圖：北邊是城牆和雙塔城門，西邊有水晶遺跡，東北有發光樹洞的老樹，東邊有河、石拱橋、風車農場，中南有商隊營地，東南有池塘、立石、發光植物 |
| building-kronenberg.jpg | KRONENBERG王都的建築 | 2026-10-10 換新圖（圖上標題是 Environment Design）：寫實的鳥瞰圖，王都在湖中，城門外有石橋，東北有圓頂宮殿 |
| building-kronenberg_south_field.jpg | 王都南方草原的建築 | 沒有換。圖上的城門是方形門樓，跟新地圖的雙圓塔城門不同；處理方式列在提案待確認 |

中文名稱「KRONENBERG王都」中英混合，你要求改成完整的中文譯名，候選名稱列在 `docs/proposals/2026-10-10-design-review.md`，確認後再改這裡和 `locale/`。
