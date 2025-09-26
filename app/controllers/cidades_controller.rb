class CidadesController < ApplicationController
  before_action :set_estado

  def index
    @cidades = @estado.cidades.order(:nome)
  end

  private

  def set_estado
    @estado = Estado.find(params[:estado_id])
  end
end
