# 生圖提示詞（複製用）

> 狀態：參考用（2026-10-10）
> 用法和流程在 `2026-10-10-art-asset-guide.md`；本文件只放提示詞。編號（P-xx）跟指南對應。
> 修訂：2026-10-11，南方草原地圖換新：P-61～P-73 換成新地標、P-74 和 P-75 拿掉、P-88～P-93 換掉、P-94 只在選雙圓塔城門時才用、P-120 的草原改寫；P-51 改成方形雙塔，原本的雙圓塔改名 P-51b

---

## 0. 使用方式

1. 提示詞用英文，大部分生圖工具對英文的理解比較好。
2. **給 Tripo 的視角圖**（P-11～P-75）：先生成正面（front），再把正面圖當參考圖，用 P-02（左）、P-03（後）、P-04（右）生成其他視角。每一段提示詞後面都要接上 **P-01**。
   - **Tripo 免費方案沒有多視角，只要一張圖**：角色、怪物、武器只生成正面；道具、地標的提示詞本來就是 3/4 視角或正面一張。初心者（女）用 P-11F（頭髮盤起、不畫背包），背包另外用 P-28（見 `2026-10-10-review-round-2.md` 第 6.3 節）。
3. 工具可以放參考圖的話，把對應的概念圖也放進去，顏色和細節會比較準。
4. 工具有「負面提示詞」欄位的話，貼 **P-05**；生成武器、盾牌時，把 P-05 裡的 `weapon, shield` 拿掉。
5. 比例：視角圖用 1:1（建築、橋用 16:9 也可以）；概念圖用 4:3；載入畫面用 16:9。
6. `{...}` 是要你填的地方，填之前把大括號一起拿掉。
7. 提示詞不能加任何遊戲、公司、作品、角色、畫家的名字（指南第 3.3 節）。

---

## 1. 共通區塊

### P-01 視角圖的共通結尾（每一段視角圖的提示詞後面都接這段）

```text
Plain flat medium-gray background (#808080) with no gradient, no floor, no grid and no shadow. Soft, even, diffuse studio lighting, no strong highlights, no rim light, no colored light. Orthographic camera at the subject's mid-height, no perspective distortion. The whole subject is visible and centered with a small margin on every side. One subject only. No text, no letters, no labels, no arrows, no measurement lines, no watermark, no border, no collage.
```

### P-02 左側（放正面圖當參考）

```text
Use the attached image as the reference. Show exactly the same subject, with the same design, colors, materials, proportions and pose (if it is a character or a creature, keep the same A-pose), in an orthographic LEFT side view: the camera is on the subject's left side, so the subject faces the left edge of the image. A true 90-degree profile, not a three-quarter view.
```

### P-03 背面（放正面圖當參考）

```text
Use the attached image as the reference. Show exactly the same subject, with the same design, colors, materials, proportions and pose, in an orthographic BACK view: the camera is directly behind the subject. Show the back details clearly, such as straps, pouches, hair, seams and fastenings.
```

### P-04 右側（放正面圖當參考）

```text
Use the attached image as the reference. Show exactly the same subject, with the same design, colors, materials, proportions and pose (if it is a character or a creature, keep the same A-pose), in an orthographic RIGHT side view: the camera is on the subject's right side, so the subject faces the right edge of the image. A true 90-degree profile, not a three-quarter view.
```

### P-05 負面提示詞

```text
text, letters, words, watermark, logo, signature, label, caption, border, frame, multiple views, collage, split screen, extra people, extra objects, weapon, shield, cast shadow, floor, ground plane, grid, perspective distortion, fisheye, dramatic lighting, rim light, colored lighting, motion blur, cropped, cut off, out of frame, blurry, low resolution
```

### P-06 角色的姿勢（P-11～P-14 已經包含，這裡單獨列出，方便你調整）

```text
Standing straight in an A-pose: arms about 45 degrees away from the body, elbows slightly bent, palms facing the thighs, fingers slightly apart and not holding anything, feet shoulder-width apart, looking straight ahead with a neutral expression.
```

---

## 2. 角色（正面，接 P-01；其他視角用 P-02～P-04）

### P-11 初心者（女）`novice_female`

```text
Orthographic FRONT view of an original character: a young woman novice adventurer, full body, about 1.60 m tall, slim build, calm friendly expression. Standing straight in an A-pose: arms about 45 degrees away from the body, elbows slightly bent, palms facing the thighs, fingers slightly apart and not holding anything, feet shoulder-width apart, looking straight ahead.
Realistic fantasy medieval European style, high-quality game character, physically based materials with light wear and dirt.
Hair: auburn shoulder-length hair with side-swept bangs, tied into two short low twin tails.
Outfit: a sleeveless off-white linen tunic reaching mid-thigh with a laced V-neck, over a dark red undershirt that shows at the neckline and through the side slits; two brown leather straps crossing in an X over the chest (backpack straps); a dark red wool sash under a wide brown leather belt with a brass buckle; a small brown leather pouch on the right hip; brown fingerless leather gloves with off-white cloth wraps on the forearms; off-white canvas trousers with a sewn patch on one knee; tall brown leather boots with folded-down cuffs and buckle straps; a dark brown leather backpack with a buckled flap worn on the back.
No helmet, no hat, no weapon, no scabbard, no shield.
```

### P-12 劍士（女）`swordsman_female`

```text
Orthographic FRONT view of an original character: a young woman swordswoman, full body, about 1.65 m tall, athletic build, serious calm expression. Standing straight in an A-pose: arms about 45 degrees away from the body, elbows slightly bent, palms facing the thighs, fingers slightly apart and not holding anything, feet shoulder-width apart, looking straight ahead.
Realistic fantasy medieval European style, high-quality game character, physically based materials with light wear and dirt.
Hair: very long straight dark violet hair with blunt bangs, reaching the middle of the back; the hair falls behind the shoulders so the cape and the shoulders stay clearly visible.
Outfit: a short mustard-yellow shoulder cape with a layered ruffled edge and small red-orange floral embroidery on the shoulders; a beaded necklace with a small bronze pendant; a polished steel breastplate under the cape; a dark brown long-sleeve wool coat-dress with a long mustard-yellow front panel reaching below the knees; a brown leather belt at the waist and a second mustard leather belt worn diagonally on the hips; engraved steel vambraces on the forearms and steel elbow guards; mustard-yellow leather gloves; a long dark brown skirt with a scalloped lace hem; brown leather ankle boots with turned-down cuffs.
No weapon, no scabbard, no shield.
```

