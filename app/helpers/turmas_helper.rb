module TurmasHelper
  TURNO_OPTIONS = {
    "manha" => {
      label: "Manhã",
      icon: '<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-4 h-4 mr-1">
               <path stroke-linecap="round" stroke-linejoin="round" d="M12 3v2.25m6.364.386l-1.59 1.59M21 12h-2.25m-.386 6.364l-1.59-1.59M12 18.75V21m-4.364-3.636l-1.59 1.59M5.25 12H3m3.636-4.364l-1.59-1.59M15.75 12a3.75 3.75 0 11-7.5 0 3.75 3.75 0 017.5 0z"/>
             </svg>',
      color: "bg-yellow-100 text-yellow-800"
    },
    "tarde" => {
      label: "Tarde",
      icon: '<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-4 h-4 mr-1">
               <path stroke-linecap="round" stroke-linejoin="round" d="M12 3v4.5m6.364 1.636l-3.182 3.182M21 12h-4.5m-1.636 6.364l-3.182-3.182M12 21v-4.5m-6.364-1.636l3.182-3.182M3 12h4.5m1.636-6.364l3.182 3.182M18 18a6 6 0 11-12 0"/>
             </svg>',
      color: "bg-orange-100 text-orange-800"
    },
    "noite" => {
      label: "Noite",
      icon: '<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-4 h-4 mr-1">
               <path stroke-linecap="round" stroke-linejoin="round" d="M21 12.79A9 9 0 1111.21 3a7.5 7.5 0 0010.08 9.79z"/>
             </svg>',
      color: "bg-blue-100 text-blue-800"
    },
    "integral" => {
      label: "Integral",
      icon: '<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-4 h-4 mr-1">
               <path stroke-linecap="round" stroke-linejoin="round" d="M12 6v6l4 2m5-2a9 9 0 11-18 0 9 9 0 0118 0z"/>
             </svg>',
      color: "bg-green-100 text-green-800"
    }
  }.freeze

  def badge_turno(turma)
    option = TURNO_OPTIONS[turma.turno] || { label: turma.turno.capitalize, icon: "", color: "bg-gray-100 text-gray-800" }

    content_tag :span, class: "badge badge-sm inline-flex items-center gap-1 rounded-full #{option[:color]}" do
      concat(option[:icon].html_safe)
      concat(option[:label])
    end
  end
end
