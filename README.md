# e04 OBJ Importer for SketchUp

**Version 1.0.0** | Author: undearstand

---

[中文說明](#中文說明) | [English](#english)

---

## 中文說明

### 簡介

e04 OBJ Importer 是一個 SketchUp Extension，用於匯入 `.obj` 3D 模型檔案，支援完整的 **UV 貼圖座標**與 **MTL 材質**資訊。

### 功能特色

- ✅ **完整 OBJ 格式支援** — 頂點、面（三角/四邊/N-gon）、法線、UV 座標
- ✅ **MTL 材質匯入** — 漫射色（Kd）、透明度（d/Tr）、貼圖（map_Kd）
- ✅ **UV 貼圖映射** — 透過 `position_material` 精確設定每個面的 UV
- ✅ **軸向轉換** — 支援 Y-up（Maya/C4D/Unity）與 Z-up（Blender/3ds Max）切換
- ✅ **單位選擇** — 支援 mm / cm / m / inch / ft 五種來源單位
- ✅ **群組分組** — 依據 OBJ 中的 `g`/`o` 標記自動建立 SketchUp Group
- ✅ **匯入選項面板** — 深色主題 HtmlDialog UI，匯入前可調整設定

### 安裝方式

> ⚠️ **安裝注意事項 (Installation Note)**
> 本外掛尚未經過 SketchUp 官方數位簽署 (Unsigned)。安裝後若無法載入，請前往 SketchUp 的 `Extensions` > `Extension Manager`，點擊右上角的齒輪圖示 (Settings)，將 `Loading Policy` (載入原則) 更改為 `Unrestricted` (無限制) 或 `Approve Unidentified` (核准未識別的擴充程式)，然後重新啟動 SketchUp。

#### 方法一：直接複製（開發用）

將以下檔案複製到 SketchUp Plugins 資料夾：

```
%AppData%\SketchUp\SketchUp 2026\SketchUp\Plugins\
```

檔案結構：

```
Plugins/
├── e04_obj_importer.rb
└── e04_obj_importer/
    ├── main.rb
    ├── obj_parser.rb
    ├── mtl_parser.rb
    ├── importer.rb
    └── options_dialog.rb
```

#### 方法二：安裝 .rbz（發布用）

1. 將 `e04_obj_importer.rb` 和 `e04_obj_importer/` 資料夾壓縮為 `.zip`
2. 將副檔名改為 `.rbz`
3. 在 SketchUp 中：`Extensions` > `Extension Manager` > `Install Extension`
4. 選擇 `.rbz` 檔案進行安裝

### 使用方式

1. 開啟 SketchUp
2. 前往 `Extensions` 選單 > `e04 OBJ Importer`
3. 選擇要匯入的 `.obj` 檔案
4. 在匯入選項面板中設定：
   - **Up Axis（上方軸）**：依來源軟體選擇 Y-up 或 Z-up
   - **Source Unit（來源單位）**：選擇 OBJ 檔案的座標單位
5. 點選 **Import** 開始匯入

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
- 超大模型（100 萬面以上）可能匯入較慢

### Debug 技巧

在 SketchUp 中開啟 `Window` > `Ruby Console` 可以看到匯入過程的詳細日誌。
如需重新載入修改後的程式碼而不重啟 SketchUp：

```ruby
load 'e04_obj_importer/main.rb'
```

---

## English

### Overview

e04 OBJ Importer is a SketchUp Extension that imports `.obj` 3D model files with full support for **UV texture coordinates** and **MTL material** data.

### Features

- ✅ **Full OBJ format support** — Vertices, faces (tri/quad/N-gon), normals, UVs
- ✅ **MTL material import** — Diffuse color (Kd), transparency (d/Tr), textures (map_Kd)
- ✅ **UV texture mapping** — Precise per-face UV via `position_material`
- ✅ **Axis conversion** — Y-up (Maya/C4D/Unity) ↔ Z-up (Blender/3ds Max)
- ✅ **Unit selection** — mm / cm / m / inch / ft source units
- ✅ **Group organization** — Auto-creates SketchUp Groups from OBJ `g`/`o` tags
- ✅ **Import options panel** — Dark-themed HtmlDialog UI for pre-import settings

### Installation

> ⚠️ **Installation Note**
> This extension is unsigned. If it fails to load after installation, please go to SketchUp's `Extensions` > `Extension Manager`, click the gear icon (Settings) in the top right corner, and change the `Loading Policy` to either `Unrestricted` or `Approve Unidentified`. Then restart SketchUp.

#### Option 1: Direct Copy (Development)

Copy the files to the SketchUp Plugins folder:

```
%AppData%\SketchUp\SketchUp 2026\SketchUp\Plugins\
```

File structure:

```
Plugins/
├── e04_obj_importer.rb
└── e04_obj_importer/
    ├── main.rb
    ├── obj_parser.rb
    ├── mtl_parser.rb
    ├── importer.rb
    └── options_dialog.rb
```

#### Option 2: Install .rbz (Distribution)

1. Compress `e04_obj_importer.rb` and `e04_obj_importer/` folder into a `.zip`
2. Rename extension to `.rbz`
3. In SketchUp: `Extensions` > `Extension Manager` > `Install Extension`
4. Select the `.rbz` file

### Usage

1. Open SketchUp
2. Go to `Extensions` menu > `e04 OBJ Importer`
3. Select the `.obj` file to import
4. Configure import options:
   - **Up Axis**: Y-up or Z-up depending on source software
   - **Source Unit**: Coordinate unit used in the OBJ file
5. Click **Import**

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
- Very large models (1M+ faces) may import slowly

### Debugging

Open `Window` > `Ruby Console` in SketchUp to view detailed import logs.
To reload modified code without restarting SketchUp:

```ruby
load 'e04_obj_importer/main.rb'
```

---

## License

MIT License

Copyright (c) 2026 undearstand
