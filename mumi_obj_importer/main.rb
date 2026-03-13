# =============================================================================
# mumi OBJ Importer - Main Module
# =============================================================================

require_relative 'obj_parser'
require_relative 'mtl_parser'
require_relative 'importer'
require_relative 'options_dialog'

module MUMI_ObjImporter

  # -------------------------------------------------------------------------
  # 匯入主流程
  # -------------------------------------------------------------------------
  def self.import_obj_file
    # 檔案選取對話框
    file_path = UI.openpanel(
      'Select OBJ File to Import',
      '',
      'OBJ Files (*.obj)|*.obj||'
    )
    return unless file_path

    # 顯示匯入選項對話框
    OptionsDialog.show(file_path) do |options|
      do_import(file_path, options)
    end
  end

  # -------------------------------------------------------------------------
  # 執行匯入（由選項對話框回呼觸發）
  # -------------------------------------------------------------------------
  def self.do_import(file_path, options)
    puts "[mumi OBJ Importer] Importing: #{file_path}"
    puts "[mumi OBJ Importer] Options: up_axis=#{options['up_axis']}, unit=#{options['source_unit']}, soften=#{options['soften_edges']}, angle=#{options['soften_angle']}"

    begin
      # 1. 解析 OBJ 檔案
      Sketchup.status_text = 'Parsing OBJ file...'
      obj_data = ObjParser.parse(file_path)
      puts "[mumi OBJ Importer] Vertices: #{obj_data[:vertices].length}, " \
           "Faces: #{obj_data[:faces].length}, " \
           "UV coords: #{obj_data[:uvs].length}"

      # 2. 解析 MTL 檔案（如果存在）
      materials_data = {}
      if obj_data[:mtl_file]
        mtl_path = resolve_mtl_path(file_path, obj_data[:mtl_file])
        if mtl_path && File.exist?(mtl_path)
          Sketchup.status_text = 'Parsing MTL file...'
          materials_data = MtlParser.parse(mtl_path)
          puts "[mumi OBJ Importer] Materials: #{materials_data.length}"
        else
          puts "[mumi OBJ Importer] WARNING: MTL file not found: #{obj_data[:mtl_file]}"
        end
      end

      # 3. 從選項取得設定
      swap_yz = (options['up_axis'] == 'y_up')
      unit_scale = OptionsDialog.unit_scale(options['source_unit'])
      soften_angle = (options['soften_edges'] == 'true') ? (options['soften_angle'] || '20').to_f : 0.0
      puts "[mumi OBJ Importer] swap_yz=#{swap_yz}, unit_scale=#{unit_scale}, soften_angle=#{soften_angle}"

      # 4. 匯入到 SketchUp
      Sketchup.status_text = 'Building model...'
      obj_dir = File.dirname(file_path)
      Importer.import(obj_data, materials_data, obj_dir,
                      swap_yz: swap_yz, unit_scale: unit_scale, soften_angle: soften_angle)

      Sketchup.status_text = 'OBJ import complete!'
      puts "[mumi OBJ Importer] Import complete!"

    rescue => e
      UI.messagebox("OBJ Import Error:\n#{e.message}")
      puts "[mumi OBJ Importer] ERROR: #{e.message}"
      puts e.backtrace.first(10).join("\n")
    end
  end

  # -------------------------------------------------------------------------
  # 解析 MTL 檔案路徑（支援相對路徑與絕對路徑）
  # -------------------------------------------------------------------------
  def self.resolve_mtl_path(obj_path, mtl_filename)
    # 先嘗試相對於 OBJ 檔案的路徑
    obj_dir = File.dirname(obj_path)
    relative_path = File.join(obj_dir, mtl_filename)
    return relative_path if File.exist?(relative_path)

    # 再嘗試絕對路徑
    return mtl_filename if File.exist?(mtl_filename)

    nil
  end

  # -------------------------------------------------------------------------
  # 載入選單（僅載入一次）
  # -------------------------------------------------------------------------
  unless file_loaded?(__FILE__)
    menu = UI.menu('Extensions')
    menu.add_item('mumi OBJ Importer') { import_obj_file }
    file_loaded(__FILE__)
  end

end # module MUMI_ObjImporter
