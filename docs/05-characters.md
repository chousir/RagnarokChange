# 05 角色、動作與裝備

> 狀態：已確認（2026-10-10，依你的授權先照建議定案，待你之後檢視）
> 建立日期：2026-10-10
> 依據：`docs/00-decisions.md`～`docs/04-art-pipeline.md`
> 決策編號格式：`05-Dxx`
> 修訂：2026-10-11，依 `docs/proposals/`（最終決定在 `2026-10-11-replies.md`）：二連擊暴擊時播該武器的暴擊動作（00-S10、06-D07；05-D06、第 5.3、8、13、15 節）；腳步聲在 M3-c 接上（05-D10、第 12 節）

---

## 1. 目的與範圍

**本文件決定：**
- 人形角色的組成（身體、頭、頭髮、骨架）和換職業的做法
- 裝備的掛點、偏移、頭飾佔格和頭髮顯示模式
- 第一版要做的武器動作組
- 動作清單、動作庫的分法和查找順序
- AnimationTree 的結構
- 攻擊動作怎麼配合 ASPD，以及動作標記
- 伺服器事件怎麼變成動作
- 外觀自訂的預留（blendshape、髮色、瞳色）和第一版的外觀選項
- 動作檢視器的規格（07 的怪物也用）

**不在本文件：**

| 內容 | 文件 |
|---|---|
| 攻擊間隔、命中時間、受擊硬直等數值和規則 | 06 |
| 怪物的動作和程序化動畫 | 07 |
| 鏡頭、按鍵 | 09 |
| 傷害數字、特效、表情圖示 | 10 |
| 模型和動作的製作流程 | 04 |

---

## 2. 決策摘要

| 編號 | 決策 | 理由／對應 00 |
|---|---|---|
| 05-D01 | 人形角色由一副人形骨架加上三組網格組成：Body（依職業和性別）、Head（共用，依性別，含眼睛、眉毛、睫毛、牙齒）、Hair（可換）。骨頭名稱統一成 Godot 人形設定檔的名稱。 | 00-A10、04-D11。 |
| 05-D02 | 換職業時換掉整副身體（身體網格和它的骨架），頭和頭髮用骨頭名稱重新綁到新的骨架上。頭、髮型、髮色、瞳色不變。 | 跟 RO 一樣，換職業不換頭。每個職業的身體各自綁骨（04），骨架長度不同，所以連骨架一起換。 |
| 05-D03 | 掛點用 BoneAttachment3D：頭飾上中下三格掛在 Head 骨頭，武器掛在 RightHand，盾牌掛在 LeftHand。位置偏移寫在裝備的外觀設定（`.visual.tres`），可以依性別、職業身體、髮型覆寫。 | 00-A09；不同身材和髮型都能對齊。 |
| 05-D04 | 頭飾佔哪幾格照資料（03 的 `locations`）。頭髮顯示模式有三種：normal、hide_top（帽子：用頭髮材質的裁切面藏起上半部）、hide_all（全罩頭盔）。同時戴好幾件時，用最嚴格的那一種。 | 大綱；用裁切面就不用把每種髮型拆成好幾塊。 |
| 05-D05 | 第一版的武器動作組有 6 種：fist（徒手）、dagger、one_handed_sword、two_handed_sword、one_handed_mace、one_handed_staff。槍、斧、弓之後再做。 | 大綱要求至少徒手、短劍、單手劍、鈍器；概念圖另外有雙手劍和單手杖。 |
| 05-D06 | 動作清單照 00-A08（第 5 節）。Miss 沒有動作；二連擊沿用普攻動作，二連擊暴擊時用該武器的暴擊動作；暴擊每種武器各一個（00-S10）。 | 00-A08、00-S10（2026-10-11 改：Renewal 的二連擊可以暴擊，06-D07）。 |
| 05-D07 | 動作庫分成共用（`human_common`）、依武器（`weapon_<種類>`），以及性別專屬的覆寫。查找順序：武器組的性別版 → 武器組 → 共用的性別版 → 共用 → 站立動作（並記錄錯誤）。 | 大綱。 |
| 05-D08 | AnimationTree：狀態機管站、走、跑、坐、詠唱、死亡；一次性的全身動作（攻擊、暴擊、受擊、施放、撿東西、表情）用 OneShot；攻擊另外有時間縮放。站、走、跑用 BlendSpace1D 依速度混合。 | 大綱。 |
| 05-D09 | 攻擊動作的播放速度依伺服器送來的揮擊時間和命中時間調整，讓動作的命中點剛好落在命中時間（也就是依 ASPD）。播放速度限制在 0.5～3 倍。 | 大綱；03-D11 的命中時間。 |
| 05-D10 | 動作標記用 Godot 4.4 起的動畫 marker：`hit`（命中點，多段攻擊可以有多個）、`cast`（施放點）、`pick`（撿起的瞬間）、`footstep_l`、`footstep_r`。客戶端在標記的時間顯示數字、特效、播放音效（腳步聲依腳下的地面種類，M3-c，10）。 | 大綱；RO 的動作檔也有標示傷害出現格的 atk 事件。 |
| 05-D11 | 伺服器事件和狀態怎麼變成動作，有固定的對照表（第 8 節）。客戶端只播放，不判定。 | 01 第 8 節。 |
| 05-D12 | 受擊動作照 RO：全身的動作，角色會停下來；沒有受擊硬直時（例如劍士的「霸體」）不播。 | 00-S07；RO 被打時會停下來（02 參考的 battle.conf）。 |
| 05-D13 | 戰鬥待機姿勢：有攻擊意圖時，以及最後一次揮擊或被打之後 5 秒內顯示，之後回到一般站立。 | 表現上的選擇，可以調整。 |
| 05-D14 | 外觀預留：臉部 blendshape 用 ARKit 命名的 16 個（第 10 節），臉型之後用 `face_` 開頭的名稱。髮色、瞳色是材質參數。模型沒有某個 blendshape 時直接略過。 | 00-A10、大綱。 |
| 05-D15 | 第一版的外觀選項：4 種髮型、4 種髮色、2 種瞳色，都來自概念圖。新角色的預設是雙馬尾、赤褐色頭髮、棕色眼睛（初心者概念圖）。 | 04 第 13.1 節的 4 種髮型；新角色從初心者開始。 |
| 05-D16 | 動作檢視器是獨立的客戶端場景（`--viewer`），可以組合角色和裝備、播放所有動作、用 ASPD 滑桿看攻擊速度，也能自動截圖。07 的怪物用同一個檢視器。 | 大綱、01-D09。 |
| 05-D17 | 移動動作照 09 的大綱：正常速度播跑步，被減速時播走路；播放速度依實際的移動速度調整，避免腳底打滑。 | 計畫大綱的 09。 |

