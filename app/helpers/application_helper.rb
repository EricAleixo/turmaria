module ApplicationHelper

  def current_account
    current_admin || current_super_admin
  end

  def card_perfil(&block)
    content_tag(:div, class: "p-4 bg-white rounded-xl shadow-md border border-gray-200 flex flex-col justify-between") do
      capture(&block)
    end
  end

  def card_metric(icon_svg, color_class, value, label)
    # Limpa os dados para garantir que nenhuma tag HTML vinda do banco de dados quebre o layout
    cleaned_value = strip_tags(value.to_s).strip
    cleaned_label = strip_tags(label.to_s).strip

    # Usamos content_tag para construir o HTML de forma segura
    content_tag(:div, class: "bg-white rounded-xl shadow-md p-4 flex flex-col items-start space-y-1 h-full transition duration-150 transform hover:shadow-lg") do

      icon_div = content_tag(:div, class: "#{color_class} p-2 rounded-lg text-white mb-2") do
        icon_svg.html_safe
      end

      value_span = content_tag(:span, cleaned_value, class: "text-xl font-bold text-gray-800 break-words leading-tight")

      label_p = content_tag(:p, cleaned_label, class: "text-sm text-gray-500 mt-1")

      # Concatena todas as partes
      icon_div + value_span + label_p
    end
  end

  # Helper to get current user regardless of type
  def current_any_user
    current_admin || current_professor || current_coordenador || current_super_admin
  end

  # Helper to get current user type as string
  def current_user_type
    return 'Administrador' if current_admin
    return 'Professor' if current_professor
    return 'Coordenador' if current_coordenador
    return 'Super Admin' if current_super_admin
    nil
  end

  # Debug helper to understand what's happening
  def debug_user_status
    {
      current_admin: current_admin.present?,
      current_super_admin: current_super_admin.present?,
      current_professor: current_professor.present?,
      current_coordenador: current_coordenador.present?,
      current_any_user_class: current_any_user&.class&.name,
      current_user_type: current_user_type
    }
  end

  # Helper to render the appropriate sidebar based on user type with explicit checks
  def render_user_sidebar
    # Explicit checks to avoid any ambiguity
    if current_admin.present? && current_super_admin.blank?
      render 'shared/admin_sidebar'
    elsif current_professor.present? && current_admin.blank? && current_super_admin.blank?
      render 'shared/professor_sidebar'
    elsif current_coordenador.present? && current_admin.blank? && current_super_admin.blank?
      render 'shared/coordenador_sidebar'
    elsif current_aluno.present?
      render 'shared/aluno_sidebar'
    elsif current_super_admin.present? && current_admin.blank?
      render 'shared/super_admin_sidebar'
    else
      # Debug fallback - let's see what's happening
      Rails.logger.debug "SIDEBAR DEBUG: #{debug_user_status}"
      render 'shared/super_admin_sidebar'
    end
  end

  # Verifica se o usuário atual pode ver informações de administradores
  def can_see_admin_info?
    # Usa Pundit policy para verificar permissão
    policy = EscolaPolicy.new(controller.current_user, Escola.new)
    policy.view_admin_info?
  rescue
    # Fallback caso não haja usuário logado
    false
  end

  # Gera avatar do administrador (iniciais do nome quando não há foto)
  def admin_avatar(admin, size: 'w-8 h-8', text_size: 'text-sm')
    return nil unless admin

    if admin.respond_to?(:avatar) && admin.avatar.present?
      # Quando implementar upload de fotos, usar esta linha:
      # image_tag admin.avatar, class: "#{size} rounded-full object-cover"
      admin_initials_avatar(admin, size, text_size)
    else
      admin_initials_avatar(admin, size, text_size)
    end
  end

  # Gera avatar com iniciais do nome
  def admin_initials_avatar(admin, size = 'w-8 h-8', text_size = 'text-sm')
    return nil unless admin&.nome

    initials = admin.nome.split.map(&:first).join.upcase.first(2)
    
    # Cores baseadas no hash do nome para consistência
    colors = [
      'bg-blue-500 text-white',
      'bg-green-500 text-white', 
      'bg-purple-500 text-white',
      'bg-red-500 text-white',
      'bg-yellow-500 text-white',
      'bg-indigo-500 text-white',
      'bg-pink-500 text-white',
      'bg-teal-500 text-white'
    ]
    
    color_class = colors[admin.nome.hash % colors.length]
    
    content_tag :div, 
                initials, 
                class: "#{size} #{color_class} rounded-full flex items-center justify-center font-semibold #{text_size}",
                title: admin.nome
  end

  # Tooltip com informações do administrador
  def admin_tooltip_info(admin)
    return '' unless admin

    info = []
    info << "Nome: #{admin.nome}"
    info << "Email: #{admin.email}" if admin.email.present?
    
    info.join("\n")
  end

  def dashboard_link_path
    if current_super_admin.present? || current_professor.present? || current_aluno
      dashboard_path
    elsif current_admin.present?
      escolas_path
    else
      root_path
    end
  end

  def markdown(text)
    return "" if text.blank?
  
    renderer = Redcarpet::Render::HTML.new(
      filter_html: true,
      hard_wrap: true
    )
  
    options = {
      autolink: true,
      tables: true,
      fenced_code_blocks: true,
      strikethrough: true,
      underline: true,
      highlight: true,
      quote: true
    }
  
    markdown = Redcarpet::Markdown.new(renderer, options)
    html = markdown.render(text)
  
    sanitize(
      html,
      tags: %w[p br strong em del code pre h1 h2 h3 h4 h5 h6 blockquote ul ol li table thead tbody tr th td a],
      attributes: %w[href class style]
    ).html_safe
  end

end
