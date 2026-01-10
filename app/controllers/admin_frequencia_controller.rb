class AdminFrequenciaController < ApplicationController

  layout "dashboard"

  def index
    @escola = Escola.find(params[:escola_id])
    @frequencias = Frequencia.all
                          .includes(:turma, :disciplina, :professor)
                          .order(data_aula: :desc, created_at: :desc)

    # Aplicar filtros se existirem
    #apply_filters

    # Paginação (se estiver usando Kaminari)
    @frequencias = @frequencias.page(params[:page]).per(20) if defined?(Kaminari)
  end

end