---

## 3. 角色的組成

### 3.1 節點結構

```text
CharacterView（Node3D，客戶端的實體視圖，01 第 8 節）
  └─ Model（Node3D，固定轉 180°：模型面向 +Z，實體的前方是 −Z，03-D16）
       ├─ Skeleton3D（人形骨架，跟著職業身體一起換）
       │    ├─ Body               依職業和性別，例如 novice_female
       │    ├─ Head               共用：head_female_01（含眼睛、眉毛、睫毛、牙齒）
       │    ├─ Hair               可換：hair_twin_tails 等
       │    ├─ HeadAttach         BoneAttachment3D（Head）→ 頭飾上、中、下
       │    ├─ RightHandAttach    BoneAttachment3D（RightHand）→ 武器
       │    └─ LeftHandAttach     BoneAttachment3D（LeftHand）→ 盾牌
       ├─ AnimationPlayer        動作庫（第 6 節）
       └─ AnimationTree          第 7 節
```

### 3.2 骨架

- 骨頭名稱用 Godot SkeletonProfileHumanoid 的名稱（Hips、Spine、Chest、UpperChest、Neck、Head、LeftUpperArm、LeftHand、LeftUpperLeg、LeftFoot 等）。匯入時開啟「重新命名骨頭」，所以不管骨架來自 Mixamo、Blender Rigify 還是 Quaternius，名稱都一樣（04-D12、04-D13）。
- 每個職業身體各自綁一副骨架，骨頭長度可以不同；動作都經過重定向，所以每副骨架都能播同一組動作。
- 頭和頭髮只綁在 Neck、Head 兩根骨頭上（04 第 9.1 節），所以可以套到任何一副身體骨架上。

