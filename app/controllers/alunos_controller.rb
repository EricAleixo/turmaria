class AlunosController < ApplicationController
    layout 'dashboard'
    before_action :authenticate_all_users!

    before_action :set_escola
    before_action :set_turma, only: [:index, :new, :create, :edit, :update, :destroy]
    before_action :set_aluno, only: [:show, :edit, :update, :destroy]

    # -------------------------------
    # INDEX (Adaptado para Busca e Filtros)
    # -------------------------------
    def index
        # 1. Base da Query
        if super_admin_signed_in? && @escola.nil?
            alunos_scope = Aluno.all.includes(:escola, :turma)
        elsif @turma
            alunos_scope = @turma.alunos.includes(:escola)
        else
            # Sempre retorna os alunos da @escola (que não é nil se não for super_admin)
            alunos_scope = Aluno.where(escola_id: @escola.id).includes(:turma, :escola)
        end

        # 2. Aplicar Busca por Nome ou Matrícula
        if params[:busca].present?
            alunos_scope = alunos_scope.where("LOWER(alunos.nome) LIKE :busca OR LOWER(alunos.matricula) LIKE :busca", busca: "%#{params[:busca].downcase}%")
        end

        # 3. Aplicar Filtros do Modal (Baseado no layout de Professores/Index)
        # NOTA: O status é um método dinâmico (status_aluno), então o filtro deve ser feito em Ruby.
        
        # Filtros do modal (Ex: Turma)
        if params[:filtros_turma].present?
          alunos_scope = alunos_scope.where(turma_id: params[:filtros_turma])
        end

        # Execute a query base e depois filtre em Ruby se necessário (para o status_aluno)
        @alunos = alunos_scope.order(nome: :asc)
        
        # 4. Filtragem por Status (Feito em Ruby por ser um método dinâmico)
        if params[:filtros_status].present?
            # Mapeia os filtros de status: "alocado" ou "pendente de alocacao"
            @alunos = @alunos.select do |aluno|
                params[:filtros_status].include?(aluno.status_aluno.downcase.gsub(' ', '_'))
            end
        end

        # Para compatibilidade com o layout anterior (opcional)
        @allocated_alunos = @alunos.select { |a| a.turma_id.present? }
        @unallocated_alunos = @alunos.select { |a| a.turma_id.nil? }
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
        # ... (Mantido o código de debug) ...
        Rails.logger.info "================================="

        respond_to do |format|
            if @aluno.save
                # Verificar após salvar
                Rails.logger.info "Após salvar - Foto: #{@aluno.foto.attached?}"
                # ... (Mantido o código de debug) ...
                
                format.html { redirect_to [@escola, @aluno], notice: "Aluno criado com sucesso." }
                format.json { render json: { success: true, message: "Aluno salvo com sucesso!" }, status: :created }
            else
                # Se falhar aqui, o erro deve vir do modelo (ex: cidade_id não preenchido)
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
    :cidade_id,
    necessidades_especiais_tipo: [], 
    cpf_documento: [],              # Array de arquivos
    comprovante_residencia: []      # Array de arquivos
  ).tap do |whitelisted_params|
    # Tratamento de string vazia para cidade_id
    if whitelisted_params[:cidade_id].blank?
      whitelisted_params[:cidade_id] = nil
    end

    # Converter string em array para necessidades especiais
    if whitelisted_params[:necessidades_especiais_tipo].is_a?(String)
      whitelisted_params[:necessidades_especiais_tipo] = whitelisted_params[:necessidades_especiais_tipo].split(',').map(&:strip)
    end

    # Se vazio, define como "Nenhuma"
    if whitelisted_params[:necessidades_especiais_tipo].blank?
      whitelisted_params[:necessidades_especiais_tipo] = ["Nenhuma"]
    end
    
    # ⭐ NOVO: Remove arrays vazios de arquivos
    if whitelisted_params[:cpf_documento].is_a?(Array)
      whitelisted_params[:cpf_documento] = whitelisted_params[:cpf_documento].reject(&:blank?)
      whitelisted_params.delete(:cpf_documento) if whitelisted_params[:cpf_documento].empty?
    end
    
    if whitelisted_params[:comprovante_residencia].is_a?(Array)
      whitelisted_params[:comprovante_residencia] = whitelisted_params[:comprovante_residencia].reject(&:blank?)
      whitelisted_params.delete(:comprovante_residencia) if whitelisted_params[:comprovante_residencia].empty?
    end
  end
end
end