### P-13 盜賊（女）`thief_female`

```text
Orthographic FRONT view of an original character: a young woman rogue adventurer, full body, about 1.65 m tall, slim athletic build, calm expression. Standing straight in an A-pose: arms about 45 degrees away from the body, elbows slightly bent, palms facing the thighs, fingers slightly apart and not holding anything, feet shoulder-width apart, looking straight ahead.
Realistic fantasy medieval European style, high-quality game character, physically based materials with light wear and dirt.
Hair: long black hair with side-swept bangs and two face-framing strands, tied in a long low ponytail.
Outfit: a cropped ochre-yellow leather jacket with long sleeves and rolled cuffs; a single dark brown leather shoulder guard on the LEFT shoulder only; a cropped off-white bodice top with silver swirl embroidery and small red leather straps, leaving the midriff bare; low-rise olive-green cargo trousers with large side pockets, a sewn patch on the LEFT knee and a round embossed leather knee guard on the RIGHT knee; layered brown leather belts with a small red cloth bow at the front, an iron ring, and a leather pouch on the LEFT hip; brown fingerless leather gloves with cloth wraps on the forearms; tall brown leather boots with several buckle straps.
No headscarf, no hat, no weapon, no shield.
```

### P-14 服事（女）`acolyte_female`

```text
Orthographic FRONT view of an original character: a young woman acolyte of a temple order, full body, about 1.65 m tall, gentle calm expression. Standing straight in an A-pose: arms about 45 degrees away from the body, elbows slightly bent, palms facing the thighs, fingers slightly apart and not holding anything, feet shoulder-width apart, looking straight ahead.
Realistic fantasy medieval European style, high-quality game character, physically based materials with light wear and dirt.
Hair: short dark brown bob with bangs, the back gathered into a small low ponytail at the nape, with no ribbon.
Outfit: an off-white short shoulder capelet with a stand-up collar and a round brass clasp; a dark brown long-sleeve tunic reaching mid-thigh with a mauve V-shaped inset and a small embroidered ornament on the chest; elbow-length dark brown leather gloves; a brown leather belt with a small leather-bound book in a holder on the LEFT hip, a small red cloth pouch on the RIGHT hip, and a small silver cross pendant hanging from the belt; an off-white overskirt open at the front, edged with gold and lavender embroidery, over a knee-length dark brown skirt with an embroidered hem; tall brown leather boots with several buckles.
No ribbon, no hat, no weapon, no staff, no shield.
```

---

### P-11F 初心者（女）`novice_female`——Tripo 免費方案用（單張正面）

跟 P-11 的差別：頭髮全部盤起來（脖子和肩膀完全露出來）、不畫背包（背包用 P-28 另外做）。後面接 P-01。

```text
Orthographic FRONT view of an original character: a young woman novice adventurer, full body, about 1.60 m tall, slim build, calm friendly expression. Standing straight in an A-pose: arms about 45 degrees away from the body, elbows slightly bent, palms facing the thighs, fingers slightly apart and not holding anything, feet shoulder-width apart, looking straight ahead.
Realistic fantasy medieval European style, high-quality game character, physically based materials with light wear and dirt.
Hair: auburn hair pulled back tightly into a small bun at the back of the head, so the neck and the shoulders are completely clear.
Outfit: a sleeveless off-white linen tunic reaching mid-thigh with a laced V-neck, over a dark red undershirt that shows at the neckline and through the side slits; two brown leather straps crossing in an X over the chest and over the back; a dark red wool sash under a wide brown leather belt with a brass buckle; a small brown leather pouch on the right hip; brown fingerless leather gloves with off-white cloth wraps on the forearms; off-white canvas trousers with a sewn patch on one knee; tall brown leather boots with folded-down cuffs and buckle straps.
No backpack, no helmet, no hat, no weapon, no scabbard, no shield.
```

### P-28 初心者的背包 `novice_backpack`（Tripo 免費方案用，單張 3/4 視角）

後面接 P-01。

```text
Three-quarter view from slightly above of a single adventurer's backpack, isolated: dark brown leather, about 40 cm tall, 30 cm wide and 15 cm deep, rectangular with rounded corners, a large buckled front flap, a small strap with a brass buckle on the flap, worn and scuffed leather, and two short shoulder-strap stubs at the top and the bottom of the back panel. Realistic, physically based materials.
```

## 3. 髮型、頭飾（正面，接 P-01；其他視角用 P-02～P-04）

### P-20 髮型的共通開頭（後面接 P-21～P-24 其中一段，再接 P-01）

```text
Orthographic FRONT view of a single hairstyle on a plain smooth light-gray mannequin head with no facial features (no eyes, no nose, no mouth), head and neck only. Hair color: neutral light brown. Realistic hair made of clearly separated strands and clumps, like high-quality game hair. Hairstyle:
```

### P-21 `hair_twin_tails`

```text
shoulder-length hair with side-swept bangs, tied into two short low twin tails just below the ears, with a few loose strands framing the face.
```

### P-22 `hair_long_straight`

```text
very long straight hair reaching the waist, with blunt straight-cut bangs; the hair falls behind the shoulders.
```

### P-23 `hair_ponytail`

```text
long hair with side-swept bangs and two long face-framing strands, the rest tied into a long low ponytail reaching the shoulder blades.
```

### P-24 `hair_short_tied`

```text
short bob reaching the jawline with bangs, the back gathered into a small low ponytail at the nape.
```

### P-25 `novice_helmet`

```text
Orthographic FRONT view of a single helmet, isolated, with no head inside: a simple dark steel round helmet in the kettle-hat style with a narrow brim all around, a riveted band at the base of the dome, a brown leather inner lining visible at the rim, and a brown leather chin strap hanging down. Worn, scratched, slightly rusty metal. Realistic medieval European style, physically based materials.
```

### P-26 `bandana`

