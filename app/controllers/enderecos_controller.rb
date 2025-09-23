class EnderecosController < ApplicationController
  def index
    @enderecos = Endereco.all
  end

  def show
    @endereco = Endereco.find(params[:id])
  end
end