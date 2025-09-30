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
end