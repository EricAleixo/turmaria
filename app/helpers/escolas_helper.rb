module EscolasHelper
    def escolas_menager_paths
      if current_admin.present?
        return minhas_escolas_admin_path

      elsif current_super_admin.present?
        return escolas_path
      end
    end

    def escola_section_active?
      current_page?(minhas_escolas_admin_path) || (controller_name == 'escolas' && action_name.in?(%w[index show edit new]))
    end
end

