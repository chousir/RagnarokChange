# 術語表

> 狀態：第 1 版（2026-10-11，依 `docs/proposals/2026-10-10-design-review.md` 第 2.3、2.4 節和 `2026-10-11-replies.md` 建立）
> 用途：寫 `locale/` 的文字、改名稱、翻譯時都照這張表，前後才會一致（03 第 7 節、10-D08）。
> 資料 ID 的規則在 03（英文小寫加底線）；本表只管玩家看到的名稱。

---

## 1. 規則

| # | 規則 |
|---|---|
| 1 | 職業、技能、素質、狀態優先用**台灣版 RO 的官方譯名**；查不到的先暫譯，標「暫譯」，定案時更新本表 |
| 2 | 地名、人名、組織名：音譯或意譯擇一，整份表一致。之後的野外照「地名＋方位＋地形」命名（例如克羅能堡南方草原） |
| 3 | 繁中不中英混合，但 **RO 本來就用英文縮寫的照 RO 保留**，各語言都一樣、不翻譯：第 6 節的素質和數值（STR、INT、HP、SP、ATK…）和第 8 節的 BOSS、MVP。這兩節就是白名單，守門測試用同一份清單（01 第 4.3 節）；其他一律中文 |
| 4 | 繁中用全形標點（，。：「」（））；數字用半形；加號用全形「＋」，百分比用半形「%」，例如「ATK ＋18」「攻擊速度增加 5%」 |
| 5 | 英文版照 RO 英文版的寫法和縮寫（STR、ATK、Miss、Lucky…） |
| 6 | 不用 Gravity 的名稱（00-A02）：怪物、NPC、組織、地名都用我們自己的名稱 |
| 7 | 新名詞先加進本表，再寫進 `locale/` |

---

## 2. 地圖和地點

| 繁中 | 英文 | ID | 備註 |
|---|---|---|---|
| 克羅能堡 | Kronenberg | `kronenberg` | 換圖畫面的副標「王都」（`map.kronenberg.subtitle`） |
| 克羅能堡南方草原 | Kronenberg South Field | `kronenberg_south_field` | — |
| 中央廣場 | Central Square | — | 克羅能堡 |
| 新月形城門 | Crescent Gate | — | 克羅能堡；城堡區的入口 |
| 大教堂 | Cathedral | — | 克羅能堡 |
| 雅典娜神像 | Statue of Athena | — | 教堂廣場；新角色出生、預設儲存點 |
| 港口 | Harbor | — | 克羅能堡 |
| 南門 | South Gate | — | 兩張地圖共用 |
| 劍士訓練營地 | Swordsman Training Camp | — | 南方草原 |
| 漁村 | Fishing Village | — | 南方草原 |
| 跨海大橋 | Sea Bridge | — | 南方草原；第一版不能過 |

- 地點名稱（ID 是「—」的）目前只出現在規劃書和截圖說明；要顯示在小地圖或對話時，再給 ID 和 `locale` 的鍵。

## 3. 組織和 NPC

| 繁中 | 英文 | ID | 備註 |
|---|---|---|---|
| 卡德威爾 | Caldwell | — | 冒險公會的服務組織（概念圖的 Caldwell Servants） |
| 冒險公會服務員 | Adventurer Guild Staff | `adventurer_guild_staff` | 任務櫃台；之後也當儲存點和倉庫（暫定，M8 寫對話時確認） |
| 訓練營地的教官 | Training Instructor | `training_instructor` | 先用服務員的模型（暫定） |

## 4. 職業

| 繁中 | 英文 | ID |
|---|---|---|
| 初心者 | Novice | `novice` |
| 劍士 | Swordsman | `swordsman` |
| 盜賊 | Thief | `thief` |
| 服事 | Acolyte | `acolyte` |

## 5. 怪物

| 繁中 | 英文 | ID | 備註 |
|---|---|---|---|
| 果凍怪 | Gelly | `gelly` | 英文維持 Gelly（新圖的標題 Rolling Orb Glop 不用） |
| 毛絨蟲 | Fluffy Caterpillar | `fluffy_caterpillar` | — |
| 小樹精 | Young Treant | `young_treant` | — |
| 可愛兔 | Cute Bunny | `cute_bunny` | 不在第一版 |

## 6. 素質、等級和數值（各語言都用英文縮寫）

照 RO：下面的縮寫在繁中、英文（之後的語言也一樣）都直接用，不翻譯。「意思」欄只給規劃書和物品說明參考。

