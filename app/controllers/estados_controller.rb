class EstadosController < ApplicationController
  def index
    @estados = Estado.order(:nome)# Ordena pelo campo logradouro, por exemplo
  end

  def show
    @estados = Estado.find(params[:id])
  end

  # Se quiser criar, editar ou deletar, pode adicionar os métodos abaixo:
  # def new
  #   @endereco = Endereco.new
  # end

  # def create
  #   @endereco = Endereco.new(endereco_params)
  #   if @endereco.save
  #     redirect_to enderecos_path, notice: 'Endereço criado com sucesso.'
  #   else
  #     render :new
  #   end
  # end

  private

  def endereco_params
    params.require(:endereco).permit(:logradouro, :bairro, :cidade_id, :estado_id, :cep)
  end
end