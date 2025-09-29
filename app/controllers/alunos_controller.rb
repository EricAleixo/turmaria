class AlunosController < ApplicationController
  layout 'dashboard'
  before_action :authenticate_all_users!

  before_action :set_escola
  before_action :set_turma, only: [:index, :new, :create, :edit, :update, :destroy]
  before_action :set_aluno, only: [:show, :edit, :update, :destroy]

  # ... (todas as suas outras ações index, show, new, create, etc. ficam inalteradas)
  def index
    if super_admin_signed_in? && @escola.nil?
      @alunos = Aluno.includes(:escola, :turma).all
      @allocated_alunos = @alunos.select(&:turma_id)
      @unallocated_alunos = @alunos.reject(&:turma_id)
    elsif @turma
      @alunos = @turma.alunos
      @allocated_alunos = @alunos
      @unallocated_alunos = []
    else
      @alunos = Aluno.where(escola_id: @escola.id).includes(:turma)
      @allocated_alunos = @alunos.select { |a| a.turma_id.present? }
      @unallocated_alunos = @alunos.select { |a| a.turma_id.nil? }
    end
  end

  def show
  end

  def new
    @aluno = @escola.alunos.build
  end

  def create
    @aluno = @escola.alunos.build(aluno_params)
    @aluno.turma = @turma if @turma

    respond_to do |format|
      if @aluno.save
        format.html { redirect_to [@escola, @aluno], notice: "Aluno criado com sucesso." }
        format.json { render json: { success: true, message: "Aluno salvo com sucesso!" }, status: :created }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { errors: @aluno.errors.messages }, status: :unprocessable_entity }
      end
    end
  end

  def edit
  end

  def update
  respond_to do |format|
      if @aluno.update(aluno_params)
        format.html { 
          redirect_path = @turma ? escola_turma_aluno_path(@escola, @turma, @aluno) : escola_aluno_path(@escola, @aluno)
          redirect_to redirect_path, notice: 'Aluno atualizado com sucesso.'
        }
        format.json { render json: { success: true, message: 'Aluno atualizado com sucesso!' }, status: :ok }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { errors: @aluno.errors.messages }, status: :unprocessable_entity }
      end
    end
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

  def authenticate_all_users!
    unless super_admin_signed_in? || admin_signed_in? || coordenador_signed_in? || professor_signed_in?
      redirect_to new_user_session_path, alert: 'Acesso negado. Faça login como administrador, professor ou coordenador.'
    end
  end

  def set_escola
    if super_admin_signed_in?
      @escola= Escola.find(params[:escola_id]) if params[:escola_id].present?
    else
      @escola = Escola.find(params[:escola_id])
    end
  end
  
  def set_turma
    @turma = @escola.turmas.find(params[:turma_id]) if params[:turma_id].present?
  end

  def set_aluno
    if super_admin_signed_in?
      @aluno = Aluno.find(params[:id])
      @escola = @aluno.escola
      @turma = @aluno.turma
    elsif @turma
      @aluno = @turma.alunos.find(params[:id])
    else
      @aluno = @escola.alunos.find(params[:id])
    end
  end

  def aluno_params
  params.require(:aluno).permit(
    :escola_id, 
    :turma_id, 
    :data_nascimento, 
    :nome, 
    :email, 
    :telefone, 
    :responsavel_1, 
    :telefone_responsavel_1, 
    :responsavel_2, 
    :telefone_responsavel_2, 
    :idade, 
    :cpf, 
    :rg, 
    :sexo, 
    :cor, 
    :tipo_sanguinio, 
    :observacoes_pcd, 
    necessidades_especiais_tipo: [], # ALTERADO: Permite a string como parâmetro
    cpf_url: [], 
    comprovante_residencia_url: [], 
    historico_academico_url: []
  ).tap do |whitelisted_params|
        # Lógica para converter string em array, se necessário
        if whitelisted_params[:necessidades_especiais_tipo].is_a?(String)
          whitelisted_params[:necessidades_especiais_tipo] = whitelisted_params[:necessidades_especiais_tipo].split(',').map(&:strip)
        end

        # -------------------------------------------------------------------
        # >> Lógica para definir "Nenhuma" se o array estiver vazio <<
        # -------------------------------------------------------------------
        if whitelisted_params[:necessidades_especiais_tipo].blank?
          whitelisted_params[:necessidades_especiais_tipo] = ["Nenhuma"]
        end
    end
  end
end