```text
Orthographic FRONT view of a cotton bandana worn on a plain smooth light-gray mannequin head with no facial features and no hair: off-white cotton cloth with faded red swirl and diamond patterns and frayed edges, covering the top of the head, tied at the back of the head in a knot with two short hanging tails. Realistic cloth with natural folds.
```

### P-27 `ribbon`

```text
Orthographic FRONT view of a single large satin hair bow, isolated: a lavender-blue satin bow with two loops and two tails hanging down about 15 cm, with soft natural folds. Realistic fabric.
```

---

## 4. 武器、盾牌（正面，接 P-01；側面用 P-30；負面提示詞拿掉 weapon、shield）

### P-30 武器的側面（放正面圖當參考）

```text
Use the attached image as the reference. Show exactly the same object, with the same design, colors, materials and proportions, rotated 90 degrees into an orthographic SIDE view (edge-on), standing vertically with the tip pointing up.
```

### P-31 `initiate_dagger`

```text
Orthographic FRONT view of a single dagger, isolated, standing vertically with the blade pointing up: a straight double-edged iron blade with a central fuller and light wear marks, a simple straight iron crossguard with squared ends, a grip wrapped in dark brown leather, and a round disc pommel. Total length about 35 cm. Realistic medieval European style, physically based materials (worn iron, leather).
```

### P-32 `apprentice_iron_sword`

```text
Orthographic FRONT view of a single one-handed sword, isolated, standing vertically with the blade pointing up: a straight double-edged iron blade with a central fuller and light wear, a simple straight iron crossguard, a grip wrapped in brown leather, and a round disc pommel. Total length about 85 cm. Realistic medieval European style, physically based materials.
```

### P-33 `initiate_greatsword`

```text
Orthographic FRONT view of a single two-handed greatsword, isolated, standing vertically with the blade pointing up: a broad, heavy iron blade with a worn, slightly notched edge and a wide central fuller, a plain straight crossguard, a long two-handed grip wrapped in brown leather, and a large round disc pommel. Total length about 150 cm. Realistic medieval European style, physically based materials.
```

### P-34 `initiate_club`

```text
Orthographic FRONT view of a single club, isolated, standing vertically with the head up: a rough club carved from a gnarled oak branch, thicker at the head, studded with rusty iron spikes and nails, the handle wrapped with worn leather strips. Total length about 70 cm. Realistic, physically based materials.
```

### P-35 `apprentice_oak_wand`

```text
Orthographic FRONT view of a single one-handed wand, isolated, standing vertically: a gnarled, twisted oak branch with natural knots, with a rough pale quartz crystal lashed to the top with leather cords. Total length about 70 cm. Realistic, physically based materials.
```

### P-36 `cleric_holy_scepter`

```text
Orthographic FRONT view of a single ornate one-handed holy scepter, isolated, standing vertically: the head is a silver cross framed by a pair of silver angel wings with a round blue gemstone in the center; the shaft has a navy-blue leather grip, white enamel sections and gold bands, and ends in a pointed gold cap. Total length about 80 cm. Realistic, physically based materials (polished silver, gold, enamel, leather).
```

### P-37 `apprentice_buckler`（正面；背面用 P-37b；側面用 P-30）

```text
Orthographic FRONT view of a single small round buckler shield, isolated, facing the camera: made of vertical wooden planks, with a domed steel boss in the center and a riveted steel rim, light wear and scratches. Realistic medieval European style, physically based materials.
```

### P-37b 盾牌的背面（放正面圖當參考）

```text
Use the attached image as the reference. Show exactly the same shield from the BACK, orthographic: a padded dark leather lining and a single wooden grip handle across the center, with the steel rim visible around the edge.
```

---

## 5. 怪物（正面，接 P-01；其他視角用 P-02～P-04）

### P-41 果凍怪 `gelly`（不透明版本，給 Tripo 用）

```text
Orthographic FRONT view of an original small creature: a round jelly blob about 50 cm wide, shaped like a slightly squashed sphere with a flat bottom resting on the ground, a smooth glossy coral-pink surface, two small glossy black bead eyes, and a small puckered round mouth between them. Cute and friendly. Make it fully OPAQUE: a solid painted surface with no transparency, no visible inner core, no particles, no bubbles and no leaves inside.
```

### P-42 毛絨蟲 `fluffy_caterpillar`

```text
Orthographic FRONT view of an original creature: a chubby caterpillar about 80 cm long and 40 cm tall, with a large round head and five round body segments covered in short dense bright-green fur, a row of small pale-green cone-shaped spikes along the back, two big glossy black compound eyes, small mandibles with two tiny curved fangs, two thin antennae with round knob tips, and six pairs of short stubby legs with small claws. Cute but a little creepy. The fur is a dense short pelt, not long individual hairs. The antennae and the legs are clearly separated from the body.
```

### P-43 小樹精 `young_treant`

```text
Orthographic FRONT view of an original creature: a small walking tree-stump monster about 1.3 m tall. The body is a thick hollow trunk with a face: two round dark eye holes and a wide, open, jagged mouth hole. On top, a ring of drooping leafy branches hangs down like bangs, with a few small pink and lavender flowers. Two branch arms come out of the sides of the trunk and end in three or four claw-like twigs; the arms are held slightly away from the trunk. Four thick root legs spread out to the front and the sides, plus a few short roots. Ivy vines wrap around the trunk, with moss patches and small bracket fungi. Realistic bark. The eye holes are dark with no glow. The arms and the root legs do not touch the trunk or each other.
```

### P-44 可愛兔 `cute_bunny`（之後才用）

```text
Orthographic FRONT view of an original creature: a chubby round bunny standing upright on two short legs, about 60 cm tall, with cream and white fluffy fur and a white belly, long floppy ears hanging down to the sides with pink inner ears, big round red eyes, a small pink nose, a crown of green leaves with tiny white flowers on its head, a collar of small green leaves with a small golden bell, short arms held slightly away from the body, and a round white cotton tail. Realistic fluffy fur, cute.
```

---

## 6. 場景（接 P-01）

### 6.1 王都的地標（正面，其他視角用 P-02～P-04）