### 3.3 換職業（05-D02）

```text
收到外觀變更（02 的 StateChange）
  → 載入新職業身體的場景（身體網格＋骨架，04 的成品）
  → 把 Head、Hair 用骨頭名稱綁到新的骨架上（Godot 匯入要開「Use Named Skins」，見第 16 節）
  → 掛點和裝備重新掛上
  → AnimationTree 接上新的骨架，從目前的動作狀態繼續
```

- 外觀資源在背景先載入（03 第 5 節），換的那一刻不會卡頓。

### 3.4 性別

- 第一版只有女性（00-S03）。男性的頭部（`head_male_01`）、身體（`*_male`）、動作的性別覆寫都已經預留，資料不用改（03 的 `visual_ids` 已經分性別）。

---

## 4. 裝備外顯

### 4.1 掛點

| 裝備位置（03 第 3.5 節） | 掛在哪根骨頭 | 說明 |
|---|---|---|
| head_top、head_mid、head_low | Head | 三格都掛在頭骨。模型的原點就是頭部掛點（04 第 8.1 節），所以大多數頭飾不用偏移 |
| weapon | RightHand | 原點是握持點，對齊手心。雙手武器也掛在右手，左手由動作去握 |
| shield | LeftHand | 原點是手把的握持點 |

- 跟 RO 一樣，收起來的武器不顯示（04 第 13.1 節）。
- garment、shoes、accessory 這些位置照資料存在，但沒有外觀（00-A09 只要求頭飾三格、武器、盾牌）。

### 4.2 偏移和覆寫

裝備的外觀設定（`.visual.tres`，03 第 5 節）裡有：

| 欄位 | 內容 |
|---|---|
| 基本偏移 | 位置、旋轉、縮放 |
| 依性別覆寫 | 男性、女性各自的偏移 |
| 依職業身體覆寫 | 例如肩甲很厚的身體，盾牌要往外移 |
| 依髮型覆寫（頭飾） | 例如緞帶在雙馬尾和長直髮上的位置不同 |
| 頭髮顯示模式（頭飾） | normal、hide_top、hide_all，以及 hide_top 用的裁切高度 |
| 拖尾的起點和終點（武器） | 10 的特效用 |

覆寫的優先順序：髮型 → 職業身體 → 性別 → 基本。

### 4.3 頭飾規則（05-D04）

| 規則 | 內容 |
|---|---|
| 佔格 | 照資料的 `locations`。一件頭飾佔好幾格時（例如全罩頭盔佔上和中），只顯示一次 |
| 衝突 | 戴上新的頭飾時，會跟它佔同一格的頭飾被卸下（伺服器的規則在 06） |
| 頭髮顯示 | normal：頭髮照常顯示；hide_top：頭髮材質在頭骨空間有一個裁切面，裁切面以上的頭髮不畫（帽子底下）；hide_all：整個頭髮不顯示 |
| 多件的組合 | 取最嚴格的：hide_all ＞ hide_top ＞ normal；hide_top 有多個高度時取最低的 |

- 用材質裁切的理由：每種髮型不用拆成上下好幾塊；被裁掉的地方剛好藏在帽子底下。
- 第一版的三件頭飾（04 第 13.2 節）：`novice_helmet` 用 hide_top，`bandana` 用 hide_top，`ribbon` 用 normal。

---

## 5. 動作清單（05-D06）

「Mixamo 關鍵字」是在 Mixamo 搜尋時用的詞，實際選哪一個動作在 M3 決定，選好後寫進動作庫。「開始」是第一次用到的里程碑，以 11 為準；動作檢視器在 M3 就能看全部。

### 5.1 共用動作（`human_common`）

