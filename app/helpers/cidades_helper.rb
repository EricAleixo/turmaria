module CidadesHelper

  def cidades_section_active?
    controller_path.include?('cidades')
  end

end