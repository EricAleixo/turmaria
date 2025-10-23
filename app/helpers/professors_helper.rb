module ProfessorsHelper
  
  # Configuração das cores por formação
  def tipo_professor_config(formacao)
    {
      'doutorado'    => { cor: 'blue',    bg: 'blue-100',   text: 'blue-700' },
      'mestrado'     => { cor: 'red',     bg: 'red-100',    text: 'red-700' },
      'pos_graduado' => { cor: 'yellow',  bg: 'yellow-100', text: 'yellow-700' },
      'graduado'     => { cor: 'gray',    bg: 'gray-100',   text: 'gray-700' }
    }[formacao] || { cor: 'gray', bg: 'gray-100', text: 'gray-700' }
  end

  def gradient_mobile(formacao)
    case formacao
    when 'doutorado'
      "bg-gradient-to-br from-white via-blue-50 to-blue-100 border border-blue-200"
    when 'mestrado'
      "bg-gradient-to-br from-white via-red-50 to-red-100 border border-red-200"
    when 'pos_graduado'
      "bg-gradient-to-br from-white via-yellow-50 to-yellow-100 border border-yellow-200"
    when 'graduado'
      "bg-gradient-to-br from-white via-gray-50 to-gray-100 border border-gray-200"
    else
      "bg-gradient-to-br from-white via-gray-50 to-gray-100 border border-gray-200"
    end
  end

  # SVG do olho, único para todos
  def svg_olho(classes: "w-5 h-5 text-current")
    <<~SVG.html_safe
      <svg class="#{classes}" fill="currentColor" viewBox="0 0 20 20">
        <path d="M10 12a2 2 0 100-4 2 2 0 000 4z"/>
        <path fill-rule="evenodd" d="M.458 10C1.732 5.943 5.522 3 10 3s8.268 2.943 9.542 7c-1.274 4.057-5.064 7-9.542 7S1.732 14.057.458 10zM14 10a4 4 0 11-8 0 4 4 0 018 0z" clip-rule="evenodd"/>
      </svg>
    SVG
  end

  # Badge de formação
  def badge_formacao(formacao)
    cfg = tipo_professor_config(formacao)

    content_tag(:div, class: "flex items-center justify-between bg-gray-50 rounded-lg p-4 border-l-4 border-#{cfg[:cor]}-500") do
      # Ícone + textos
      icon_text = content_tag(:div, class: "flex items-center space-x-3") do
        icon = content_tag(:div, svg_olho(classes: "w-5 h-5 text-#{cfg[:cor]}-600"), class: "p-2 rounded-lg bg-#{cfg[:bg]}")
        texts = content_tag(:div) do
          content_tag(:p, "Formação", class: "text-sm font-medium text-gray-600") +
          content_tag(:p, formacao.to_s.titleize, class: "text-lg font-semibold text-#{cfg[:text]}")
        end
        icon + texts
      end

      # Badge à direita
      badge = content_tag(:span, formacao.to_s.titleize.upcase, class: "px-3 py-1 text-xs font-medium rounded-full bg-#{cfg[:bg]} text-#{cfg[:text]}")

      icon_text + badge
    end
  end
  

  def contato_card(titulo:, valor:, cor:, icone_svg:)
    content_tag(:div, class: "bg-gradient-to-br from-#{cor}-50 to-#{cor}-100 rounded-lg p-4 border border-#{cor}-200") do
      concat(
        content_tag(:div, class: "flex items-center space-x-3") do
          concat(content_tag(:div, icone_svg, class: "p-2 rounded-lg bg-#{cor}-100"))
          concat(
            content_tag(:div) do
              concat(content_tag(:p, titulo, class: "text-xs font-medium text-#{cor}-700 uppercase tracking-wide"))
              concat(content_tag(:p, valor, class: "text-sm font-semibold text-gray-900"))
            end
          )
        end
      )
    end
  end
  
def disciplinas_badges(professor, max_visible = 3)
  disciplinas = professor.disciplinas.to_a
  visible = disciplinas.first(max_visible)
  hidden_count = disciplinas.size - max_visible

  badges = visible.map do |disciplina|
    if disciplina.cor.present?
      cor = disciplina.cor
      text_color = contraste_texto(cor) # 🔹 usa contraste automático
      content_tag(:span, disciplina.nome,
                  class: "px-2 py-1 rounded-full text-sm font-medium",
                  style: "background-color: #{cor}; color: #{text_color};")
    else
      cfg = area_cfg(disciplina.area)
      content_tag(:span, disciplina.nome,
                  class: "px-2 py-1 rounded-full text-sm font-medium bg-#{cfg[:bg]} text-#{cfg[:text]}")
    end
  end

  if hidden_count.positive?
    badges << content_tag(:span, "+#{hidden_count}",
                          class: "px-2 py-1 rounded-full text-sm font-medium bg-gray-200 text-gray-700")
  end

  safe_join(badges, " ")
end

def contraste_texto(cor_hex)
  return "#000000" unless cor_hex.present? && cor_hex.match?(/^#(?:[0-9a-fA-F]{3}){1,2}$/)

  # Remove o "#" e converte os componentes
  r, g, b = cor_hex.delete("#").scan(/../).map { |c| c.to_i(16) }

  # Calcula a luminância relativa (fórmula do W3C)
  luminancia = (0.299 * r + 0.587 * g + 0.114 * b) / 255

  # Se for claro, usa texto escuro; se for escuro, texto branco
  luminancia > 0.6 ? "#000000" : "#FFFFFF"
end
end