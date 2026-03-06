# =============================================================================
# e04 OBJ Importer for SketchUp 2026
# Import OBJ files with UV mapping and MTL material support
# =============================================================================

require 'sketchup.rb'
require 'extensions.rb'

ext = SketchupExtension.new('e04 OBJ Importer', 'e04_obj_importer/main.rb')

ext.creator     = 'undearstand'
ext.version     = '1.0.0'
ext.copyright   = '2026'
ext.description = 'Import OBJ files with UV texture coordinates and MTL material support.'

Sketchup.register_extension(ext, true)
