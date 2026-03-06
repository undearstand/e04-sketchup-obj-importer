# =============================================================================
# e04 OBJ Importer - OBJ Parser
# 解析 .obj 檔案格式
# =============================================================================

module E04_ObjImporter
  module ObjParser

    # -----------------------------------------------------------------------
    # 解析 OBJ 檔案，回傳結構化資料
    #
    # 回傳 Hash:
    #   :vertices  => [[x,y,z], ...]           頂點座標
    #   :uvs       => [[u,v], ...]             UV 貼圖座標
    #   :normals   => [[nx,ny,nz], ...]        法線向量
    #   :faces     => [face_hash, ...]         面資料
    #   :groups    => { group_name => [face_indices] }
    #   :mtl_file  => "filename.mtl" or nil
    #
    # face_hash 結構:
    #   :vertex_indices  => [vi, ...]     頂點索引 (0-based)
    #   :uv_indices      => [ti, ...]     UV 索引 (0-based), 可能為空
    #   :normal_indices  => [ni, ...]     法線索引 (0-based), 可能為空
    #   :material        => "mat_name"    材質名稱, 可能為 nil
    #   :group           => "group_name"  群組名稱
    # -----------------------------------------------------------------------
    def self.parse(file_path)
      vertices = []
      uvs = []
      normals = []
      faces = []
      groups = {}

      current_group = 'default'
      current_material = nil
      mtl_file = nil

      groups[current_group] = []

      File.open(file_path, 'r') do |f|
        f.each_line do |raw_line|
          line = raw_line.strip

          # 跳過空行和註解
          next if line.empty? || line.start_with?('#')

          parts = line.split(/\s+/)
          keyword = parts[0]

          case keyword
          when 'v'
            # 頂點: v x y z
            vertices << [
              parts[1].to_f,
              parts[2].to_f,
              parts[3].to_f
            ]

          when 'vt'
            # UV 貼圖座標: vt u v [w]
            uvs << [
              parts[1].to_f,
              parts[2].to_f
            ]

          when 'vn'
            # 法線: vn nx ny nz
            normals << [
              parts[1].to_f,
              parts[2].to_f,
              parts[3].to_f
            ]

          when 'f'
            # 面: f v1 v2 v3 ... 或 f v1/vt1 v2/vt2 ... 或 f v1/vt1/vn1 ...
            face = parse_face(parts[1..], current_material, current_group)
            face_index = faces.length
            faces << face
            groups[current_group] << face_index

          when 'g', 'o'
            # 群組或物件
            current_group = parts[1..].join(' ')
            current_group = 'default' if current_group.empty?
            groups[current_group] ||= []

          when 'usemtl'
            # 切換材質
            current_material = parts[1..].join(' ')

          when 'mtllib'
            # MTL 檔案引用
            mtl_file = parts[1..].join(' ')

          end # case
        end # each_line
      end # File.open

      {
        vertices: vertices,
        uvs: uvs,
        normals: normals,
        faces: faces,
        groups: groups,
        mtl_file: mtl_file
      }
    end

    private

    # -----------------------------------------------------------------------
    # 解析一個面的頂點資料
    # 支援格式: v, v/vt, v/vt/vn, v//vn
    # -----------------------------------------------------------------------
    def self.parse_face(vertex_tokens, material, group)
      vertex_indices = []
      uv_indices = []
      normal_indices = []

      vertex_tokens.each do |token|
        components = token.split('/')

        # 頂點索引 (OBJ 是 1-based，轉為 0-based)
        vi = components[0].to_i
        vertex_indices << (vi > 0 ? vi - 1 : vi)  # 負數索引保持原樣

        # UV 索引
        if components.length >= 2 && !components[1].empty?
          ti = components[1].to_i
          uv_indices << (ti > 0 ? ti - 1 : ti)
        end

        # 法線索引
        if components.length >= 3 && !components[2].empty?
          ni = components[2].to_i
          normal_indices << (ni > 0 ? ni - 1 : ni)
        end
      end

      {
        vertex_indices: vertex_indices,
        uv_indices: uv_indices,
        normal_indices: normal_indices,
        material: material,
        group: group
      }
    end

  end # module ObjParser
end # module E04_ObjImporter
