module PlanoDeEnsinoHelper
  def planos_de_ensino_section_active?
    current_page?(selecionar_escola_planos_de_ensino_path) ||
      (controller_name == 'planos_de_ensino' && action_name.in?(%w[index show edit new selecionar_escola]))
  end
end
