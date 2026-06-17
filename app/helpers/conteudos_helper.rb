module ConteudosHelper

  def conteudos_section_active?
    controller_path.include?('conteudo')
  end

  def conteudos_index_path
    @escola ? escola_conteudos_path(@escola) : conteudos_path
  end

  def conteudo_path_for(conteudo)
    @escola ? escola_conteudo_path(@escola, conteudo) : conteudo_path(conteudo)
  end

  def edit_conteudo_path_for(conteudo)
    @escola ? edit_escola_conteudo_path(@escola, conteudo) : edit_conteudo_path(conteudo)
  end

  def new_conteudo_path_for
    @escola ? new_escola_conteudo_path(@escola) : new_conteudo_path
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
