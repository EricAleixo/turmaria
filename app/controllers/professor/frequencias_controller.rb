class Professor::FrequenciasController < ApplicationController
  layout 'dashboard'
  before_action :authenticate_professor!
  before_action :set_frequencia, only: [:show, :edit, :update, :destroy, :update_presencas]
  before_action :set_turma, only: [:new, :create]

  def index
    @frequencias = current_user.frequencias
                                  .includes(:turma, :frequencia_alunos, :alunos)
                                  .por_data
  end

  def show
    @frequencia_alunos = @frequencia.frequencia_alunos.includes(:aluno)
  end

  def new
    @frequencia = @turma.frequencias.build(professor: current_user, data_aula: Date.current)
    @alunos = @turma.alunos.order(:nome)
  end

  def create
    @frequencia = @turma.frequencias.build(frequencia_params)
    @frequencia.professor = current_user

    if @frequencia.save
      # Processar dados dos alunos enviados do formulário
      if params[:alunos].present?
        params[:alunos].each do |aluno_id, dados|
          @frequencia.frequencia_alunos.create!(
            aluno_id: aluno_id,
            status: dados[:status] || 'presente',
            observacoes: dados[:observacoes]
          )
        end
      else
        # Fallback: criar registros para todos os alunos como presente
        @turma.alunos.each do |aluno|
          @frequencia.frequencia_alunos.create!(
            aluno: aluno,
            status: 'presente'
          )
        end
      end

      redirect_to frequencia_path(@frequencia), notice: 'Frequência registrada com sucesso!'
    else
      @alunos = @turma.alunos.order(:nome)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @frequencia_alunos = @frequencia.frequencia_alunos.includes(:aluno).order('alunos.nome')
  end

  def update
    if @frequencia.update(frequencia_params)
      redirect_to frequencia_path(@frequencia), notice: 'Frequência atualizada com sucesso!'
    else
      @frequencia_alunos = @frequencia.frequencia_alunos.includes(:aluno).order('alunos.nome')
      render :edit, status: :unprocessable_entity
    end
  end

  def update_presencas
    if params[:frequencia_alunos].present?
      params[:frequencia_alunos].each do |id, attrs|
        frequencia_aluno = @frequencia.frequencia_alunos.find(id)
        frequencia_aluno.update(attrs.permit(:status, :observacoes))
      end
      redirect_to frequencia_path(@frequencia), notice: 'Presenças atualizadas com sucesso!'
    else
      redirect_to frequencia_path(@frequencia), alert: 'Nenhuma alteração foi feita.'
    end
  end

  def destroy
    @frequencia.destroy
    redirect_to frequencias_path, notice: 'Frequência excluída com sucesso!'
  end

  private

  def set_frequencia
    @frequencia = current_user.frequencias.find(params[:id])
  end

  def set_turma
    @turma = current_user.turmas.find(params[:turma_id])
  end

  def frequencia_params
    params.require(:frequencia).permit(:data_aula, :conteudo_trabalhado, :observacoes)
  end
end
