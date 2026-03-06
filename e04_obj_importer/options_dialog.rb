# =============================================================================
# e04 OBJ Importer - Import Options Dialog
# HtmlDialog UI for import settings
# =============================================================================

module E04_ObjImporter
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
        dialog_title: 'e04 OBJ Import Options',
        preferences_key: 'e04_obj_importer_options',
        width: 380,
        height: 360,
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
          puts "[e04 OBJ Importer] Options error: #{e.message}"
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
              background: #1e1e2e;
              color: #cdd6f4;
              padding: 20px;
              user-select: none;
            }
            h2 {
              font-size: 16px;
              color: #89b4fa;
              margin-bottom: 6px;
              letter-spacing: 0.5px;
            }
            .filename {
              font-size: 12px;
              color: #6c7086;
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
              color: #a6adc8;
              margin-bottom: 6px;
              font-weight: 600;
            }
            select {
              width: 100%;
              padding: 8px 12px;
              background: #313244;
              color: #cdd6f4;
              border: 1px solid #45475a;
              border-radius: 6px;
              font-size: 13px;
              cursor: pointer;
              outline: none;
              appearance: none;
              -webkit-appearance: none;
            }
            select:hover { border-color: #89b4fa; }
            select:focus { border-color: #89b4fa; box-shadow: 0 0 0 2px rgba(137,180,250,0.2); }

            .hint {
              font-size: 11px;
              color: #585b70;
              margin-top: 4px;
              line-height: 1.4;
            }

            .button-row {
              display: flex;
              gap: 10px;
              margin-top: 24px;
              justify-content: flex-end;
            }
            button {
              padding: 8px 24px;
              border: none;
              border-radius: 6px;
              font-size: 13px;
              font-weight: 600;
              cursor: pointer;
              transition: all 0.15s;
            }
            .btn-import {
              background: #89b4fa;
              color: #1e1e2e;
            }
            .btn-import:hover { background: #74c7ec; }
            .btn-cancel {
              background: #45475a;
              color: #cdd6f4;
            }
            .btn-cancel:hover { background: #585b70; }
          </style>
        </head>
        <body>
          <h2>e04 OBJ Import Options</h2>
          <div class="filename" title="#{filename}">#{filename}</div>

          <div class="option-group">
            <label>Up Axis 上方軸</label>
            <select id="up_axis">
              <option value="y_up" selected>Y-up (Maya, C4D, Unity)</option>
              <option value="z_up">Z-up (Blender, 3ds Max, SketchUp)</option>
            </select>
            <div class="hint">選擇來源軟體使用的上方軸向</div>
          </div>

          <div class="option-group">
            <label>Source Unit 來源單位</label>
            <select id="source_unit">
              <option value="mm">Millimeters (mm)</option>
              <option value="cm" selected>Centimeters (cm)</option>
              <option value="m">Meters (m)</option>
              <option value="inch">Inches (inch)</option>
              <option value="ft">Feet (ft)</option>
            </select>
            <div class="hint">OBJ 檔案中的座標數值代表的單位</div>
          </div>

          <div class="button-row">
            <button class="btn-cancel" onclick="doCancel()">Cancel</button>
            <button class="btn-import" onclick="doImport()">Import</button>
          </div>

          <script>
            function doImport() {
              var upAxis = document.getElementById('up_axis').value;
              var unit = document.getElementById('source_unit').value;
              var json = '{"up_axis":"' + upAxis + '","source_unit":"' + unit + '"}';
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
end # module E04_ObjImporter
