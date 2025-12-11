module AlunosHelper
  def alunos_section_active?
    current_page?(selecionar_escola_alunos_path) ||
      (controller_name == 'alunos' && action_name.in?(%w[index show edit new]))
  end
end