#### P-51 `kronenberg_main_gate`（方形雙塔，建議；照 `building-kronenberg_south_field.jpg`，`concept-art-update` 第 11 節第 16 項）

```text
Orthographic FRONT view of a single medieval city gatehouse, isolated, seen from outside the city: two square towers of light-gray limestone blocks with flat crenellated tops, joined by a central gatehouse block with a crenellated top and a carved stone shield crest above the gate; a tall round-arched gate passage about 5 m wide and 7 m high with heavy dark wooden double doors and iron fittings; arrow slits and small arched windows; long deep-blue banners hanging on both towers. Total height about 22 m, width about 26 m. Short stubs of the adjoining city wall on both sides. Realistic, physically based materials with weathering and a little moss at the base.
```

#### P-51b `kronenberg_main_gate`（雙圓塔尖頂，第 16 項選另一個選項時才用）

```text
Orthographic FRONT view of a single medieval city gatehouse, isolated, seen from outside the city: two round towers of light-gray limestone blocks with crenellated tops and dark blue-gray slate conical roofs, joined by a central gatehouse block with a crenellated top; a tall round-arched gate passage about 5 m wide and 7 m high with heavy dark wooden double doors and iron fittings; small arched windows and arrow slits. Total height about 22 m, width about 26 m. Short stubs of the adjoining city wall on both sides. Realistic, physically based materials with weathering and a little moss at the base.
```

#### P-52 `kronenberg_crescent_gate`

```text
Orthographic FRONT view of a single structure, isolated: a crescent-shaped (semicircular) inner wall of light-gray limestone about 12 m tall, with its convex side facing the viewer, and a square gate tower in the middle of the curve. The gate tower has a crenellated top and a round-arched gateway with closed wooden doors, and a long deep-blue royal banner with a simple white crown emblem hangs above the gate. Realistic, physically based materials with light weathering.
```

#### P-53 `kronenberg_cathedral`

```text
Orthographic FRONT view of the main facade of a single Gothic cathedral, isolated: twin bell towers flanking the facade, a large round rose window above three pointed-arch portals, a wide stone staircase in front, a tall slender central spire behind, a long nave with flying buttresses and tall pointed windows, light-gray limestone with dark slate roofs. About 48 m long and 60 m tall to the tip of the spire. Realistic, physically based materials.
```

#### P-54 `kronenberg_castle`（遠景）

```text
Orthographic FRONT view of a compact medieval royal castle, isolated, designed to be seen from a distance: a curtain wall with round towers topped by dark blue-gray slate conical roofs, a long great hall with a steep slate roof inside the walls, and a square keep, all in light-gray limestone. Simple, clear shapes. About 80 m wide.
```

#### P-55 `kronenberg_palace`（遠景）

```text
Orthographic FRONT view of a single royal palace building, isolated, designed to be seen from a distance: a large central dome of aged reddish-bronze copper on a drum with arched windows, four smaller domed corner turrets, and light-gray limestone walls with classical arched windows. About 40 m wide and 35 m tall. Simple, clear shapes.
```

### 6.2 王都的小地標和道具（3/4 視角，一張就好）

#### P-56 `kronenberg_memorial_column`

```text
Three-quarter view from slightly above of a single tall memorial column, isolated: a slender square stone pillar about 18 m tall standing on a stepped stone plinth, with simple carved bands and a small reddish-brown pointed cap on top. Light-gray limestone, weathered. Realistic, physically based materials.
```

#### P-57 `kronenberg_monument`

```text
Three-quarter view from slightly above of a single small town-square monument, isolated: a carved stone pedestal about 2 m tall carrying a bronze statue of a cloaked traveler raising a lantern, with green patina on the bronze. Total height about 4 m. Original design. Realistic, physically based materials.
```

#### P-57b `kronenberg_temple_statue`（草稿：神像的樣子還沒定，`{STATUE}` 換成你的描述）

正面，其他視角用 P-02～P-04；後面接 P-01。

```text
Orthographic FRONT view of a single statue on a pedestal, isolated: {STATUE}. The statue stands on a three-tier round pedestal of light-gray limestone with a carved original crest, about 4 m wide at the base; total height about 7 m. Weathered stone with light moss in the cracks. Original design. Realistic, physically based materials.
```

`{STATUE}` 的建議（原創）：`a white marble statue of a robed goddess with a pair of folded feathered wings on her back, holding a lantern in both hands in front of her chest, calm face looking slightly downward`

#### P-58 `market_stall`

```text
Three-quarter view from slightly above of a single wooden market stall, isolated: a sturdy oak frame with a front counter and a sloped roof of striped canvas in faded red and cream, with a few baskets and small crates on the counter. About 4 m wide, 3 m deep and 3 m tall. Realistic, physically based materials with wear.
```

#### P-59 `street_lamp`

```text
Three-quarter view of a single wrought-iron street lamp, isolated: a tall dark iron post with a decorative bracket holding a four-sided glass lantern with aged brass details. About 3.5 m tall. Realistic, physically based materials.
```

#### P-60 `stone_well`

```text
Three-quarter view from slightly above of a single round stone water well, isolated: mossy fieldstone walls about 1 m tall and 2 m wide, a small wooden shingle roof on two posts, a crank with a rope and a wooden bucket. Realistic, physically based materials.
```

### 6.3 南方草原的地標

2026-10-11 依新的草原地圖整段換掉（上一版的 P-61～P-75 作廢）。水井用 P-60。

#### P-61 `sea_bridge_span`（正面是「從側邊看得到拱」的那一面；背面用 P-03；左右用 P-02、P-04 看到的是橋面的兩端）

```text
Orthographic FRONT view of a single straight section of a large stone sea bridge, isolated, seen from the side so the arch is visible: one wide round arch on two massive square piers with pointed cutwaters, a flat roadway about 8 m wide with low crenellated stone parapets on both sides, about 20 m long and 12 m tall from the pier base to the parapet. Weathered light-gray limestone blocks, dark wet stains and barnacles near the base of the piers. The section is designed to repeat, so both ends are cut flat. Realistic, physically based materials.
```

#### P-62 `bridge_statue`