| 動作 ID | 中文 | 類型 | 標記 | Mixamo 關鍵字 | RO 對應 | 開始 |
|---|---|---|---|---|---|---|
| `idle` | 站立 | 迴圈 | — | breathing idle | 站立 | M3 |
| `idle_fidget_01`～`03` | 待機小動作 | 一次 | — | looking around、stretching、weight shift | 沒有（00-A08 加的） | M3 |
| `walk` | 走 | 迴圈 | footstep_l、footstep_r | walking（in place） | 走路 | M3 |
| `run` | 跑 | 迴圈 | footstep_l、footstep_r | running（in place） | 走路（RO 只有一種移動動作） | M3 |
| `sit_down` | 坐下 | 一次 | — | stand to sit（ground） | 坐下 | M3 |
| `sit_idle` | 坐著 | 迴圈 | — | sitting idle（ground） | 坐下 | M3 |
| `stand_up` | 起身 | 一次 | — | sit to stand（ground） | — | M3 |
| `pick_up` | 撿物品 | 一次 | pick | picking up | 撿東西 | M6 |
| `hit` | 受擊 | 一次 | — | hit reaction | 受擊 | M5 |
| `cast` | 詠唱 | 迴圈 | — | magic casting idle | 詠唱 | M7 |
| `skill_cast` | 技能施放 | 一次 | cast | standing 1h magic attack | 施放 | M7 |
| `death` | 死亡 | 一次 | — | dying、falling back death | 死亡 | M5 |
| `dead_loop` | 倒地 | 迴圈 | — | 用 `death` 的最後一格 | 死亡 | M5 |
| `revive` | 復活 | 一次 | — | getting up | 沒有（00-A08 加的） | M5 |

### 5.2 表情動作（`human_common`）

00-A08 有「表情動作」。RO 的表情是頭上的圖示（10 會做），這裡另外做全身的動作。第一版 10 種，按鍵在 09。

| 動作 ID | 中文 | Mixamo 關鍵字 | 臉部表情（第 10 節） |
|---|---|---|---|
| `emote_wave` | 揮手 | waving | 微笑 |
| `emote_bow` | 鞠躬 | bowing | — |
| `emote_clap` | 拍手 | clapping | 微笑 |
| `emote_cheer` | 歡呼 | cheering | 張嘴笑 |
| `emote_laugh` | 大笑 | laughing | 張嘴笑 |
| `emote_think` | 思考 | thinking | 皺眉 |
| `emote_no` | 搖頭 | shaking head no | — |
| `emote_yes` | 點頭 | head nod yes | — |
| `emote_angry` | 生氣 | angry | 皺眉、瞇眼 |
| `emote_cry` | 哭泣 | crying | 嘴角下垂 |

### 5.3 依武器的動作（`weapon_<種類>`）

每種武器有 3 個動作：

| 動作 ID | 中文 | 類型 | 標記 | RO 對應 |
|---|---|---|---|---|
| `combat_idle` | 戰鬥待機 | 迴圈 | — | 準備戰鬥的站姿 |
| `attack` | 普攻 | 一次 | hit | 攻擊 |
| `critical` | 暴擊 | 一次 | hit | 攻擊（RO 用同一個動作加特效；00-S10 決定每種武器另做） |

| 武器種類 | 普攻的 Mixamo 關鍵字 | 暴擊的 Mixamo 關鍵字 | 戰鬥待機的 Mixamo 關鍵字 |
|---|---|---|---|
| fist | punching、cross punch | punch combo、hook punch | fighting idle |
| dagger | stabbing、knife attack | dagger slash combo | knife idle |
| one_handed_sword | sword and shield slash | sword and shield attack（較大的動作） | sword and shield idle |
| two_handed_sword | great sword slash | great sword high spin attack | great sword idle |
| one_handed_mace | standing melee attack downward | standing melee combo attack | sword and shield idle |
| one_handed_staff | standing melee attack horizontal | standing 1h magic attack（揮擊版） | standing idle（持杖） |

- 拿盾牌時用同一組動作（RO 沒有拿盾牌專用的攻擊動作）。
- 二連擊沿用 `attack`；二連擊暴擊時播 `critical`（Renewal 的二連擊可以暴擊，06-D07）。兩段傷害的數字怎麼顯示由 10 決定（00-S10）。
- Miss 沒有動作，只顯示文字（00-S10）。

### 5.4 第一版的動作數量

| 組 | 數量 |
|---|---|
| 共用（含 3 個待機小動作） | 16 |
| 表情 | 10 |
| 武器（6 種 × 3 個） | 18 |
| 合計 | 44 |

- 04 第 9.4 節：Mixamo 的動作要由你在網站上下載。Quaternius 的免費版有的基本動作（站立、走、跑、受擊、死亡等）可以先用，減少要下載的數量。

