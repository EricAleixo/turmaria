class TurmasController < ApplicationController
  before_action :set_escola
  before_action :set_turma, only: %i[show edit update destroy]

  # GET /escolas/:escola_id/turmas or /escolas/:escola_id/turmas.json
  def index
    @turmas = @escola.turmas
  end

  # GET /escolas/:escola_id/turmas/1 or /escolas/:escola_id/turmas/1.json
  def show
  end

  # GET /escolas/:escola_id/turmas/new
  def new
    @turma = @escola.turmas.build
  end

  # GET /escolas/:escola_id/turmas/1/edit
  def edit
  end

  # POST /escolas/:escola_id/turmas or /escolas/:escola_id/turmas.json
  def create
    @turma = @escola.turmas.build(turma_params)

    respond_to do |format|
      if @turma.save
        format.html { redirect_to [@escola, @turma], notice: "Turma foi criada com sucesso." }
        format.json { render :show, status: :created, location: [@escola, @turma] }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @turma.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /escolas/:escola_id/turmas/1 or /escolas/:escola_id/turmas/1.json
  def update
    respond_to do |format|
      if @turma.update(turma_params)
        format.html { redirect_to [@escola, @turma], notice: "Turma foi atualizada com sucesso." }
        format.json { render :show, status: :ok, location: [@escola, @turma] }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @turma.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /escolas/:escola_id/turmas/1 or /escolas/:escola_id/turmas/1.json
  def destroy
    @turma.destroy!

    respond_to do |format|
      format.html { redirect_to escola_turmas_path(@escola), status: :see_other, notice: "Turma foi excluída com sucesso." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_escola
      @escola = Escola.find(params[:escola_id])
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_turma
      @turma = @escola.turmas.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def turma_params
      params.require(:turma).permit(:nome, :serie, :turno)
    end
end
