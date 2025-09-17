class AdministradoresController < ApplicationController

  def index
    @administradores = Admin.all
  end

  def new
    @admin = Admin.new
  end

  def create
    @admin = Admin.new(admin_params)
    if @admin.save
      redirect_to administradores_path, notice: "Administrador salvo com sucesso!"
    else
      flash.now[:alert] = "Falha ao salvar administrador"
      render :new, status: :unprocessable_entity
    end
  end

  private

  def admin_params
    params.require(:admin).permit(:email, :nome, :password, :password_confirmation)
  end
end
