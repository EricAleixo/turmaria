class AlunosController < ApplicationController
  layout 'dashboard'
  before_action :authenticate_all_users!

  before_action :set_escola
  before_action :set_turma, only: [:index, :new, :create, :edit, :update, :destroy]
  before_action :set_aluno, only: [:show, :edit, :update, :destroy]

  # -------------------------------
  # INDEX
  # -------------------------------
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


  def index_geral
    # 1. Busca os IDs de todas as turmas que o professor leciona
    turma_ids = current_user.turmas.pluck(:id)
    
    # 2. Busca todos os alunos nessas turmas
    @alunos_gerais = Aluno.where(turma_id: turma_ids)
                          .order(:nome)
                          .includes(:turma) 
                          
    # Renderiza a nova view
    render :index_geral
  end

  # -------------------------------
  # SHOW
  # -------------------------------
  def show
  end

  # -------------------------------
  # NEW
  # -------------------------------
  def new
    @aluno = @escola.alunos.build
  end

  # -------------------------------
  # CREATE
  # -------------------------------
  def create
    @aluno = @escola.alunos.build(aluno_params)
    @aluno.turma = @turma if @turma

    # Debug: Verificar o que está sendo recebido
    Rails.logger.info "========== DEBUG ALUNO =========="
    Rails.logger.info "Foto attached: #{params[:aluno][:foto].present?}"
    Rails.logger.info "CPF Documento attached: #{params[:aluno][:cpf_documento].present?}"
    Rails.logger.info "Comprovante attached: #{params[:aluno][:comprovante_residencia].present?}"
    Rails.logger.info "Historico attached: #{params[:aluno][:historico_academico].present?}"
    Rails.logger.info "================================="

    respond_to do |format|
      if @aluno.save
        # Verificar após salvar
        Rails.logger.info "Após salvar - Foto: #{@aluno.foto.attached?}"
        Rails.logger.info "Após salvar - CPF Doc: #{@aluno.cpf_documento.attached?}"
        Rails.logger.info "Após salvar - Comprovante: #{@aluno.comprovante_residencia.attached?}"
        Rails.logger.info "Após salvar - Historico: #{@aluno.historico_academico.attached?}"
        
        format.html { redirect_to [@escola, @aluno], notice: "Aluno criado com sucesso." }
        format.json { render json: { success: true, message: "Aluno salvo com sucesso!" }, status: :created }
      else
        Rails.logger.error "Erros: #{@aluno.errors.full_messages}"
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { errors: @aluno.errors.messages }, status: :unprocessable_entity }
      end
    end
  end

  # -------------------------------
  # EDIT
  # -------------------------------
  def edit
  end

  # -------------------------------
  # UPDATE
  # -------------------------------
  def update
    respond_to do |format|
      if @aluno.update(aluno_params)
        format.html do
          redirect_path = @turma ? escola_turma_aluno_path(@escola, @turma, @aluno) : escola_aluno_path(@escola, @aluno)
          redirect_to redirect_path, notice: 'Aluno atualizado com sucesso.'
        end
        format.json { render json: { success: true, message: 'Aluno atualizado com sucesso!' }, status: :ok }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { errors: @aluno.errors.messages }, status: :unprocessable_entity }
      end
    end
  end

  # -------------------------------
  # DESTROY
  # -------------------------------
  def destroy
    @aluno.destroy
    redirect_path = @turma ? escola_turma_alunos_path(@escola, @turma) : escola_alunos_path(@escola)
    redirect_to redirect_path, notice: 'Aluno removido com sucesso.'
  end

  # -------------------------------
  # ALOCAÇÃO DE TURMAS
  # -------------------------------
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

  # -------------------------------
  # PRIVATE METHODS
  # -------------------------------
  private

  def authenticate_all_users!
    unless super_admin_signed_in? || admin_signed_in? || coordenador_signed_in? || professor_signed_in?
      redirect_to new_user_session_path, alert: 'Acesso negado. Faça login como administrador, professor ou coordenador.'
    end
  end

    # Versão mais simples e segura do set_escola para o Controller Antigo:
  def set_escola
    if params[:escola_id].present?
      @escola = Escola.find(params[:escola_id])
    elsif super_admin_signed_in?
      # Deixe o SuperAdmin acessar sem @escola se necessário
      @escola = nil
    else
      # Redireciona todos os outros se não houver ID na URL
      raise ActiveRecord::RecordNotFound, "Couldn't find Escola without an ID"
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
      :foto,
      :historico_academico,
      :comprovante_residencia,
      necessidades_especiais_tipo: [], 
      cpf_documento: []
    ).tap do |whitelisted_params|
      # Converter string em array para necessidades especiais
      if whitelisted_params[:necessidades_especiais_tipo].is_a?(String)
        whitelisted_params[:necessidades_especiais_tipo] = whitelisted_params[:necessidades_especiais_tipo].split(',').map(&:strip)
      end

      # Se vazio, define como "Nenhuma"
      if whitelisted_params[:necessidades_especiais_tipo].blank?
        whitelisted_params[:necessidades_especiais_tipo] = ["Nenhuma"]
      end
    end
  end
end