---

## 6. 動作庫與命名（05-D07）

```text
assets/animations/
  human_common/              共用動作（AnimationLibrary，.res，LFS）
  human_common_female/       女性專屬的覆寫（例如走路、站姿），沒有就用共用的
  weapon_fist/  weapon_dagger/  weapon_one_handed_sword/
  weapon_two_handed_sword/  weapon_one_handed_mace/  weapon_one_handed_staff/
```

- 動作名稱就是第 5 節的動作 ID（英文小寫加底線）。
- 查找順序（以女性拿短劍的 `attack` 為例）：`weapon_dagger` 的女性版 → `weapon_dagger` → `human_common_female` → `human_common` → `idle`（找不到時記錄錯誤，冒煙測試會失敗）。
- 動作一律 30 fps、原地（in place）、沒有根骨位移；移動由程式控制（01-D08）。
- 匯入時開啟「位置軌跡正規化」（Normalize Position Tracks），不同身高的角色播同一組動作，腳也不會滑。

---

## 7. AnimationTree（05-D08）

```text
AnimationTree（根：BlendTree）
  ├─ StateMachine「main」
  │    ├─ locomotion   BlendSpace1D（速度：0 → idle、走路速度 → walk、跑步速度 → run）
  │    ├─ combat_idle  依目前的武器
  │    ├─ sitting      sit_down → sit_idle → stand_up
  │    ├─ casting      cast（迴圈）
  │    └─ dead         death → dead_loop；revive 之後回到 locomotion
  ├─ OneShot「action」  attack、critical、skill_cast、pick_up、emote_*、hit（全身）
  └─ TimeScale「action_speed」  攻擊依 ASPD 調整播放速度
```

- 全部的一次性動作都是全身的。RO 攻擊、施放、撿東西時都站著不動，被打時也會停下來（05-D12），所以不需要上下半身分開。
- 待機小動作：在 `idle` 狀態停留時，每 8～15 秒隨機播一個（客戶端的外觀隨機數，01 第 15 節）。
- 狀態切換的混合時間 0.1～0.2 秒。

---

## 8. 伺服器事件 → 動作（05-D11）

播放的時間點照 02 第 8 節：其他實體在插值時間軸上播放，自己的角色收到就播。

| 伺服器訊息（02 第 4.5 節） | 內容 | 動作 |
|---|---|---|
| Snapshot | 移動速度、移動狀態 | locomotion 的速度參數；靜止時是 idle 或 combat_idle |
| StateChange（坐下、起身） | — | sitting 狀態 |
| StateChange（表情） | 表情 ID | `emote_*`，加上臉部表情 |
| StateChange（死亡、復活） | — | dead 狀態；`revive` |
| StateChange（外觀、裝備） | 新的職業身體、髮型、裝備外顯 | 換身體或髮型、重新掛裝備（第 3.3 節） |
| AttackResult（自己是攻擊者） | 揮擊時間、段數；每段的命中時間、是否命中、是否暴擊 | 有任何一段是暴擊（包含二連擊暴擊）：`critical`；其他（一般、Miss、二連擊）：`attack`。播放速度依第 9 節（用第一段的命中時間） |
| AttackResult（自己是目標） | 結果、命中時間、受擊硬直 | 有傷害而且有受擊硬直時，在命中時間播 `hit`；Miss 沒有動作 |
| 技能相關（詠唱開始、中斷、效果） | — | casting 狀態；中斷時回到站立；施放時 `skill_cast` |
| 物品相關（撿起） | — | `pick_up` |
| EntityAppear、MapReady | — | 依目前狀態直接進入對應的狀態，不播過場 |

---

## 9. 攻擊動作的時間（05-D09）

```text
伺服器：揮擊時間 S、命中時間 H（02 的 AttackResult）
動作：  hit 標記在動作裡的位置 h（秒，原本的速度）

播放速度 ＝ h ÷（H − S）  限制在 0.5～3 倍
```

- 這樣動作的命中點一定落在伺服器套用傷害的時間，傷害數字也在同一刻出現（02 第 8 節）。
- ASPD 很高時，下一次揮擊會在上一個動作結束前開始，直接混合到下一次攻擊。
- 速度超出 0.5～3 倍時就用上限或下限，命中點和數字會差一點點；遇到這種情況記錄下來，再回頭調整動作。
- 怪物的命中時間來自資料的 `attack_hit_ms`（03 第 4.5 節），玩家的由 06 依 ASPD 算出。