```text
Three-quarter view of a single small stone statue on a square pedestal, isolated: a hooded guardian figure holding a lantern in front of its chest, weathered light-gray limestone with lichen, about 2.5 m tall in total. Original design. Realistic, physically based materials.
```

#### P-63 `fishing_hut`（正面，其他視角用 P-02～P-04；要兩種就換掉 {VARIANT} 生成兩次）

```text
Orthographic FRONT view of a single small wooden fishing hut, isolated: walls of weathered gray-brown vertical planks on a low fieldstone base, a steep roof of dark wooden shingles, a small window with wooden shutters, a plank door, fishing nets and cork floats hanging on the wall, a few crates and a coiled rope by the door. {VARIANT}. About 6 m by 5 m. Realistic, physically based materials with salt weathering.
```

`{VARIANT}` 依序換成：
- a：`One story with a small lean-to shed on one side`
- b：`Two stories, the upper floor slightly overhanging, with an outside wooden staircase`

#### P-64 `rowboat`

```text
Three-quarter view from slightly above of a single small wooden rowboat, isolated: about 4 m long, overlapping weathered planks painted faded blue-green on the outside, a bare wood interior with two bench seats, a pair of oars resting inside, and a coiled rope at the bow. Realistic, physically based materials.
```

#### P-65 `sailboat`

```text
Three-quarter view of a single small wooden fishing sailboat, isolated, designed to be seen from a distance: about 8 m long, a dark wooden hull, one mast with a single off-white triangular sail, simple rigging. Simple, clear shapes. Realistic, physically based materials.
```

#### P-66 `net_drying_rack`

```text
Three-quarter view of a single wooden net drying rack, isolated: two pairs of crossed wooden poles about 2 m tall joined by a horizontal pole about 3 m long, with a brown fishing net draped over it and a few cork floats, a wooden basket on the ground. Realistic, physically based materials.
```

#### P-67 `training_dummy`

```text
Three-quarter view of a single combat training dummy, isolated: a thick wooden post about 1.8 m tall set in the ground, a horizontal wooden crossbar for arms, a body of straw bundled with rope and wrapped in torn burlap, a burlap sack head, sword cuts and patches on the burlap. Realistic, physically based materials with wear.
```

#### P-68 `weapon_rack`

```text
Three-quarter view of a single wooden weapon rack, isolated: an A-frame of dark oak about 2.5 m long and 1.5 m tall, holding six wooden practice swords upright and two round wooden practice shields leaning against one end. Realistic, physically based materials with wear.
```

#### P-69 `canvas_tent`

```text
Three-quarter view of a single canvas A-frame tent, isolated: about 3 m long and 2 m tall, stained beige canvas on wooden poles, guy ropes and wooden stakes, front flaps tied open. Realistic, physically based materials.
```

#### P-70 `training_ring_frame`

```text
Three-quarter view of a single wooden training frame, isolated: two sturdy wooden posts about 3 m tall joined by a crossbeam about 4 m long, with two iron rings and two leather sandbags hanging from chains on the crossbeam. Realistic, physically based materials with wear.
```

#### P-71 `campfire`

```text
Three-quarter view from above of a single campfire, isolated: a ring of fist-sized stones about 1.2 m wide with stacked split logs and ash in the center. No flames and no smoke (the fire is added in the game engine). Realistic, physically based materials.
```

#### P-72 `desert_menhir`

```text
Three-quarter view of a single tall standing stone, isolated: a weathered sandstone monolith about 6 m tall with a rounded leaning top, wind-carved horizontal grooves, warm ochre and tan colors, a few smaller stones and dry grass tufts at its base. Realistic, physically based materials.
```

#### P-73 `signpost`

```text
Three-quarter view of a single wooden crossroads signpost, isolated: a weathered wooden post about 2.2 m tall with three plank arrow signs pointing in different directions, the signs left blank with no text, a small iron cap on top, grass tufts at the base. Realistic, physically based materials.
```

---

## 7. 補充概念圖（放 `ConceptArt/`，不用接 P-01）

這些是給我看的「目標樣貌」，可以有標題和標籤，背景隨意。共通開頭：

### P-80 概念圖的共通開頭（後面接 P-81～P-100 其中一段）

```text
Concept art reference sheet for an original fantasy game. Realistic medieval European style with the look of a high-quality 3D render, physically based materials with wear and weathering, consistent morning daylight. Clean layout on a dark gray studio background with short English labels.
```

### P-81 王都的房屋模組

```text
Title: "KRONENBERG ARCHITECTURE KIT - HALF-TIMBERED HOUSES". Show four town house types, each in a front view and a side view: a two-story house, a three-story house, a three-story corner house, and a narrow four-story house. Dark oak timber framing, cream and ochre lime plaster, ground floors of light-gray stone, steep roofs of dark blue-gray slate and some of red-brown clay tiles, dormer windows, chimneys, wooden shutters, small balconies and flower boxes. Below, show the modular parts separately: wall panels, window types, door types, roof pieces and chimneys. Include a 1.7 m human silhouette for scale.
```

### P-82 城牆和圓塔的模組

```text
Title: "KRONENBERG WALL KIT". Show a straight city wall segment about 12 m tall with crenellations and a wall walk, a round tower with a dark blue-gray slate conical roof, a round tower with a flat crenellated top, a square gatehouse with a round-arched gate, and a lower outer wall about 10 m tall with a grassy strip between the two walls. Light-gray limestone blocks with moss at the base. Front and side views, with a 1.7 m human silhouette for scale.
```

### P-83 東南主城門（方形雙塔；第 16 項選雙圓塔尖頂的話，把 `Two square towers with flat crenellated tops` 換成 `Two round towers with dark blue-gray slate conical roofs`，拿掉 shield crest）

```text
Title: "KRONENBERG MAIN GATE". Turnaround of the city's main gate: front view from outside the city, back view from inside the city, and a side view. Two square towers with flat crenellated tops and a central arched gatehouse spanning a double wall, a carved stone shield crest above the gate, heavy wooden doors, long deep-blue banners. Include a 1.7 m human silhouette for scale.
```

### P-84 新月形城門和王室旗幟

