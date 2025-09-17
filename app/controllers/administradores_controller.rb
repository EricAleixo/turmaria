class AdministradoresController < ApplicationController

  def index
    @administradores = Admin.all
  end

  def new
    @administrador = Admin.new
  end

  def create
  end

end
