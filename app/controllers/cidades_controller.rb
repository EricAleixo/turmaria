class CidadesController < ApplicationController
  layout "dashboard"

  before_action :carregar_estado, only: [:index, :new, :edit, :destroy, :confirm_delete, :create, :update, :show]
  before_action :carregar_cidade, only: [:edit, :update, :destroy, :confirm_delete, :show]
  
  def index
    @cidades = @estado.cidades.order(:nome)
  end

  def new
    @cidade = @estado.cidades.new
  end

  def show
       @cidade = Cidade.find(params[:id])
  @estado = @cidade.estado
  render :show
  end

  def admin_index
      @cidades = Cidade.includes(:estado).order('cidades.nome')
  end

  def admin_show
    @cidade = Cidade.find(params[:id])
    @estado = @cidade.estado
    render :show
  end

  def admin_new
    @cidade = Cidade.new
  end

  def admin_create
    @cidade = Cidade.new(cidade_params_admin)
    if @cidade.save
      redirect_to @cidade, notice: 'Cidade criada com sucesso!'
    else
      @estados = Estado.order(:nome)
      render :admin_new
    end
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

  def cidade_params_admin
    params.require(:cidade).permit(:nome, :estado_id)
  end
end
