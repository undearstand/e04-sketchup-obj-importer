# =============================================================================
# mumi OBJ Importer - MTL Parser
# 解析 .mtl 材質檔案
# =============================================================================

module MUMI_ObjImporter
  module MtlParser

    # -----------------------------------------------------------------------
    # 解析 MTL 檔案
    #
    # 回傳 Hash: { material_name => properties_hash }
    #
    # properties_hash:
    #   :diffuse_color  => [r, g, b]     漫射色 (0.0-1.0)
    #   :specular_color => [r, g, b]     鏡面色 (0.0-1.0)
    #   :alpha          => Float         透明度 (0.0-1.0, 1.0=不透明)
    #   :texture_path   => "path"        漫射貼圖路徑 (map_Kd)
    # -----------------------------------------------------------------------
    def self.parse(file_path)
      materials = {}
      current_material = nil
      mtl_dir = File.dirname(file_path)

      File.open(file_path, 'r') do |f|
        f.each_line do |raw_line|
          line = raw_line.strip

          # 跳過空行和註解
          next if line.empty? || line.start_with?('#')

          parts = line.split(/\s+/)
          keyword = parts[0]

          case keyword
          when 'newmtl'
            # 新材質
            current_material = parts[1..].join(' ')
            materials[current_material] = {
              diffuse_color: [0.8, 0.8, 0.8],
              specular_color: [0.0, 0.0, 0.0],
              alpha: 1.0,
              texture_path: nil
            }

          when 'Kd'
            # 漫射色: Kd r g b
            next unless current_material
            materials[current_material][:diffuse_color] = [
              parts[1].to_f,
              parts[2].to_f,
              parts[3].to_f
            ]

          when 'Ks'
            # 鏡面色: Ks r g b
            next unless current_material
            materials[current_material][:specular_color] = [
              parts[1].to_f,
              parts[2].to_f,
              parts[3].to_f
            ]

          when 'd'
            # 透明度 (dissolve): d alpha (1.0 = 不透明)
            next unless current_material
            materials[current_material][:alpha] = parts[1].to_f

          when 'Tr'
            # 透明度 (transparency): Tr value (0.0 = 不透明, 與 d 相反)
            next unless current_material
            materials[current_material][:alpha] = 1.0 - parts[1].to_f

          when 'map_Kd'
            # 漫射貼圖
            next unless current_material
            texture_file = parts[1..].join(' ')
            # 解析貼圖路徑
            texture_path = resolve_texture_path(mtl_dir, texture_file)
            materials[current_material][:texture_path] = texture_path

          end # case
        end # each_line
      end # File.open

      materials
    end

    private

    # -----------------------------------------------------------------------
    # 解析貼圖路徑（相對/絕對）
    # -----------------------------------------------------------------------
    def self.resolve_texture_path(mtl_dir, texture_file)
      # 嘗試相對路徑
      relative_path = File.join(mtl_dir, texture_file)
      return relative_path if File.exist?(relative_path)

      # 嘗試絕對路徑
      return texture_file if File.exist?(texture_file)

      # 嘗試同一目錄下（只取檔名）
      basename_path = File.join(mtl_dir, File.basename(texture_file))
      return basename_path if File.exist?(basename_path)

      # 找不到就回傳原始路徑（之後建立材質時會跳過）
      puts "[mumi OBJ Importer] WARNING: Texture not found: #{texture_file}"
      nil
    end

  end # module MtlParser
end # module MUMI_ObjImporter