```text
Title: "CRESCENT GATE AND ROYAL BANNER". Left: the crescent-shaped inner wall with its square gate tower, seen from the plaza in front and from above. Right: the royal banner design in front view: a long deep-blue cloth banner with gold trim and a simple white crown emblem (original design), plus a smaller pennant version.
```

### P-85 大教堂

```text
Title: "KRONENBERG CATHEDRAL". Front facade, side view and back view of a Gothic cathedral: twin bell towers, a large rose window, three pointed-arch portals with a wide staircase, a tall central spire, flying buttresses, tall pointed windows, light-gray limestone and dark slate roofs. Include a 1.7 m human silhouette for scale.
```

### P-86 城堡和宮殿

```text
Title: "CASTLE AND PALACE". The royal castle and the copper-domed palace as seen from the central plaza through the crescent gate: round towers with dark slate conical roofs, a long great hall, a large reddish-bronze copper dome with smaller domed turrets. One wide view plus small front views of each building.
```

### P-87 王都的小東西

```text
Title: "KRONENBERG STREET PROPS". A market stall with a striped canvas roof, a wrought-iron street lamp, a stone water well with a wooden roof, a wooden bench, oak barrels, wooden crates, a hand cart, stone flower planters, and a wooden notice board. Each object shown separately in a three-quarter view with approximate sizes.
```

### P-88 劍士訓練營地

```text
Title: "SWORDSMAN TRAINING CAMP". An open dirt clearing outside a city wall with about ten canvas A-frame tents, five straw training dummies on wooden posts, a wooden weapon rack with practice swords and shields, a wooden training frame with hanging rings and sandbags, two stone campfire rings and logs used as benches. Separate three-quarter views of each object, plus an overview of the whole camp from above at an angle.
```

### P-89 漁村和碼頭

```text
Title: "FISHING HAMLET AND PIER". Four or five small wooden fishing huts with shingle roofs on a low earthen terrace beside a sea bay, an L-shaped wooden pier on posts, fishing nets drying on racks, a small rowboat tied to the pier and two small sailboats in the bay. Separate views of a hut, the pier and the boats, plus an overview from above at an angle.
```

### P-90 跨海的大橋

```text
Title: "SEA BRIDGE". A long multi-arched stone bridge crossing the sea from a grassy shore toward a distant city: wide round arches on massive piers, a roadway about 8 m wide with low crenellated parapets, a small hooded guardian statue with a lantern at the near end. Side view, a view from the near end looking along the roadway, and a close-up of the statue, with a 1.7 m human silhouette for scale.
```

### P-91 沙漠的邊緣

```text
Title: "MEADOW TO DESERT EDGE". Green grassy terraces ending in low eroded earth cliffs that drop onto pale golden sand; a flat-topped sandstone mesa with steep sides, tall weathered sandstone standing stones, scattered rocks, dry grass tufts and rolling sand dunes in the distance. One wide view plus small views of the cliff edge, the mesa and a standing stone.
```

### P-92 海岸

```text
Title: "COAST AND BEACH". A sandy beach between a desert and a blue sea: a curved sand spit, low sandy cliffs, dark wet rocks and small rocky islets in the water, gentle waves with white foam along the shore. Morning light. One wide view plus a close-up of the waterline.
```

### P-93 草原的小東西

```text
Title: "MEADOW PROPS". A wooden crossroads signpost with three blank plank signs, a round fieldstone well with a small shingle roof and a bucket, logs used as benches, clusters of dry grass, a few broadleaf shrubs. Each object shown separately in a three-quarter view with approximate sizes.
```

### P-94 南門外的氣氛圖（只有選雙圓塔尖頂的城門才要，`concept-art-update` 第 11 節第 16 項）

```text
Environment concept painting, no text: early morning just outside the main gate of a walled medieval city. The gate has two round towers with dark slate conical roofs and a central arched gatehouse; blue banners hang on the wall. A dirt road leads south through rolling green meadows with wildflowers, scattered pine and broadleaf trees, light morning mist, the sun low in the east. Realistic, cinematic, wide 16:9 composition.
```

### P-95 頭飾

```text
Title: "HEADGEAR SET". Three headgear items, each in front, side, back and top views on a plain gray mannequin head: (1) a dark steel round kettle-hat helmet with a narrow brim, rivets, leather lining and chin strap; (2) an off-white cotton bandana with faded red swirl and diamond patterns, tied at the back with two hanging tails; (3) a large lavender-blue satin hair bow worn at the back of the head.
```

### P-96 髮型

```text
Title: "HAIRSTYLE SET". Four hairstyles, each in front, side and back views on a plain gray mannequin head with no facial features: (1) shoulder-length hair with side-swept bangs in two short low twin tails; (2) very long straight hair to the waist with blunt bangs; (3) long hair with side-swept bangs and face-framing strands in a long low ponytail; (4) a short jaw-length bob with bangs and a small low ponytail at the nape. Neutral light brown hair, realistic game hair strands.
```

### P-97 共用頭部的臉

```text
Title: "BASE HEAD REFERENCE". Front view and side profile view of the same original young woman, {FACE_DESCRIPTION}, head and neck only, neutral relaxed expression, eyes open looking forward, mouth closed, natural skin, no makeup, no jewelry, all hair hidden under a tight light-gray cap so the forehead, ears and the hairline area are visible. Soft even lighting, plain medium-gray background, orthographic views side by side.
```

`{FACE_DESCRIPTION}` 你決定（四張女性概念圖的臉不一樣），例如：
- `early twenties, soft youthful features, East Asian`
- `early twenties, soft youthful features, mixed East Asian and European`

### P-98 臉部表情

```text
Title: "FACIAL EXPRESSION SHEET". The same base head (attached reference) in a 5 x 2 grid of front views with these expressions: gentle smile while waving, polite neutral bow, happy smile while clapping, open-mouth cheer, laughing with eyes squinted, thinking with a slight frown, shaking head no with a flat mouth, nodding yes with a small smile, angry with lowered brows and squinted eyes, crying with the mouth corners turned down. Same lighting and framing in every cell, a short English label under each.
```

### P-99 特效

