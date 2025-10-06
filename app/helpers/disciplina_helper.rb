module DisciplinaHelper
  def card_classes(area)
    case area
    when "exatas"
      "bg-gradient-to-br from-blue-50/40 via-blue-100/40 to-blue-200/60 border border-blue-300/50"
    when "humanas"
      "bg-gradient-to-br from-yellow-50/40 via-yellow-100/40 to-yellow-200/60 border border-yellow-300/50"
    when "linguagens"
      "bg-gradient-to-br from-purple-50/40 via-purple-100/40 to-purple-200/60 border border-purple-300/50"
    when "biologicas"
      "bg-gradient-to-br from-green-50/40 via-green-100/40 to-green-200/60 border border-green-300/50"
    when "tecnica"
      "bg-gradient-to-br from-orange-50/40 via-orange-100/40 to-orange-200/60 border border-orange-300/50"
    when "interdisciplinares"
      "bg-gradient-to-br from-indigo-50/40 via-indigo-100/40 to-indigo-200/60 border border-indigo-300/50"
    when "extras"
      "bg-gradient-to-br from-pink-50/40 via-pink-100/40 to-pink-200/60 border border-pink-300/50"
    else
      "bg-gradient-to-br from-gray-50/40 via-gray-100/40 to-gray-200/60 border border-gray-300/50"
    end
  end

  def bg_pattern(area)
    case area
    when "exatas"
      "bg-gradient-to-br from-blue-50/20 via-transparent to-blue-100/30"
    when "humanas"
      "bg-gradient-to-br from-yellow-50/20 via-transparent to-yellow-100/30"
    when "linguagens"
      "bg-gradient-to-br from-purple-50/20 via-transparent to-purple-100/30"
    when "biologicas"
      "bg-gradient-to-br from-green-50/20 via-transparent to-green-100/30"
    when "tecnica"
      "bg-gradient-to-br from-teal-50/20 via-transparent to-teal-100/30"
    when "interdisciplinares"
      "bg-gradient-to-br from-indigo-50/20 via-transparent to-indigo-100/30"
    when "extras"
      "bg-gradient-to-br from-pink-50/20 via-transparent to-pink-100/30"
    else
      "bg-gradient-to-br from-gray-50/20 via-transparent to-gray-100/30"
    end
  end

  def area_cfg(area)
    {
      'exatas' => { cor: 'blue', bg: 'blue-100', text: 'blue-700' },
      'humanas' => { cor: 'yellow', bg: 'yellow-100', text: 'yellow-700' },
      'linguagens' => { cor: 'purple', bg: 'purple-100', text: 'purple-700' },
      'biologicas' => { cor: 'green', bg: 'green-100', text: 'green-700' },
      'tecnica' => { cor: 'orange', bg: 'orange-100', text: 'orange-700' },
      'interdisciplinares' => { cor: 'fuchsia', bg: 'fuchsia-100', text: 'fuchsia-700' },
      'extras' => { cor: 'rose', bg: 'rose-100', text: 'rose-700' }
    }[area] || { cor: 'gray', bg: 'gray-100', text: 'gray-700' }
  end
  def svgs(area ,classes: "w-5 h-5 text-current")

    case area
    when 'exatas'
      <<~SVG.html_safe
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="#{classes}">
          <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 15.75V18m-7.5-6.75h.008v.008H8.25v-.008Zm0 2.25h.008v.008H8.25V13.5Zm0 2.25h.008v.008H8.25v-.008Zm0 2.25h.008v.008H8.25V18Zm2.498-6.75h.007v.008h-.007v-.008Zm0 2.25h.007v.008h-.007V13.5Zm0 2.25h.007v.008h-.007v-.008Zm0 2.25h.007v.008h-.007V18Zm2.504-6.75h.008v.008h-.008v-.008Zm0 2.25h.008v.008h-.008V13.5Zm0 2.25h.008v.008h-.008v-.008Zm0 2.25h.008v.008h-.008V18Zm2.498-6.75h.008v.008h-.008v-.008Zm0 2.25h.008v.008h-.008V13.5ZM8.25 6h7.5v2.25h-7.5V6ZM12 2.25c-1.892 0-3.758.11-5.593.322C5.307 2.7 4.5 3.65 4.5 4.757V19.5a2.25 2.25 0 0 0 2.25 2.25h10.5a2.25 2.25 0 0 0 2.25-2.25V4.757c0-1.108-.806-2.057-1.907-2.185A48.507 48.507 0 0 0 12 2.25Z" />
        </svg>    
      SVG
    when 'humanas'
      <<~SVG.html_safe
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="#{classes}">
          <path stroke-linecap="round" stroke-linejoin="round" d="M12 6.042A8.967 8.967 0 0 0 6 3.75c-1.052 0-2.062.18-3 .512v14.25A8.987 8.987 0 0 1 6 18c2.305 0 4.408.867 6 2.292m0-14.25a8.966 8.966 0 0 1 6-2.292c1.052 0 2.062.18 3 .512v14.25A8.987 8.987 0 0 0 18 18a8.967 8.967 0 0 0-6 2.292m0-14.25v14.25" />
        </svg>
      SVG
    when 'linguagens'
      <<~SVG.html_safe
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="#{classes}">
          <path stroke-linecap="round" stroke-linejoin="round" d="M20.25 8.511c.884.284 1.5 1.128 1.5 2.097v4.286c0 1.136-.847 2.1-1.98 2.193-.34.027-.68.052-1.02.072v3.091l-3-3c-1.354 0-2.694-.055-4.02-.163a2.115 2.115 0 0 1-.825-.242m9.345-8.334a2.126 2.126 0 0 0-.476-.095 48.64 48.64 0 0 0-8.048 0c-1.131.094-1.976 1.057-1.976 2.192v4.286c0 .837.46 1.58 1.155 1.951m9.345-8.334V6.637c0-1.621-1.152-3.026-2.76-3.235A48.455 48.455 0 0 0 11.25 3c-2.115 0-4.198.137-6.24.402-1.608.209-2.76 1.614-2.76 3.235v6.226c0 1.621 1.152 3.026 2.76 3.235.577.075 1.157.14 1.74.194V21l4.155-4.155" />
        </svg>

      SVG
    when 'biologicas'
      <<~SVG.html_safe
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="#{classes}">
          <path stroke-linecap="round" stroke-linejoin="round" d="M9.75 3.104v5.714a2.25 2.25 0 0 1-.659 1.591L5 14.5M9.75 3.104c-.251.023-.501.05-.75.082m.75-.082a24.301 24.301 0 0 1 4.5 0m0 0v5.714c0 .597.237 1.17.659 1.591L19.8 15.3M14.25 3.104c.251.023.501.05.75.082M19.8 15.3l-1.57.393A9.065 9.065 0 0 1 12 15a9.065 9.065 0 0 0-6.23-.693L5 14.5m14.8.8 1.402 1.402c1.232 1.232.65 3.318-1.067 3.611A48.309 48.309 0 0 1 12 21c-2.773 0-5.491-.235-8.135-.687-1.718-.293-2.3-2.379-1.067-3.61L5 14.5" />
        </svg>  
      SVG
    when 'tecnica'
      <<~SVG.html_safe
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="#{classes}">
          <path stroke-linecap="round" stroke-linejoin="round" d="M9.594 3.94c.09-.542.56-.94 1.11-.94h2.593c.55 0 1.02.398 1.11.94l.213 1.281c.063.374.313.686.645.87.074.04.147.083.22.127.325.196.72.257 1.075.124l1.217-.456a1.125 1.125 0 0 1 1.37.49l1.296 2.247a1.125 1.125 0 0 1-.26 1.431l-1.003.827c-.293.241-.438.613-.43.992a7.723 7.723 0 0 1 0 .255c-.008.378.137.75.43.991l1.004.827c.424.35.534.955.26 1.43l-1.298 2.247a1.125 1.125 0 0 1-1.369.491l-1.217-.456c-.355-.133-.75-.072-1.076.124a6.47 6.47 0 0 1-.22.128c-.331.183-.581.495-.644.869l-.213 1.281c-.09.543-.56.94-1.11.94h-2.594c-.55 0-1.019-.398-1.11-.94l-.213-1.281c-.062-.374-.312-.686-.644-.87a6.52 6.52 0 0 1-.22-.127c-.325-.196-.72-.257-1.076-.124l-1.217.456a1.125 1.125 0 0 1-1.369-.49l-1.297-2.247a1.125 1.125 0 0 1 .26-1.431l1.004-.827c.292-.24.437-.613.43-.991a6.932 6.932 0 0 1 0-.255c.007-.38-.138-.751-.43-.992l-1.004-.827a1.125 1.125 0 0 1-.26-1.43l1.297-2.247a1.125 1.125 0 0 1 1.37-.491l1.216.456c.356.133.751.072 1.076-.124.072-.044.146-.086.22-.128.332-.183.582-.495.644-.869l.214-1.28Z" />
          <path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z" />
        </svg>

      SVG

    when 'interdisciplinares'
      <<~SVG.html_safe
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="#{classes}">
          <path stroke-linecap="round" stroke-linejoin="round" d="M14.25 6.087c0-.355.186-.676.401-.959.221-.29.349-.634.349-1.003 0-1.036-1.007-1.875-2.25-1.875s-2.25.84-2.25 1.875c0 .369.128.713.349 1.003.215.283.401.604.401.959v0a.64.64 0 0 1-.657.643 48.39 48.39 0 0 1-4.163-.3c.186 1.613.293 3.25.315 4.907a.656.656 0 0 1-.658.663v0c-.355 0-.676-.186-.959-.401a1.647 1.647 0 0 0-1.003-.349c-1.036 0-1.875 1.007-1.875 2.25s.84 2.25 1.875 2.25c.369 0 .713-.128 1.003-.349.283-.215.604-.401.959-.401v0c.31 0 .555.26.532.57a48.039 48.039 0 0 1-.642 5.056c1.518.19 3.058.309 4.616.354a.64.64 0 0 0 .657-.643v0c0-.355-.186-.676-.401-.959a1.647 1.647 0 0 1-.349-1.003c0-1.035 1.008-1.875 2.25-1.875 1.243 0 2.25.84 2.25 1.875 0 .369-.128.713-.349 1.003-.215.283-.4.604-.4.959v0c0 .333.277.599.61.58a48.1 48.1 0 0 0 5.427-.63 48.05 48.05 0 0 0 .582-4.717.532.532 0 0 0-.533-.57v0c-.355 0-.676.186-.959.401-.29.221-.634.349-1.003.349-1.035 0-1.875-1.007-1.875-2.25s.84-2.25 1.875-2.25c.37 0 .713.128 1.003.349.283.215.604.401.96.401v0a.656.656 0 0 0 .658-.663 48.422 48.422 0 0 0-.37-5.36c-1.886.342-3.81.574-5.766.689a.578.578 0 0 1-.61-.58v0Z" />
        </svg>

      SVG
    when 'extras'
      <<~SVG.html_safe
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="#{classes}">
          <path stroke-linecap="round" stroke-linejoin="round" d="M9.813 15.904 9 18.75l-.813-2.846a4.5 4.5 0 0 0-3.09-3.09L2.25 12l2.846-.813a4.5 4.5 0 0 0 3.09-3.09L9 5.25l.813 2.846a4.5 4.5 0 0 0 3.09 3.09L15.75 12l-2.846.813a4.5 4.5 0 0 0-3.09 3.09ZM18.259 8.715 18 9.75l-.259-1.035a3.375 3.375 0 0 0-2.455-2.456L14.25 6l1.036-.259a3.375 3.375 0 0 0 2.455-2.456L18 2.25l.259 1.035a3.375 3.375 0 0 0 2.456 2.456L21.75 6l-1.035.259a3.375 3.375 0 0 0-2.456 2.456ZM16.894 20.567 16.5 21.75l-.394-1.183a2.25 2.25 0 0 0-1.423-1.423L13.5 18.75l1.183-.394a2.25 2.25 0 0 0 1.423-1.423l.394-1.183.394 1.183a2.25 2.25 0 0 0 1.423 1.423l1.183.394-1.183.394a2.25 2.25 0 0 0-1.423 1.423Z" />
        </svg>
      SVG
    end
  end

  def badge_direita(area)
    cfg = area_cfg(area) 

    badge = content_tag(:span, area.to_s.titleize.upcase, class: "px-3 py-1 text-xs font-medium rounded-full bg-#{cfg[:bg]} text-#{cfg[:text]}")

    badge
  end

  def badge_area(area)
    cfg = area_cfg(area)

    content_tag(:div, class: "flex items-center justify-between bg-gray-50 rounded-lg p-4 border-l-4 border-#{cfg[:cor]}-500") do
      # Parte esquerda: ícone + textos
      icon_text = content_tag(:div, class: "flex items-center space-x-3") do
        # Ícone
        svg_classes = "w-5 h-5 text-#{cfg[:cor]}-600"
        icon = content_tag(:div, svgs(area, classes: svg_classes), class: "p-2 rounded-lg bg-#{cfg[:bg]}")

        # Textos
        texts = content_tag(:div) do
          content_tag(:p, "Área", class: "text-sm font-medium text-gray-600") +
          content_tag(:p, area.to_s.titleize, class: "text-lg font-semibold text-#{cfg[:text]}")
        end

        icon + texts
      end

      # Badge direita
      badge = content_tag(:span, area.to_s.titleize.upcase, class: "px-3 py-1 text-xs font-medium rounded-full bg-#{cfg[:bg]} text-#{cfg[:text]}")

      icon_text + badge
    end
  end
end