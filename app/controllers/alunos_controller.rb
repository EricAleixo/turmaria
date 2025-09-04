class AlunosController < ApplicationController
  before_action :set_escola
  before_action :set_turma
  before_action :set_aluno, only: %i[show edit update destroy]

  # GET /escolas/:escola_id/turmas/:turma_id/alunos or /escolas/:escola_id/turmas/:turma_id/alunos.json
  def index
    @alunos = @turma.alunos
  end

  # GET /escolas/:escola_id/turmas/:turma_id/alunos/1 or /escolas/:escola_id/turmas/:turma_id/alunos/1.json
  def show
  end

  # GET /escolas/:escola_id/turmas/:turma_id/alunos/new
  def new
    @aluno = @turma.alunos.build
  end

  # GET /escolas/:escola_id/turmas/:turma_id/alunos/1/edit
  def edit
  end

  # POST /escolas/:escola_id/turmas/:turma_id/alunos or /escolas/:escola_id/turmas/:turma_id/alunos.json
  def create
    @aluno = @turma.alunos.build(aluno_params)

    respond_to do |format|
      if @aluno.save
        format.html { redirect_to [@escola, @turma, @aluno], notice: "Aluno foi criado com sucesso." }
        format.json { render :show, status: :created, location: [@escola, @turma, @aluno] }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @aluno.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /escolas/:escola_id/turmas/:turma_id/alunos/1 or /escolas/:escola_id/turmas/:turma_id/alunos/1.json
  def update
    respond_to do |format|
      if @aluno.update(aluno_params)
        format.html { redirect_to [@escola, @turma, @aluno], notice: "Aluno foi atualizado com sucesso." }
        format.json { render :show, status: :ok, location: [@escola, @turma, @aluno] }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @aluno.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /escolas/:escola_id/turmas/:turma_id/alunos/1 or /escolas/:escola_id/turmas/:turma_id/alunos/1.json
  def destroy
    @aluno.destroy!

    respond_to do |format|
      format.html { redirect_to escola_turma_alunos_path(@escola, @turma), status: :see_other, notice: "Aluno foi excluído com sucesso." }
      format.json { head :no_content }
    end
  end

  private

  def set_escola
    @escola = Escola.find(params[:escola_id])
  end

  def set_turma
    @turma = @escola.turmas.find(params[:turma_id])
  end

  def set_aluno
    @aluno = @turma.alunos.find(params[:id])
  end

  def aluno_params
    params.require(:aluno).permit(:nome, :data_nascimento)
  end
end
