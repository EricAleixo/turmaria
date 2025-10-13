class CidadesController < ApplicationController
  before_action :carregar_estado
  before_action :carregar_cidade, only: [:edit, :update, :destroy, :confirm_delete]

  def index
    @cidades = @estado.cidades.order(:nome)
  end

  def new
    @cidade = @estado.cidades.new
  end

  def create
    @cidade = @estado.cidades.new(cidade_params)

    if @cidade.save
      redirect_to estado_cidades_path(@estado)
    else
      render :new
    end
  end

  def edit
    # apenas renderiza o formulário
  end

  def update
    if @cidade.update(cidade_params)
      redirect_to estado_cidades_path(@estado)
    else
      render :edit
    end
  end

  def confirm_delete
    # só renderizar a página de confirmação
  end

  def destroy
    @cidade.destroy
    redirect_to estado_cidades_path(@estado)
  end

  private

  def carregar_estado
    @estado = Estado.find(params[:estado_id])
  end

  def carregar_cidade
    @cidade = @estado.cidades.find(params[:id])
  end

  def cidade_params
    params.require(:cidade).permit(:nome)
  end
end
