# =============================================================================
# mumi OBJ Importer - Import Options Dialog
# HtmlDialog UI for import settings
# =============================================================================

module MUMI_ObjImporter
  module OptionsDialog

    # 單位轉英吋的換算表
    UNIT_SCALES = {
      'mm'    => 0.0393701,    # 1mm = 0.0393701 inch
      'cm'    => 0.393701,     # 1cm = 0.393701 inch
      'm'     => 39.3701,      # 1m  = 39.3701 inch
      'inch'  => 1.0,          # 1inch = 1 inch
      'ft'    => 12.0           # 1ft = 12 inch
    }.freeze

    # -----------------------------------------------------------------------
    # 顯示匯入選項對話框
    # @param callback [Proc] 匯入回呼，接收 options Hash
    # -----------------------------------------------------------------------
    def self.show(file_path, &callback)
      dialog = UI::HtmlDialog.new(
        dialog_title: 'mumi OBJ Import Options',
        preferences_key: 'mumi_obj_importer_options',
        width: 380,
        height: 480,
        left: 300,
        top: 200,
        resizable: false,
        style: UI::HtmlDialog::STYLE_DIALOG
      )

      dialog.set_html(build_html(file_path))

      # 接收來自 HTML 的匯入指令
      dialog.add_action_callback('do_import') do |_ctx, json_str|
        begin
          # 手動解析簡單 JSON（SketchUp Ruby 沒有內建 JSON gem）
          options = parse_simple_json(json_str)
          dialog.close
          callback.call(options) if callback
        rescue => e
          puts "[mumi OBJ Importer] Options error: #{e.message}"
          dialog.close
        end
      end

      dialog.add_action_callback('do_cancel') do |_ctx, _params|
        dialog.close
      end

      dialog.show
    end

    # -----------------------------------------------------------------------
    # 取得單位縮放因子
    # -----------------------------------------------------------------------
    def self.unit_scale(unit_key)
      UNIT_SCALES[unit_key] || 1.0
    end

    private

    # -----------------------------------------------------------------------
    # 簡易 JSON 解析（不依賴外部 gem）
    # 解析格式: {"key":"value","key2":"value2"}
    # -----------------------------------------------------------------------
    def self.parse_simple_json(json_str)
      result = {}
      # 移除大括號
      content = json_str.strip.gsub(/^\{|\}$/, '')
      # 分割 key-value pairs
      content.scan(/"(\w+)"\s*:\s*"([^"]*)"/).each do |key, value|
        result[key] = value
      end
      result
    end

    # -----------------------------------------------------------------------
    # 建立 HTML 內容
    # -----------------------------------------------------------------------
    def self.build_html(file_path)
      filename = File.basename(file_path)

      <<~HTML
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="UTF-8">
          <style>
            * { margin: 0; padding: 0; box-sizing: border-box; }
            body {
              font-family: 'Segoe UI', 'Microsoft JhengHei', sans-serif;
              background: #f0f0f0;
              color: #333333;
              padding: 20px;
              user-select: none;
            }
            h2 {
              font-size: 16px;
              color: #2b5797;
              margin-bottom: 6px;
              letter-spacing: 0.3px;
            }
            .filename {
              font-size: 12px;
              color: #888888;
              margin-bottom: 18px;
              overflow: hidden;
              text-overflow: ellipsis;
              white-space: nowrap;
            }
            .option-group {
              margin-bottom: 16px;
            }
            label {
              display: block;
              font-size: 13px;
              color: #555555;
              margin-bottom: 6px;
              font-weight: 600;
            }
            select {
              width: 100%;
              padding: 8px 12px;
              background: #ffffff;
              color: #333333;
              border: 1px solid #c0c0c0;
              border-radius: 4px;
              font-size: 13px;
              cursor: pointer;
              outline: none;
            }
            select:hover { border-color: #4a90d9; }
            select:focus { border-color: #4a90d9; box-shadow: 0 0 0 2px rgba(74,144,217,0.15); }

            .hint {
              font-size: 11px;
              color: #999999;
              margin-top: 4px;
              line-height: 1.4;
            }

            /* Checkbox */
            .checkbox-row {
              display: flex;
              align-items: center;
              gap: 8px;
              margin-bottom: 6px;
            }
            .checkbox-row input[type="checkbox"] {
              width: 16px;
              height: 16px;
              accent-color: #4a90d9;
              cursor: pointer;
            }
            .checkbox-row label {
              display: inline;
              margin-bottom: 0;
              cursor: pointer;
            }

            /* Number input */
            input[type="number"] {
              width: 70px;
              padding: 6px 8px;
              background: #ffffff;
              color: #333333;
              border: 1px solid #c0c0c0;
              border-radius: 4px;
              font-size: 13px;
              outline: none;
              text-align: center;
            }
            input[type="number"]:hover { border-color: #4a90d9; }
            input[type="number"]:focus { border-color: #4a90d9; box-shadow: 0 0 0 2px rgba(74,144,217,0.15); }
            .angle-row {
              display: flex;
              align-items: center;
              gap: 8px;
              margin-top: 6px;
            }
            .angle-label {
              font-size: 12px;
              color: #666666;
            }

            .button-row {
              display: flex;
              gap: 10px;
              margin-top: 24px;
              justify-content: flex-end;
            }
            button {
              padding: 8px 24px;
              border: 1px solid transparent;
              border-radius: 4px;
              font-size: 13px;
              font-weight: 600;
              cursor: pointer;
              transition: all 0.15s;
            }
            .btn-import {
              background: #4a90d9;
              color: #ffffff;
            }
            .btn-import:hover { background: #3a7bc8; }
            .btn-cancel {
              background: #e0e0e0;
              color: #555555;
              border-color: #c0c0c0;
            }
            .btn-cancel:hover { background: #d0d0d0; }
          </style>
        </head>
        <body>
          <h2>mumi OBJ Import Options</h2>
          <div class="filename" title="#{filename}">#{filename}</div>

          <div class="option-group">
            <label>Up Axis 上方軸</label>
            <select id="up_axis">
              <option value="y_up" selected>Y-up (e.g exported from Maya or C4D)</option>
              <option value="z_up">Z-up (e.g exported from Blender or 3ds Max)</option>
            </select>
            <div class="hint">Select the up-axis of the source model / 選擇來源模型的上方軸向</div>
          </div>

          <div class="option-group">
            <label>Unit 單位</label>
            <select id="source_unit">
              <option value="mm">Millimeters (mm)</option>
              <option value="cm" selected>Centimeters (cm)</option>
              <option value="m">Meters (m)</option>
              <option value="inch">Inches (inch)</option>
              <option value="ft">Feet (ft)</option>
            </select>
            <div class="hint">Select model units for import / 選擇模型匯入時使用的單位</div>
          </div>

          <div class="option-group">
              <div class="checkbox-row">
                <input type="checkbox" id="soften_edges" checked>
                <label for="soften_edges">Auto Soften Edges 自動柔化邊線</label>
              </div>
              <div class="angle-row">
                <span class="angle-label">Angle Threshold 角度閾值</span>
                <input type="number" id="soften_angle" value="15" min="0" max="180" step="5">
                <span class="angle-label">°</span>
              </div>
              <div class="hint">Soften/smooth edges if the angle between adjacent faces is below the threshold. Larger angles yield smoother results<br>相鄰面夾角 ≤ 閾值的邊線會被柔化隱藏，值越大越平滑</div>
            </div>

            <div class="button-row">
              <button class="btn-cancel" onclick="doCancel()">Cancel</button>
              <button class="btn-import" onclick="doImport()">Import</button>
            </div>

          <script>
            function doImport() {
              var upAxis = document.getElementById('up_axis').value;
              var unit = document.getElementById('source_unit').value;
              var softenEdges = document.getElementById('soften_edges').checked ? 'true' : 'false';
              var softenAngle = document.getElementById('soften_angle').value;
              var json = '{"up_axis":"' + upAxis + '","source_unit":"' + unit + '","soften_edges":"' + softenEdges + '","soften_angle":"' + softenAngle + '"}';
              sketchup.do_import(json);
            }
            function doCancel() {
              sketchup.do_cancel();
            }
            // Enter 鍵觸發匯入
            document.addEventListener('keydown', function(e) {
              if (e.key === 'Enter') doImport();
              if (e.key === 'Escape') doCancel();
            });
          </script>
        </body>
        </html>
      HTML
    end

  end # module OptionsDialog
end # module MUMI_ObjImporter