---

## 10. 外觀預留（05-D14、05-D15）

### 10.1 臉部 blendshape

用 Apple ARKit 的命名，第一版用到的 16 個：

| 用途 | 名稱 |
|---|---|
| 眨眼 | eyeBlinkLeft、eyeBlinkRight |
| 眼睛 | eyeWideLeft、eyeWideRight、eyeSquintLeft、eyeSquintRight |
| 眉毛 | browInnerUp、browDownLeft、browDownRight |
| 嘴巴 | jawOpen、mouthSmileLeft、mouthSmileRight、mouthFrownLeft、mouthFrownRight、mouthPucker |
| 臉頰 | cheekPuff |

- 用途：每 2～6 秒隨機眨眼一次；表情動作配上臉部表情（第 5.2 節）。
- 臉型（外觀自訂用）之後用 `face_<部位>_<方向>` 的名稱，例如 `face_jaw_wide`；03 第 4.11 節的 face_shape 清單到時候再填。
- 模型沒有某個 blendshape 時直接略過，只記一次 debug log（00-A10 的要求：缺少時自動略過）。

### 10.2 髮色和瞳色

- 頭髮的貼圖去色（04 第 9.2 節），材質用 `hair_color` 參數上色；眼睛的材質用 `iris_color` 參數。
- 03 的外觀選項 ID 對應到客戶端外觀設定裡的顏色值（03 第 4.11 節）。

### 10.3 第一版的外觀選項

| 種類 | 選項（ID：中文名稱） | 預設 |
|---|---|---|
| 髮型 | `hair_twin_tails`：雙馬尾、`hair_long_straight`：長直髮、`hair_ponytail`：馬尾、`hair_short_tied`：短髮小馬尾 | 雙馬尾 |
| 髮色 | `auburn`：赤褐、`violet`：紫、`black`：黑、`brown`：棕 | 赤褐 |
| 瞳色 | `brown`：棕、`gray_violet`：灰紫 | 棕 |

- 選項都來自四張女性概念圖（髮型和髮色的組合就是各職業概念圖的樣子），檢視器有「照概念圖」的預設組合，方便對照截圖。
- 外觀自訂畫面之後才做；第一版新角色一律用預設值。

---

## 11. 動作檢視器（05-D16）

| 項目 | 內容 |
|---|---|
| 啟動 | `--viewer`（01 第 5.1 節），只有客戶端，不需要伺服器 |
| 選角色 | 性別、職業身體、髮型、髮色、瞳色、頭飾上中下、武器、盾牌；「照概念圖」的預設組合 |
| 選怪物 | 怪物 ID（07） |
| 動作清單 | 依共用、表情、武器分組；標出用了備用動作（查找順序退回）的項目 |
| 播放 | 播放、暫停、逐格、循環、速度 0.1～3 倍 |
| ASPD 滑桿 | 設定攻擊間隔和命中時間，看攻擊動作在這個攻速下的樣子（第 9 節） |
| 標記 | 時間軸上顯示 hit、cast、pick、腳步；播放到標記時畫面閃一下 |
| 鏡頭 | 環繞、轉台、拉近；地面有 1 公尺格線和身高尺 |
| 光線 | 日光、中性兩種預設 |
| 截圖 | 按鈕截圖；自動截圖模式（01 第 11.3 節）依序截每個角色、每種武器、每個動作的開始、命中點和結尾 |

---

## 12. 第一版要做的和之後才做的

| 項目 | 第一版（M3） | 之後 |
|---|---|---|
| 人形角色組成、換職業、換髮型 | ✔ | — |
| 頭飾三格、武器、盾牌的掛點和偏移 | ✔ | — |
| 頭髮顯示模式 | ✔ | — |
| 共用動作、表情、6 種武器動作組 | ✔（檢視器全部可看；遊戲中依 11 的里程碑接上） | 槍、斧、弓 |
| 攻擊速度配合 ASPD、動作標記 | ✔ | — |
| 腳步聲（依地面種類，10） | ✔（M3-c） | — |
| 眨眼 | ✔ | — |
| 表情動作的臉部表情 | 模型有 blendshape 才有 | 外觀自訂時補齊 |
| 臉型 blendshape | — | 外觀自訂時 |
| 男性 | — | 之後 |

