class AlunosController < ApplicationController
  before_action :set_escola
  before_action :set_turma, only: [:index, :show, :new, :create, :edit, :update, :destroy]
  before_action :set_aluno, only: [:show, :edit, :update, :destroy]

  def index
    if @turma
      # Quando estamos no contexto de uma turma, mostra apenas os alunos dessa turma
      @alunos = @turma.alunos.includes(:endereco)
      @allocated_alunos = @alunos
      @unallocated_alunos = []
    else
      # Quando estamos no contexto da escola, mostra todos os alunos da escola
      @alunos = Aluno.where(escola_id: @escola.id).includes(:turma, :endereco)
      @allocated_alunos = @alunos.select { |a| a.turma_id.present? }
      @unallocated_alunos = @alunos.select { |a| a.turma_id.nil? }
    end
  end

  def show
  end

  def new
    @aluno = @escola.alunos.build
    @aluno.build_endereco
  end

  def create
    @aluno = @escola.alunos.build(aluno_params)
    @aluno.turma = @turma if @turma

    if @aluno.save
      redirect_path = @turma ? escola_turma_alunos_path(@escola, @turma) : escola_alunos_path(@escola)
      redirect_to redirect_path, notice: 'Aluno criado com sucesso.'
    else
      @aluno.build_endereco unless @aluno.endereco
      render :new, status: :unprocessable_entity
    end
  end

  # GET /escolas/:escola_id/turmas/:turma_id/alunos/1/edit
  def edit
  end


  def update
    if @aluno.update(aluno_params)
      redirect_path = @turma ? escola_turma_aluno_path(@escola, @turma, @aluno) : escola_aluno_path(@escola, @aluno)
      redirect_to redirect_path, notice: 'Aluno atualizado com sucesso.'
    else
      render :edit, status: :unprocessable_entity
    end
  end


  def destroy
    @aluno.destroy
    redirect_path = @turma ? escola_turma_alunos_path(@escola, @turma) : escola_alunos_path(@escola)
    redirect_to redirect_path, notice: 'Aluno removido com sucesso.'
  end

  def assign_to_turma
    @turma = @escola.turmas.find(params[:turma_id])
    @aluno = @escola.alunos.find(params[:id])
    
    if @aluno.update(turma: @turma)
      redirect_to escola_turma_alunos_path(@escola, @turma), 
                  notice: "#{@aluno.nome} foi alocado para a turma #{@turma.nome}."
    else
      redirect_to escola_alunos_path(@escola), 
                  alert: 'Erro ao alocar aluno para a turma.'
    end
  end

  def remove_from_turma
    @aluno = @escola.alunos.find(params[:id])
    turma_nome = @aluno.turma&.nome
    
    if @aluno.update(turma: nil)
      redirect_to escola_alunos_path(@escola), 
                  notice: "#{@aluno.nome} foi removido da turma #{turma_nome}."
    else
      redirect_to request.referer || escola_alunos_path(@escola), 
                  alert: 'Erro ao remover aluno da turma.'
    end
  end

  private

  def set_escola
    @escola = Escola.find(params[:escola_id])
  end

  def set_turma
    @turma = @escola.turmas.find(params[:turma_id]) if params[:turma_id]
  end

  def set_aluno
    if @turma
      @aluno = @turma.alunos.find(params[:id])
    else
      @aluno = @escola.alunos.find(params[:id])
    end
  end

  def aluno_params
    params.require(:aluno).permit(:nome, :data_nascimento, :turma_id, :escola_id,
                                  endereco_attributes: [:id, :logradouro, :numero, :bairro, :cidade, :estado, :cep, :_destroy])
  end
end
