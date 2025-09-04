class EscolasController < ApplicationController
  before_action :set_escola, only: %i[show edit update destroy]

  def index
    @escolas = Escola.all
  end

  def show
  end

  def new
    @escola = Escola.new
  end

  def edit
  end

  def create
    @escola = Escola.new(escola_params)

    respond_to do |format|
      if @escola.save
        format.html { redirect_to @escola, notice: "Escola foi criada com sucesso." }
        format.json { render :show, status: :created, location: @escola }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @escola.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @escola.update(escola_params)
        format.html { redirect_to @escola, notice: "Escola foi atualizada com sucesso." }
        format.json { render :show, status: :ok, location: @escola }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @escola.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @escola.destroy!

    respond_to do |format|
      format.html { redirect_to escolas_path, status: :see_other, notice: "Escola foi excluída com sucesso." }
      format.json { head :no_content }
    end
  end

  private

  def set_escola
    @escola = Escola.find(params[:id])
  end

  def escola_params
    params.require(:escola).permit(:nome, :cnpj)
  end
end
