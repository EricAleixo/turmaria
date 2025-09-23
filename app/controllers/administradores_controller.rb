class AdministradoresController < ApplicationController
  layout 'dashboard'
  before_action :set_administrador, only: [:show, :edit, :update, :destroy]

  def index
    @administradores = Admin.all
  end

  def show
  end

  def new
    @admin = Admin.new
  end

  def create
    @admin = Admin.new(admin_params)
    if @admin.save
      redirect_to administradore_path(@admin), notice: "Administrador criado com sucesso!"
    else
      flash.now[:alert] = "Falha ao salvar administrador"
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @admin.update(admin_params_for_update)
      redirect_to administradore_path(@admin), notice: "Administrador atualizado com sucesso!"
    else
      flash.now[:alert] = "Falha ao atualizar administrador"
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @admin.destroy
    redirect_to administradores_path, notice: "Administrador removido com sucesso!"
  end

  private

  def set_administrador
    @admin = Admin.find(params[:id])
  end

  def admin_params
    params.require(:admin).permit(:email, :nome, :password, :password_confirmation)
  end

  def admin_params_for_update
    # Don't require password on update unless provided
    permitted_params = [:email, :nome]
    if params[:admin][:password].present?
      permitted_params += [:password, :password_confirmation]
    end
    params.require(:admin).permit(permitted_params)
  end
end
