module ConteudosHelper

  def conteudos_section_active?
    current_page?(selecionar_escola_conteudos_path) ||
      (controller_name == 'admin_conteudos' && action_name.in?(%w[index show edit new]))
  end

  def badge_conteudo(conteudo)
  cor_bg = conteudo.disciplina&.cor_nome || "#3c3c3c"
  text_color = contraste_texto(cor_bg)

  content_tag(
    :span,
    conteudo.disciplina.nome,
    class: "px-3 py-1 text-xs font-medium rounded-full",
    style: "background-color: #{cor_bg}; color: #{text_color};"
  )
  end
end
