module AnoLetivosHelper
  def ano_letivos_section_active?
  current_page?(selecionar_escola_ano_letivo_path) ||
    (controller_name == 'ano_letivos' && action_name.in?(%w[index show edit new]))
  end

end