```text
Title: "SKILL EFFECTS CONCEPT". Original magical effects for a realistic fantasy game, each shown on a dark background next to a 1.7 m human silhouette: a circular casting rune circle on the ground made of thin glowing lines and abstract geometric glyphs (not real letters); a level-up pillar of golden light rising with sparkles; a swirling blue teleport portal on the ground; four hit spark types (slash, pierce, blunt, punch); a critical hit burst; soft green-white healing sparkles.
```

### P-100 HUD

```text
Title: "HUD MOCKUP". A 1920x1080 game screenshot mockup of a heads-up display over a realistic medieval town scene: a character frame at the top left with name, base level, job level, HP and SP bars; a target frame at the top center; a minimap at the top right; status effect icons under the character frame; a cast bar above the center bottom; a row of nine skill slots at the bottom center with base and job experience bars below it; a chat and system message box at the bottom left. Semi-transparent dark panels with thin light borders and clean sans-serif text. Use placeholder numbers only.
```

---

### P-101 大教堂廣場的神像

```text
Title: "TEMPLE STATUE". The statue in the center of the cathedral square: {STATUE}, on a three-tier round limestone pedestal with a carved original crest, total height about 7 m. Front, side and back views, plus one view of the statue in front of a Gothic cathedral facade in morning light. Include a 1.7 m human silhouette for scale.
```

`{STATUE}` 同 P-57b。

## 8. 2D 遊戲素材

### P-111 游標（6 個，換掉 {SHAPE}）

```text
A single game mouse cursor icon, 1024x1024, {SHAPE}, polished silver metal with a thin dark outline and a subtle drop shadow, the tip pointing to the top-left corner, centered, on a pure flat #00FF00 green background. No text.
```

`{SHAPE}` 依序換成：
- `cursor_normal`：`a classic pointer arrow`
- `cursor_attack`：`a small sword pointing diagonally to the top-left`
- `cursor_pick`：`an open hand reaching to grab, fingers toward the top-left`
- `cursor_talk`：`a small speech bubble with three dots inside`
- `cursor_target`：`a circular crosshair reticle with four ticks` （這個不用指向左上角，準星中心就是點）
- `cursor_ground`：`a dashed circle with a small center dot` （同上）

### P-112 暴擊的爆炸形圖案

```text
A single jagged comic-style starburst explosion shape with twelve uneven spikes, solid bright yellow-orange fill with a dark red outline, flat graphic style, centered, on a pure flat black background, 1024x1024. No text.
```

### P-113 技能圖示（26 個）

共通開頭（每次都一樣，後面換 `{PALETTE}` 和 `{SYMBOL}`）：

```text
A square game skill icon, 1024x1024, painted realistic fantasy style with a strong, readable silhouette that still reads at 32 px, one centered symbol: {SYMBOL}. Color palette: {PALETTE}. Dark background with a subtle radial vignette and a thin metallic beveled border. No text, no letters, no numbers.
```

`{PALETTE}`（依職業）：
- 初心者：`warm brown, cream and soft gold`
- 劍士：`crimson, orange and steel gray`
- 盜賊：`dark green, violet and charcoal`
- 服事：`white, gold and sky blue`

| ID | 職業 | `{SYMBOL}` |
|---|---|---|
| `basic_skill` | 初心者 | `a worn leather backpack with a rolled map and a small compass` |
| `sword_mastery` | 劍士 | `two crossed one-handed swords with a steel glint` |
| `two_handed_sword_mastery` | 劍士 | `one large greatsword standing upright with a glint on the blade` |
| `increase_hp_recovery` | 劍士 | `a glowing red heart with a rising green spiral` |
| `bash` | 劍士 | `a sword striking downward with a bright orange impact flash` |
| `provoke` | 劍士 | `a fierce shouting warrior face in silhouette with red sound waves` |
| `magnum_break` | 劍士 | `a sword driven into the ground releasing a ring of fiery explosion` |
| `endure` | 劍士 | `a warrior silhouette standing firm inside a golden protective aura` |
| `double_attack` | 盜賊 | `two quick dagger slashes forming a bright X` |
| `improve_dodge` | 盜賊 | `a figure leaning aside with a blurred afterimage` |
| `steal` | 盜賊 | `a gloved hand snatching a small coin pouch` |
| `hiding` | 盜賊 | `a hooded figure dissolving into dark shadows` |
| `envenom` | 盜賊 | `a dagger blade dripping green poison` |
| `detoxify` | 盜賊 | `a clear water droplet washing away green poison` |
| `divine_protection` | 服事 | `a glowing white-gold shield with small feathered wings` |
| `demon_bane` | 服事 | `a beam of holy light striking a dark horned shadow` |
| `ruwach` | 服事 | `a glowing blue orb of light with small orbiting sparks` |
| `pneuma` | 服事 | `a translucent pale-blue dome barrier deflecting arrows` |
| `teleport` | 服事 | `a figure fading into swirling blue particles` |
| `heal` | 服事 | `an open hand releasing soft green-white light and sparkles` |
| `increase_agi` | 服事 | `a winged boot with green speed lines` |
| `decrease_agi` | 服事 | `a heavy boot bound by a chain in a purple haze` |
| `signum_crucis` | 服事 | `a cross of golden light glowing over cracked dark ground` |
| `angelus` | 服事 | `white angel feathers forming a protective circle` |
| `blessing` | 服事 | `radiant golden light rays from above with falling feathers` |
| `cure` | 服事 | `a white flower dispelling a dark mist` |

### P-114 狀態圖示（11 個）

```text
A round game status effect icon, 1024x1024, painted realistic fantasy style, one centered symbol that still reads at 24 px: {SYMBOL}. A thin circular border colored {BORDER}. Dark background inside the circle, pure flat #00FF00 green outside the circle. No text, no letters, no numbers.
```

`{BORDER}`：增益用 `gold`，減益用 `purple`。

| ID | 增益／減益 | `{SYMBOL}` |
|---|---|---|
| `provoke` | 增益（ATK 上升）＋減益（DEF 下降），用 purple | `an angry red face with an upward arrow and a cracked shield` |
| `endure` | 增益 | `a golden shield aura around a standing figure` |
| `increase_agi` | 增益 | `a green winged boot` |
| `decrease_agi` | 減益 | `a boot bound by a chain` |
| `blessing` | 增益 | `golden light rays with a feather` |
| `angelus` | 增益 | `a circle of white feathers` |
| `signum_crucis` | 減益（給敵人） | `a golden cross with a downward arrow` |
| `hiding` | 增益 | `a hooded figure half hidden in shadow` |
| `ruwach` | 增益 | `a small glowing blue orb` |
| `poison` | 減益 | `a bubbling green droplet` |
| `stun` | 減益 | `small yellow stars circling` |

