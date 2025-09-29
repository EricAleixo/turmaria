class CidadesController < ApplicationController
  before_action :carregar_estado

  def index
    # Busca as cidades relacionadas ao estado, ordenadas pelo nome
    @cidades = @estado.cidades.order(:nome)
  end

  private

  def carregar_estado
    # Busca o estado pelo ID passado na URL
    @estado = Estado.find(params[:estado_id])
  end
end
