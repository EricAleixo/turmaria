module FrequenciasHelper
  def frequencias_section_path?
    controller_path.include?("frequencias") || controller_path.include?("frequencia")
  end
end