module FrequenciasHelper
  def frequencias_section_path?
    puts "NOME AQUI: ", controller_name
    controller_path.include?("frequencias") || controller_path.include?("frequencia")
  end
end