| 縮寫 | 意思 |
|---|---|
| STR、AGI、VIT、INT、DEX、LUK | 力量、敏捷、體力、智力、靈巧、幸運 |
| HP、SP、MaxHP、MaxSP | 生命、魔力、最大值 |
| ATK、MATK | 攻擊力、魔法攻擊力 |
| DEF、MDEF | 防禦力、魔法防禦力 |
| HIT、FLEE | 命中、迴避 |
| CRI | 暴擊 |
| ASPD | 攻擊速度 |
| Base Lv、Job Lv | 基本等級、職業等級 |
| EXP（Base EXP、Job EXP） | 經驗值 |

| 繁中 | 英文 | 備註 |
|---|---|---|
| 完全迴避 | Perfect Dodge | 狀態視窗的項目；戰鬥文字另見第 7 節 |
| 負重 | Weight | — |
| 攻擊速度增加（百分比的效果） | Attack Speed | 例如附加能力「攻擊速度增加 5%」；固定值的寫「ASPD ＋1」 |

## 7. 戰鬥文字

| 繁中 | 英文 | 備註 |
|---|---|---|
| 未命中 | Miss | 10 第 5 節 |
| 完全迴避 | Lucky | 同上 |
| 暴擊 | Critical | 同上 |

## 8. 屬性、種族、體型、怪物等級

| 種類 | 繁中 | 英文 | ID |
|---|---|---|---|
| 屬性 | 無、水、地、火、風、毒、聖、暗、念、不死 | Neutral、Water、Earth、Fire、Wind、Poison、Holy、Shadow、Ghost、Undead | `neutral`、`water`、`earth`、`fire`、`wind`、`poison`、`holy`、`dark`、`ghost`、`undead` |
| 種族 | 無形、不死、動物、植物、昆蟲、魚貝、惡魔、人類、天使、龍族 | Formless、Undead、Brute、Plant、Insect、Fish、Demon、Demi-Human、Angel、Dragon | `formless`、`undead`、`brute`、`plant`、`insect`、`fish`、`demon`、`demihuman`、`angel`、`dragon` |
| 體型 | 小型、中型、大型 | Small、Medium、Large | `small`、`medium`、`large` |
| 怪物等級 | 一般、BOSS、MVP | Normal、BOSS、MVP | `normal`、`boss`、`mvp` |

## 9. 裝備和物品

| 繁中 | 英文 | 備註 |
|---|---|---|
| 武器 | Weapon | — |
| 鎧甲 | Armor | — |
| 盾牌 | Shield | — |
| 披肩 | Garment | — |
| 鞋子 | Shoes | — |
| 飾品 | Accessory | — |
| 頭飾（上段、中段、下段） | Headgear (Upper, Middle, Lower) | — |
| 消耗品 | Consumable | — |
| 卡片插槽 | Card Slot | — |
| 精煉 | Refine | — |
| **附加能力** | Random Option | 遊戲裡的用語；RO 的「附魔」是另一個系統，不混用（06 第 13.2 節） |
| 名稱顏色：白、綠、藍、紫 | White、Green、Blue、Purple | 依附加能力的條數；說明用語：初階／優良、中階／稀有、高階／史詩（10 第 3.3 節） |
| 貨幣 | — | M6 再定（要不要沿用 RO 的 Zeny 一起討論） |

## 10. 系統和介面

| 繁中 | 英文 | 備註 |
|---|---|---|
| 儲存點 | Save Point | — |
| 倉庫 | Storage | — |
| 傳送點 | Warp Portal | 不能過的傳點的訊息：「這條路還沒開放」 |
| 安全區 | Safe Zone | — |
| 任務 | Quest | — |
| 任務追蹤列 | Quest Tracker | — |
| 走路中 | Walking | HUD 的小圖示說明 |
| 回到儲存點 | Return to Save Point | 死亡畫面 |
| 繁體中文 | 繁體中文 | 語言選單一律用該語言的自稱 |
| English | English | 同上 |

## 11. 技能和狀態

- 第一版的技能名稱見 06 第 8.2 節（暫譯），狀態效果見 06 第 9 節。M7 建資料時對照台灣版 RO 的官方名稱定案，再把定案的名稱加進本表。

---

## 12. 修訂紀錄

| 日期 | 內容 |
|---|---|
| 2026-10-11 | 第 1 版：地圖名稱（克羅能堡、克羅能堡南方草原）、卡德威爾、雅典娜神像、附加能力、戰鬥文字 |
| 2026-10-11 | 你的指示：素質和數值的縮寫（STR、ATK、HP…）、BOSS、MVP 照 RO 用英文，各語言都一樣（第 1 節第 3 條、第 6、8 節） |