### P-115 詠唱魔法陣

```text
A perfectly symmetrical magic casting circle seen straight from above, 2048x2048: concentric rings, thin glowing white lines, an eight-pointed star pattern and abstract geometric glyphs (not letters or symbols from any real script, religion or existing game), crisp clean lines, centered, on a pure flat black background. No text.
```

### P-116 表情圖示（10 個）

```text
A single emote icon for a game, 1024x1024: a white speech bubble with a dark outline containing {SYMBOL}, bold simple flat colors, readable at 32 px, centered, on a pure flat #00FF00 green background. No text, no letters.
```

| ID | `{SYMBOL}` |
|---|---|
| `emote_wave` | `a waving hand` |
| `emote_bow` | `a small figure bowing politely` |
| `emote_clap` | `two clapping hands with motion lines` |
| `emote_cheer` | `a raised fist with sparkles` |
| `emote_laugh` | `a laughing face with tears of joy` |
| `emote_think` | `three dots inside a small thought cloud` |
| `emote_no` | `a bold red X` |
| `emote_yes` | `a bold green check mark` |
| `emote_angry` | `a red anger symbol with a puff of steam` |
| `emote_cry` | `a crying face with big tear drops` |

### P-117 物品圖示（只有在不用 3D 模型渲染時才用）

```text
A single game item icon, 1024x1024, realistic painted style: {ITEM}, shown at a slight diagonal angle, soft studio lighting with a gentle rim light and a subtle dark outline, centered with a small margin, on a pure flat white background. No text, no frame.
```

`{ITEM}` 用第 4、3 節裡物品的描述，例如 `a simple iron dagger with a dark brown leather-wrapped grip and a round disc pommel`。

### P-118 職業圖示（4 個）

```text
A round emblem icon for a character class, 1024x1024, painted realistic fantasy style with a metallic rim: {SYMBOL}. Readable at 32 px. Dark background inside the emblem, pure flat #00FF00 green outside. No text.
```

- 初心者：`a worn leather backpack`
- 劍士：`a sword crossed over a round shield`
- 盜賊：`two crossed daggers`
- 服事：`a holy book with a small cross on the cover`

### P-119 屬性圖示（10 個，之後才用）

```text
A small round elemental icon, 1024x1024, flat painted style with a soft glow and a dark outline, readable at 24 px: {SYMBOL}. Pure flat #00FF00 green background. No text.
```

| ID | `{SYMBOL}` |
|---|---|
| `neutral` | `a plain gray circle` |
| `water` | `a blue water droplet` |
| `earth` | `a brown rock with a green leaf` |
| `fire` | `an orange flame` |
| `wind` | `a green wind swirl` |
| `poison` | `a purple bubbling droplet` |
| `holy` | `a golden radiant star` |
| `dark` | `a black and purple crescent moon` |
| `ghost` | `a pale blue wisp` |
| `undead` | `a cracked gray tombstone` |

### P-120 載入畫面（2 張）

```text
Wide cinematic landscape painting for a game loading screen, 16:9, 2560x1440, realistic fantasy medieval European style, morning light: {SCENE}. Keep the lower third slightly darker and calm, with no important details there (the map name and the progress bar go there). No text, no logo, no characters close to the camera.
```

`{SCENE}`：
- 王都：`an aerial view of a walled city on a rocky island in a calm lake: light-gray limestone walls with round towers and dark slate conical roofs, a twin-towered main gate, a Gothic cathedral with a tall spire on the west side, a castle and a copper-domed palace on the north side, half-timbered houses with dark roofs, thin morning mist and sunlight from the east`
- 南方草原：`rolling green meadows outside the square twin-towered gate of a walled city, dirt paths branching between groves of broadleaf trees, a camp of canvas tents and training dummies near the wall, dark pine forests on rocky terraces to the west, a blue sea bay with a small fishing pier and a long multi-arched stone bridge crossing the sea to the east, pale golden desert with standing stones in the distance, light morning mist`

### P-121 標題畫面（遊戲名稱決定後才用）

```text
A wide cinematic key art for the title screen of an original fantasy game, 16:9, 2560x1440: four young women adventurers (a novice with a backpack, a swordswoman in a mustard cape, a rogue in an ochre jacket, an acolyte in a cream capelet) standing on a hill at sunrise looking toward a walled city on a lake with a copper-domed palace and a Gothic cathedral. Realistic painted style. Leave clear space at the top center for a logo. No text.
```

標誌：

```text
A game title logo that reads "{GAME_TITLE}", ornate medieval fantasy lettering in polished silver and gold with a deep blue enamel accent and a small crown motif, centered, on a pure flat black background, 2048x1024.
```

---

## 9. Tripo 的文字轉 3D（沒有圖時）

04 第 14.3 節的範本照樣可以用：

```text
{OBJECT}, realistic medieval European fantasy style, game-ready 3D asset, PBR materials, worn and weathered, {MATERIALS}, about {SIZE} tall, single isolated object, no base, no text
```

例子（04 第 14.3 節的表，加上新地圖的東西）：

| 物件 | `{OBJECT}` | `{MATERIALS}` |
|---|---|---|
| 木箱 | `rough wooden crate with rope handles` | `weathered pine planks, iron nails` |
| 木桶 | `oak barrel with iron hoops` | `dark oak staves, rusty iron hoops` |
| 麻袋 | `burlap grain sack, tied at the top` | `coarse beige burlap` |
| 長椅 | `simple wooden bench` | `weathered oak` |
| 拴馬柱 | `wooden hitching post with an iron ring` | `gray weathered wood, dark iron` |
| 告示板 | `wooden notice board with a small roof and blank pinned papers` | `oak, blank parchment` |
| 手推車 | `wooden hand cart with two spoked wheels` | `worn oak, iron rims` |