---

## 13. 測試與驗收方式

**M3：**
1. 冒煙測試：每個職業身體 × 每種武器，第 5 節的每個動作都找得到（沒有退回到 `idle`）；缺的話測試失敗，並列出缺哪些（01 第 11.1 節）。
2. 換職業：在檢視器連續換 4 個職業身體，頭和頭髮都正確綁在新的骨架上，播走路動作時脖子沒有裂開（自動截圖，我先看）。
3. 頭飾：三件頭飾都在正確的位置；`novice_helmet` 戴上時，帽子底下沒有頭髮穿出來。
4. 攻擊速度：ASPD 滑桿從低到高，`hit` 標記都落在設定的命中時間（誤差 ≤ 1/60 秒，速度在 0.5～3 倍內時）。
5. 動作標記：每個 `attack`、`critical` 至少有一個 `hit`，每個 `skill_cast` 有 `cast`，`walk`、`run` 有左右腳步。
6. 截圖清單（給你看）：四個職業「照概念圖」的組合，正面、側面、背面；每種武器的普攻和暴擊在命中點的畫面；10 種表情。

**M5 起：**
7. 遊戲中：普攻、暴擊、Miss（沒有動作）、二連擊（普攻動作）、二連擊暴擊（暴擊動作）、受擊、死亡、復活都照第 8 節播放（03 第 12 節第 18 項的命中時間測試）。

---

## 14. 風險與備案

| 風險 | 影響 | 備案 |
|---|---|---|
| 頭和頭髮綁到不同的身體骨架時，脖子對不齊 | 脖子有裂縫 | 04 的管線把身體縮放到同一個身高、對齊脖子；不行就退回每個職業自帶頭部（04 第 9.2 節） |
| Mixamo 的動作套到寫實身材上手臂穿模 | 手穿進身體或裙子 | 重定向時調整、選比較不會穿模的動作；必要時在 Blender 修 |
| 裙子、披肩、長髮沒有物理 | 動作時看起來很硬 | 第一版先接受；之後加骨頭的彈簧物理（Godot 的 SkeletonModifier3D） |
| 攻擊速度很快時動作被壓縮 | 動作看起來太急 | 播放速度上限 3 倍；超過時另做快速版的動作 |
| 用材質裁切的頭髮在帽緣看得到切口 | 不自然 | 調整裁切高度；必要時那件頭飾改用 hide_all |
| 44 個動作要從 Mixamo 手動下載 | 很花時間 | 先用 Quaternius 免費版有的基本動作；Mixamo 只下載缺的 |

---

## 15. 與 RO 原制不同之處（待檢視）

| 項目 | RO 原制 | 本專案 | 理由 |
|---|---|---|---|
| 待機小動作 | 沒有 | 站立時隨機播 | 00-A08 決定的 |
| 跑步 | 只有一種走路動作 | 正常速度播跑步，減速時播走路 | 計畫大綱的 09；速度本身照 RO |
| 復活 | 沒有復活動作，直接站起來 | 有起身的動作 | 00-A08 決定的 |
| 表情 | 頭上的表情圖示 | 圖示（10）加上全身的表情動作 | 00-A08 決定的「表情動作」 |
| 暴擊 | 同一個攻擊動作加上特效 | 每種武器有專屬的暴擊動作；二連擊暴擊也播暴擊動作 | 00-S10 決定的（2026-10-11 加上二連擊暴擊） |
| 眨眼、臉部表情 | 2D sprite 沒有 | 有 | 寫實 3D 的表現；不影響機制 |
| 戰鬥待機姿勢顯示多久 | 客戶端自己的表現 | 攻擊或被打後 5 秒 | 表現上的選擇 |

除了上表，本文件其他部分都照 RO：
- 換職業只換服裝，頭和髮型不變
- 攻擊、施放、撿東西時站著不動
- 被打時全身受擊、會停下來；沒有受擊硬直時不播
- Miss 沒有動作，二連擊沿用普攻（00-S10；二連擊暴擊見上表）
- 攻擊動作的速度跟著攻速走
- 身上不顯示收起來的武器

