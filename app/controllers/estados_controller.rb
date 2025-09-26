class EstadosController < ApplicationController
  def index
    @estados = Estado.order(:nome)
  end

  def show
    @estado = Estado.find(params[:id])
  end

  def new
    @estado = Estado.new
  end

  def create
    @estado = Estado.new(estado_params)
    if @estado.save
      redirect_to estados_path
    else
      render :new
    end
  end

def update
  @estado = Estado.find(params[:id])
  if @estado.update(estado_params)
    redirect_to estados_path
  else
    render :edit
  end
end


  def edit
  @estado = Estado.find(params[:id])
end

  def confirm_delete
    @estado = Estado.find(params[:id])
  end

  def destroy
  @estado = Estado.find(params[:id])
  @estado.destroy

  redirect_to estados_path
end



  private

  def estado_params
    params.require(:estado).permit(:nome, :sigla, :regiao)
  end
end
