module FrequenciasHelper
  def frequencias_section_path?
    controller_path.include?("frequencias")
  end
end