---

## 16. 需要修改已確認文件的地方

依你的授權（2026-10-10），以下修改已經直接改好，對應文件的狀態列都註明了修訂日期。

| 文件 | 位置 | 原本的寫法 | 改成 | 理由 |
|---|---|---|---|---|
| 03 | 第 4.11 節外觀選項表的「第一版」欄 | 髮型、髮色、瞳色都「只有 `default`」 | 髮型 4 種、髮色 4 種、瞳色 2 種（05 第 10.3 節），臉型清單先空著 | 04 第 13.1 節有 4 種髮型，檢視器也要能對照概念圖 |
| 04 | 第 11 節 Godot 匯入設定表 | 沒有寫骨架網格的綁定方式 | 加一列「網格的骨架綁定：開啟 Use Named Skins（用骨頭名稱綁定），頭和頭髮才能套到任何一副身體骨架上」 | 05-D02 |

---

## 17. 待你確認事項

> 2026-10-10 你授權先全部照建議定案，以下 10 項都已照建議採用，等你之後檢視。

| # | 事項 | 建議（已採用） |
|---|---|---|
| 1 | 第一版的武器動作組 | 6 種：徒手、短劍、單手劍、雙手劍、鈍器、單手杖 |
| 2 | 新角色的預設外觀 | 雙馬尾、赤褐色頭髮、棕色眼睛（初心者概念圖） |
| 3 | 帽子底下的頭髮 | 用頭髮材質的裁切面藏起來（不拆頭髮模型） |
| 4 | 戰鬥待機姿勢 | 攻擊或被打後顯示 5 秒 |
| 5 | 攻擊動作的播放速度 | 限制在 0.5～3 倍 |
| 6 | 臉部 blendshape | ARKit 命名的 16 個（第 10.1 節） |
| 7 | 表情動作 | 10 種（第 5.2 節） |
| 8 | 受擊動作 | 照 RO：全身、會停下來；沒有受擊硬直時不播 |
| 9 | 動作檢視器的規格 | 第 11 節 |
| 10 | 修改 03、04 | 第 16 節（已改好） |

---

## 18. 與 00 決策對照

| 00 決策 | 本文件對應 |
|---|---|
| 00-A08 動作 | 05-D06、第 5 節 |
| 00-A09 裝備外顯 | 05-D03、05-D04、第 4 節 |
| 00-A10 外觀自訂預留 | 05-D01、05-D14、05-D15、第 10 節 |
| 00-S02 點怪後依 ASPD 連打 | 05-D09、第 9 節 |
| 00-S03 先做女性 | 第 3.4 節 |
| 00-S07 以 RO 機制為主 | 05-D12、第 15 節 |
| 00-S10 Miss、二連擊、暴擊的動作 | 05-D06、第 5.3、8 節 |
| 00-S12 概念圖 | 05-D15（外觀選項來自概念圖）、檢視器的「照概念圖」組合 |

其他 00 決策跟角色和動作沒有直接關係，由其他文件處理。

---

## 19. 參考來源

**Godot 4.7**
- 骨架重定向（BoneMap、SkeletonProfileHumanoid、重新命名骨頭、位置軌跡正規化）：https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/retargeting_3d_skeletons.html
- AnimationPlayer 的 marker 和區段播放（4.4 起）：https://docs.godotengine.org/en/4.7/classes/class_animationplayer.html
- AnimationTree（狀態機、BlendSpace1D、OneShot、TimeScale）：https://docs.godotengine.org/en/4.7/tutorials/animation/animation_tree.html
- BoneAttachment3D：https://docs.godotengine.org/en/4.7/classes/class_boneattachment3d.html
- 匯入設定（Use Named Skins）：https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/importing_3d_scenes/import_configuration.html

**RO**
- RO 動作檔的 atk 事件（標示傷害數字和受擊出現的那一格）：https://github.com/csnv/act-parser/blob/master/docs/fix-attack-delay.md
- 被打時停下來（02 已引用）：https://github.com/rathena/rathena/blob/master/conf/battle/battle.conf

**其他**
- ARKit 的臉部 blendshape 名稱：https://developer.apple.com/documentation/arkit/arfaceanchor/blendshapelocation
