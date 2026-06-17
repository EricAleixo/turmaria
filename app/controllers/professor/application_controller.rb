class Professor::ApplicationController < ApplicationController
  # Assume que este before_action está sendo chamado pelo Devise
  before_action :authenticate_professor!
  
  # 🔑 Adiciona a lógica para carregar a escola do professor
  before_action :set_escola

  private

  def set_escola
    # 1. Carrega a escola associada ao professor logado
    if current_professor.present? && current_professor.escola.present?
      @escola = current_professor.escola
    else
      # Se o professor logado não tiver uma escola, ou não estiver logado
      flash[:alert] = "Não foi possível identificar sua escola. Acesso restrito."
      redirect_to dashboard_path and return
    end
  end
end