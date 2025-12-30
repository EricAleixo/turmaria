module ConteudosHelper

  def conteudos_section_active?
    return true if controller_path == 'professor/selecionar_turma'

    controller_path.start_with?('professor/') &&
      controller_name.in?(%w[
        conteudos
        professor_conteudos
        admin_conteudos
      ])
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
