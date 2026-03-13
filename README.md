# mumi OBJ Importer for SketchUp

**Version 1.2.0** | Author: undearstand

---

[中文說明](#中文說明) | [English](#english)

---

## 中文說明

### 簡介

mumi OBJ Importer 是一個 SketchUp Extension，用於匯入 `.obj` 3D 模型檔案，支援完整的 **UV 貼圖座標**與 **MTL 材質**資訊。
本擴充功能採用 `entities.add_face` 逐面建立方式，能精確控制每一個面的材質、UV 映射與邊線屬性，適合需要處理**柔邊**與**單物件多材質**的使用情境。

### 功能特色

- ✅ **完整 OBJ 格式支援** — 頂點、面（三角/四邊/N-gon）、法線、UV 座標
- ✅ **MTL 材質匯入** — 漫射色（Kd）、透明度（d/Tr）、貼圖（map_Kd）
- ✅ **UV 貼圖映射** — 透過 `position_material` 精確設定每個面的 UV
- ✅ **軸向轉換** — 支援 Y-up（Maya/C4D/Unity）與 Z-up（Blender/3ds Max）切換
- ✅ **單位選擇** — 支援 mm / cm / m / inch / ft 五種來源單位
- ✅ **群組分組** — 依據 OBJ 中的 `g`/`o` 標記自動建立 SketchUp Group
- ✅ **自動柔化邊線** — 相鄰面夾角 ≤ 設定閾值的邊線自動柔化隱藏，讓平面與曲面看起來乾淨平滑
- ✅ **非共面多邊形自動三角化** — 自動檢測四邊形以上的面是否共面，非共面的面會自動拆分為三角形，避免匯入後產生破面
- ✅ **匯入選項面板** — 簡潔的淺色主題 HtmlDialog UI，匯入前可調整所有設定

### 安裝方式

> ⚠️ **安裝注意事項**
> 本外掛尚未經過 SketchUp 官方數位簽署 (Unsigned)。安裝後若無法載入，請前往 SketchUp 的 `Extensions` > `Extension Manager`，點擊右上角的齒輪圖示 (Settings)，將 `Loading Policy` (載入原則) 更改為 `Unrestricted` (無限制) 或 `Approve Unidentified` (核准未識別的擴充程式)，然後重新啟動 SketchUp。

#### 方法一：直接複製（開發用）

將以下檔案複製到 SketchUp Plugins 資料夾：

- **Windows**: `%AppData%\SketchUp\SketchUp 2026\SketchUp\Plugins\`
- **Mac**: `~/Library/Application Support/SketchUp 2026/SketchUp/Plugins/`

檔案結構：

```
Plugins/
├── mumi_obj_importer.rb          # Extension 載入檔
└── mumi_obj_importer/
    ├── main.rb                   # 主程式流程
    ├── obj_parser.rb             # OBJ 檔案解析器
    ├── mtl_parser.rb             # MTL 材質解析器
    ├── importer.rb               # 模型匯入器（含柔邊與三角化邏輯）
    ├── options_dialog.rb         # 匯入選項 UI 面板
    └── README.md                 # 說明文件
```

#### 方法二：安裝 .rbz（發布用）

1. 將 `mumi_obj_importer.rb` 和 `mumi_obj_importer/` 資料夾壓縮為 `.zip`
2. 將副檔名改為 `.rbz`
3. 在 SketchUp 中：`Extensions` > `Extension Manager` > `Install Extension`
4. 選擇 `.rbz` 檔案進行安裝

### 使用方式

1. 開啟 SketchUp
2. 前往 `Extensions` 選單 > `mumi OBJ Importer`
3. 選擇要匯入的 `.obj` 檔案
4. 在匯入選項面板中設定：
   - **Up Axis（上方軸）**：依來源軟體選擇 Y-up 或 Z-up
   - **Source Unit（來源單位）**：選擇 OBJ 檔案的座標單位
   - **Auto Soften Edges（自動柔化邊線）**：勾選後啟用自動柔化功能
   - **Angle Threshold（角度閾值）**：設定柔化邊線的角度閾值（預設 20°），相鄰面夾角 ≤ 此值的邊線會被柔化隱藏
5. 點選 **Import** 開始匯入

### 匯入選項說明

| 選項 | 預設值 | 說明 |
|------|--------|------|
| Up Axis 上方軸 | Y-up | 選擇來源軟體使用的上方軸向。Y-up 適用於 Maya、Cinema 4D、Unity；Z-up 適用於 Blender、3ds Max、SketchUp |
| Source Unit 來源單位 | cm | OBJ 檔案中的座標數值代表的單位 |
| Auto Soften Edges 自動柔化邊線 | ✅ 開啟 | 啟用後，匯入時自動將共面或近似共面的邊線設為柔化（soft + smooth），隱藏三角面之間不必要的邊線 |
| Angle Threshold 角度閾值 | 20° | 相鄰面夾角 ≤ 閾值的邊線會被柔化隱藏，值越大越平滑。設為 0° 時只柔化完全共面的邊線 |

### 自動三角化

匯入時會自動檢測每個四邊形以上的面：

- **共面（Coplanar）** → 直接以原始多邊形建立面（保持乾淨）
- **非共面（Non-coplanar）** → 自動拆分為三角形後再建立（避免破面）

判定方式：用前 3 個頂點定義平面，檢查其餘頂點到該平面的距離是否超過容差值（0.001 英吋）。搭配自動柔化功能，三角化產生的額外邊線也會被自動隱藏，視覺上看不出差異。

### 來源軟體對照表

| 來源軟體 | Up Axis | 建議單位 |
|---------|---------|---------|
| Cinema 4D | Y-up | cm |
| Maya | Y-up | cm |
| Unity | Y-up | m |
| Blender | Z-up | m |
| 3ds Max | Z-up | cm / inch |

### 相容性

| SketchUp 版本 | 相容性 | 說明 |
|--------------|--------|------|
| 2026 | ✅ 完整支援 | 主要開發與測試版本 |
| 2021–2025 | ✅ 應可正常運作 | 使用的 API 方法在這些版本中均存在 |
| 2017–2020 | ⚠️ 可能可用 | HtmlDialog 於 2017 版引入，基本功能應可運作 |
| 2016 及更早 | ❌ 不支援 | 缺少 HtmlDialog，需改用 WebDialog |

> **說明**：本 Extension 使用的核心 API（`add_face`、`position_material`、`HtmlDialog`）
> 在 SketchUp 2017 以後的版本中都是穩定存在的。主要的相容性限制來自 Ruby 版本差異——
> SketchUp 2021+ 使用 Ruby 2.7，2024+ 使用 Ruby 3.x。本 Extension 的程式碼語法簡潔，
> 未使用任何版本特定的 Ruby 語法，因此向下相容性應該良好。

### 已知限制

- 不支援 PBR 材質（bump map、metallic 等）—— SketchUp 本身不支援
- 不支援 NURBS 曲面 —— OBJ 中的 `curv`/`surf` 指令會被忽略
- 超大模型（100 萬面以上）可能匯入較慢（因使用 `add_face` 逐面匯入）

### Debug 技巧

在 SketchUp 中開啟 `Window` > `Ruby Console` 可以看到匯入過程的詳細日誌，包含：
- 頂點、面、UV 座標數量
- 材質載入狀態與貼圖路徑
- 柔化的邊線數量與使用的角度閾值
- 匯入失敗的面資訊（前 20 筆）

如需重新載入修改後的程式碼而不重啟 SketchUp：

```ruby
load 'mumi_obj_importer/main.rb'
```

---

## English

### Overview

mumi OBJ Importer is a SketchUp Extension that imports `.obj` 3D model files with full support for **UV texture coordinates** and **MTL material** data.
This extension uses the `entities.add_face` method to build faces individually, enabling precise control over materials, UV mapping, and edge properties per face — ideal for workflows that require **edge softening** and **multi-material objects**.

### Features

- ✅ **Full OBJ format support** — Vertices, faces (tri/quad/N-gon), normals, UVs
- ✅ **MTL material import** — Diffuse color (Kd), transparency (d/Tr), textures (map_Kd)
- ✅ **UV texture mapping** — Precise per-face UV via `position_material`
- ✅ **Axis conversion** — Y-up (Maya/C4D/Unity) ↔ Z-up (Blender/3ds Max)
- ✅ **Unit selection** — mm / cm / m / inch / ft source units
- ✅ **Group organization** — Auto-creates SketchUp Groups from OBJ `g`/`o` tags
- ✅ **Auto Soften Edges** — Automatically softens and hides edges between adjacent faces whose angle is ≤ the set threshold, resulting in clean, smooth surfaces
- ✅ **Non-coplanar face triangulation** — Automatically detects quads and N-gons with non-coplanar vertices and splits them into triangles to prevent broken geometry
- ✅ **Import options panel** — Clean, light-themed HtmlDialog UI for configuring all import settings

### Installation

> ⚠️ **Installation Note**
> This extension is unsigned. If it fails to load after installation, please go to SketchUp's `Extensions` > `Extension Manager`, click the gear icon (Settings) in the top right corner, and change the `Loading Policy` to either `Unrestricted` or `Approve Unidentified`. Then restart SketchUp.

#### Option 1: Direct Copy (Development)

Copy the files to the SketchUp Plugins folder:

- **Windows**: `%AppData%\SketchUp\SketchUp 2026\SketchUp\Plugins\`
- **Mac**: `~/Library/Application Support/SketchUp 2026/SketchUp/Plugins/`

File structure:

```
Plugins/
├── mumi_obj_importer.rb          # Extension loader
└── mumi_obj_importer/
    ├── main.rb                   # Main workflow
    ├── obj_parser.rb             # OBJ file parser
    ├── mtl_parser.rb             # MTL material parser
    ├── importer.rb               # Model importer (with edge softening & triangulation)
    ├── options_dialog.rb         # Import options UI panel
    └── README.md                 # Documentation
```

#### Option 2: Install .rbz (Distribution)

1. Compress `mumi_obj_importer.rb` and `mumi_obj_importer/` folder into a `.zip`
2. Rename extension to `.rbz`
3. In SketchUp: `Extensions` > `Extension Manager` > `Install Extension`
4. Select the `.rbz` file

### Usage

1. Open SketchUp
2. Go to `Extensions` menu > `mumi OBJ Importer`
3. Select the `.obj` file to import
4. Configure import options:
   - **Up Axis**: Y-up or Z-up depending on source software
   - **Source Unit**: Coordinate unit used in the OBJ file
   - **Auto Soften Edges**: Check to enable automatic edge softening
   - **Angle Threshold**: Set the softening angle threshold (default 20°); edges between adjacent faces with an angle ≤ this value will be softened and hidden
5. Click **Import**

### Import Options Reference

| Option | Default | Description |
|--------|---------|-------------|
| Up Axis | Y-up | Select the up-axis used by the source software. Y-up for Maya, Cinema 4D, Unity; Z-up for Blender, 3ds Max, SketchUp |
| Source Unit | cm | The unit represented by the coordinate values in the OBJ file |
| Auto Soften Edges | ✅ Enabled | When enabled, automatically sets edges between coplanar or near-coplanar faces to soft + smooth, hiding unnecessary edges between triangulated meshes |
| Angle Threshold | 20° | Edges between adjacent faces with an angle ≤ threshold will be softened and hidden. Higher values result in smoother surfaces. Set to 0° to only soften perfectly coplanar edges |

### Automatic Triangulation

During import, every quad and N-gon face is automatically checked for coplanarity:

- **Coplanar** → Created as the original polygon (keeps geometry clean)
- **Non-coplanar** → Automatically split into triangles via fan triangulation (prevents broken faces)

Detection method: A plane is defined by the first 3 vertices, then the distance of each remaining vertex to this plane is measured. If any distance exceeds the tolerance (0.001 inches), the face is considered non-coplanar and will be triangulated. Combined with Auto Soften Edges, the extra edges from triangulation are automatically hidden, so there is no visible difference.

### Source Software Reference

| Software | Up Axis | Recommended Unit |
|----------|---------|-----------------|
| Cinema 4D | Y-up | cm |
| Maya | Y-up | cm |
| Unity | Y-up | m |
| Blender | Z-up | m |
| 3ds Max | Z-up | cm / inch |

### Compatibility

| SketchUp Version | Status | Notes |
|-----------------|--------|-------|
| 2026 | ✅ Fully supported | Primary development & testing version |
| 2021–2025 | ✅ Should work | All API methods used are available |
| 2017–2020 | ⚠️ Likely works | HtmlDialog introduced in 2017 |
| 2016 and earlier | ❌ Not supported | Requires WebDialog (not implemented) |

> **Note**: The core APIs used (`add_face`, `position_material`, `HtmlDialog`) have been
> stable since SketchUp 2017. The main compatibility concern is Ruby version differences —
> SketchUp 2021+ uses Ruby 2.7, 2024+ uses Ruby 3.x. This extension uses simple, clean
> Ruby syntax with no version-specific features, so backward compatibility should be good.

### Known Limitations

- No PBR material support (bump maps, metallic, etc.) — SketchUp limitation
- No NURBS surface support — OBJ `curv`/`surf` commands are ignored
- Very large models (1M+ faces) may import slowly (due to per-face `add_face` approach)

### Debugging

Open `Window` > `Ruby Console` in SketchUp to view detailed import logs, including:
- Vertex, face, and UV coordinate counts
- Material loading status and texture paths
- Number of softened edges and the angle threshold used
- Skipped face details (first 20 entries)

To reload modified code without restarting SketchUp:

```ruby
load 'mumi_obj_importer/main.rb'
```

---

## Changelog

### v1.2.0 (2026-03-12)
- ✨ Auto-triangulation for non-coplanar quads/N-gons — prevents broken faces on import
- ♻️ Refactored face creation into reusable `create_face` method

### v1.1.0 (2026-03-10)
- ✨ Auto Soften Edges — softens/smooths edges between coplanar faces with configurable angle threshold
- 🎨 Restyled import options dialog from dark to light theme to match SketchUp's default UI
- 🔧 New UI controls: checkbox for soften toggle, number input for angle threshold

### v1.0.0 (2026-03-07)
- 🎉 Initial release
- OBJ file import with UV texture coordinates and MTL material support
- Axis conversion (Y-up / Z-up) and unit selection
- Group organization from OBJ `g`/`o` tags
- HtmlDialog import options panel

---

## License

MIT License

Copyright (c) 2026 undearstand
