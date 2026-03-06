# =============================================================================
# e04 OBJ Importer - SketchUp Importer
# 將解析後的 OBJ 資料匯入 SketchUp 模型
# =============================================================================

module E04_ObjImporter
  module Importer

    # -----------------------------------------------------------------------
    # 匯入 OBJ 資料到 SketchUp
    #
    # @param obj_data [Hash] ObjParser.parse 的回傳值
    # @param materials_data [Hash] MtlParser.parse 的回傳值
    # @param obj_dir [String] OBJ 檔案所在目錄（用於解析貼圖路徑）
    # @param swap_yz [Boolean] 是否交換 Y/Z 軸 (Y-up → Z-up)
    # @param unit_scale [Float] 來源單位→英吋的縮放因子
    # -----------------------------------------------------------------------
    def self.import(obj_data, materials_data, obj_dir, swap_yz: true, unit_scale: 0.393701)
      model = Sketchup.active_model

      model.start_operation('Import OBJ', true)

      begin
        # 1. 建立 SketchUp 材質
        su_materials = create_materials(model, materials_data, obj_dir)

        # 2. 轉換頂點座標
        vertices = convert_vertices(obj_data[:vertices], swap_yz, unit_scale)

        # 3. 依群組匯入面
        import_groups(model, obj_data, vertices, su_materials)

        model.commit_operation
      rescue => e
        model.abort_operation
        raise e
      end
    end

    private

    # -----------------------------------------------------------------------
    # 轉換頂點座標
    # - Y-up → Z-up 交換（可選）
    # - 來源單位轉英吋（SketchUp 內部單位）
    # -----------------------------------------------------------------------
    def self.convert_vertices(raw_vertices, swap_yz, unit_scale)
      raw_vertices.map do |v|
        x = v[0] * unit_scale
        if swap_yz
          # Y-up → Z-up: (x, y, z) → (x, -z, y)
          y = -v[2] * unit_scale
          z = v[1] * unit_scale
        else
          y = v[1] * unit_scale
          z = v[2] * unit_scale
        end
        Geom::Point3d.new(x, y, z)
      end
    end

    # -----------------------------------------------------------------------
    # 建立 SketchUp 材質
    # -----------------------------------------------------------------------
    def self.create_materials(model, materials_data, obj_dir)
      su_materials = {}

      materials_data.each do |name, props|
        mat = model.materials.add("e04_#{name}")

        # 設定漫射色
        r = (props[:diffuse_color][0] * 255).to_i
        g = (props[:diffuse_color][1] * 255).to_i
        b = (props[:diffuse_color][2] * 255).to_i
        mat.color = Sketchup::Color.new(r, g, b)

        # 設定透明度
        if props[:alpha] < 1.0
          mat.alpha = props[:alpha]
        end

        # 設定貼圖
        if props[:texture_path] && File.exist?(props[:texture_path])
          begin
            mat.texture = props[:texture_path]
            puts "[e04 OBJ Importer] Loaded texture: #{props[:texture_path]}"
          rescue => e
            puts "[e04 OBJ Importer] WARNING: Failed to load texture: #{e.message}"
          end
        end

        su_materials[name] = mat
      end

      su_materials
    end

    # -----------------------------------------------------------------------
    # 依群組匯入面
    # -----------------------------------------------------------------------
    def self.import_groups(model, obj_data, vertices, su_materials)
      faces = obj_data[:faces]
      groups = obj_data[:groups]
      uvs = obj_data[:uvs]
      total_faces = faces.length
      imported_count = 0

      groups.each do |group_name, face_indices|
        next if face_indices.empty?

        # 為每個 OBJ 群組建立 SketchUp Group
        group = model.active_entities.add_group
        group.name = group_name unless group_name == 'default'
        entities = group.entities

        face_indices.each do |fi|
          face_data = faces[fi]
          imported_count += 1

          # 更新進度
          if imported_count % 500 == 0
            Sketchup.status_text = "Importing faces: #{imported_count}/#{total_faces}"
          end

          # 取得面的頂點
          pts = face_data[:vertex_indices].map { |vi| vertices[vi] }

          # 跳過退化面（少於3個頂點或頂點重複）
          next if pts.length < 3
          next if pts.uniq.length < 3

          begin
            face = entities.add_face(pts)
            next unless face

            # 指派材質
            mat_name = face_data[:material]
            if mat_name && su_materials[mat_name]
              material = su_materials[mat_name]
              face.material = material
              face.back_material = material

              # 設定 UV 映射
              if !face_data[:uv_indices].empty? && !uvs.empty?
                apply_uv_mapping(face, face_data, vertices, uvs, material)
              end
            end

          rescue => e
            # 某些面可能因為共面或其他原因建立失敗，跳過
            puts "[e04 OBJ Importer] Skip face #{fi}: #{e.message}" if fi < 20
          end
        end

        # 移除空群組
        if entities.count == 0
          model.active_entities.erase_entities(group)
        end
      end
    end

    # -----------------------------------------------------------------------
    # 設定面的 UV 映射
    #
    # SketchUp 使用 face.position_material(material, pts_array, front)
    # pts_array 是 [Point3d, UV_Point3d, Point3d, UV_Point3d, ...] 交替排列
    # 至少需要 2 組配對（非共線），通常提供整個面的配對
    # -----------------------------------------------------------------------
    def self.apply_uv_mapping(face, face_data, vertices, uvs, material)
      return unless material.texture

      vi_list = face_data[:vertex_indices]
      ti_list = face_data[:uv_indices]

      # 確保 UV 索引和頂點索引數量匹配
      return if ti_list.length < 3
      return if ti_list.length != vi_list.length

      # 取得面的實際頂點（SketchUp 可能已調整頂點順序）
      face_vertices = face.vertices
      face_pts = face_vertices.map(&:position)

      # 建立 OBJ 頂點 → UV 的映射
      vertex_uv_map = {}
      vi_list.each_with_index do |vi, idx|
        ti = ti_list[idx]
        next if ti < 0 || ti >= uvs.length
        pt = vertices[vi]
        uv = uvs[ti]
        vertex_uv_map[vi] = uv
      end

      # 建立 position_material 所需的配對陣列
      # 最多取 4 個點（SketchUp 限制）
      pts_array = []
      matched = 0

      vi_list.each_with_index do |vi, idx|
        break if matched >= 4
        next unless vertex_uv_map[vi]

        pt3d = vertices[vi]
        uv = vertex_uv_map[vi]

        # 找到最接近的面頂點（因為 SketchUp 可能合併了頂點）
        closest = find_closest_vertex(face_pts, pt3d)
        next unless closest

        pts_array << closest
        pts_array << Geom::Point3d.new(uv[0], uv[1], 0)
        matched += 1
      end

      # 至少需要 2 組配對
      return if matched < 2

      begin
        # 驗證 UV 點不完全相同（避免退化映射）
        uv_points = (0...pts_array.length).select(&:odd?).map { |i| pts_array[i] }
        return if uv_points.uniq.length < 2

        face.position_material(material, pts_array, true)   # 正面
        face.position_material(material, pts_array, false)  # 背面
      rescue => e
        # UV 映射失敗時靜默處理，材質顏色仍會保留
        puts "[e04 OBJ Importer] UV mapping failed for a face: #{e.message}"
      end
    end

    # -----------------------------------------------------------------------
    # 找到離目標點最近的面頂點
    # -----------------------------------------------------------------------
    def self.find_closest_vertex(face_pts, target)
      min_dist = Float::INFINITY
      closest = nil

      face_pts.each do |pt|
        dist = pt.distance(target)
        if dist < min_dist
          min_dist = dist
          closest = pt
        end
      end

      # 容差：0.01 英吋
      closest if min_dist < 0.01
    end

  end # module Importer
end # module E04_ObjImporter
