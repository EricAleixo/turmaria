class AlunosController < ApplicationController
    # Configurações de layout e autenticação
    layout 'dashboard'
    before_action :authenticate_all_users! 

    # Configurações de callbacks de escopo
    before_action :set_escola
    before_action :set_turma, only: [:index, :new, :create, :edit, :update, :destroy]
    before_action :set_aluno, only: [:show, :edit, :update, :destroy]
    
    # Chamada necessária para carregar as cidades no dropdown de filtro (index, new, edit)
    before_action :set_cidades_filtradas, only: [:index, :new, :edit]

    def index
        # 1. DEFINIÇÃO DO ESCOPO BASE
        alunos_scope = define_base_scope
        
        # 2. APLICAÇÃO DOS FILTROS
        alunos_scope = apply_filters(alunos_scope)
        
        # 3. CONTAGEM TOTAL
        @alunos_count = alunos_scope.count 
        
        # 4. EXECUÇÃO DA QUERY PAGINADA
        @alunos = alunos_scope
                        .includes(:escola, :turma, cidade: :estado)
                        .order(nome: :asc)
                        .page(params[:page])
                        .per(15)
    end

    # =====================================================================
    # AJAX ENDPOINTS
    # =====================================================================
    
    # Retorna as cidades em JSON para o JavaScript
    def cidades_por_estado
        # 1. Busca o Estado usando o 'id' enviado pelo AJAX (params[:estado_id])
        estado = Estado.find_by(id: params[:estado_id])

        # 2. Carrega apenas as colunas necessárias (id e nome) e ordena
        cidades = estado ? estado.cidades.select(:id, :nome).order(:nome) : []

        # 3. Responde com JSON para o frontend
        render json: cidades
    end


    # =====================================================================
    # ACTIONS CRUD
    # =====================================================================

    def show; end

    def new
        if @escola.nil?
            @aluno = Aluno.new
        else
            @aluno = @escola.alunos.build
        end
    end

    def create
        @aluno = @escola.alunos.build(aluno_params)
        @aluno.turma = @turma if @turma
        
        respond_to do |format|
            if @aluno.save
                format.html { redirect_to [@escola, @aluno], notice: "Aluno criado com sucesso." }
                format.json { render json: { success: true, message: "Aluno salvo com sucesso!" }, status: :created }
            else
                # Recarrega a lista de cidades filtradas em caso de erro de validação
                set_cidades_filtradas 
                format.html { render :new, status: :unprocessable_entity }
                format.json { render json: { errors: @aluno.errors.messages }, status: :unprocessable_entity }
            end
        end
    end

    def edit; end

    def update
        respond_to do |format|
            if @aluno.update(aluno_params)
                format.html do
                    redirect_path = path_for_aluno_details(@aluno)
                    redirect_to redirect_path, notice: 'Aluno atualizado com sucesso.'
                end
                format.json { render json: { success: true, message: 'Aluno atualizado com sucesso!' }, status: :ok }
            else
                set_cidades_filtradas 
                format.html { render :edit, status: :unprocessable_entity }
                format.json { render json: { errors: @aluno.errors.messages }, status: :unprocessable_entity }
            end
        end
    end

    def destroy
        @aluno.destroy
        redirect_path = path_for_alunos_index
        redirect_to redirect_path, notice: 'Aluno removido com sucesso.'
    end

    # =====================================================================
    # ALOCAÇÃO DE TURMAS (Inalterado)
    # =====================================================================
    
    # ... (métodos assign_to_turma e remove_from_turma inalterados) ...

    # =====================================================================
    # PRIVATE METHODS
    # =====================================================================
    private

    # Define o escopo inicial baseado na navegação
    def define_base_scope
        if @turma
            @turma.alunos
        elsif @escola
            @escola.alunos
        else
            Aluno.all 
        end
    end
    
    # 💡 AJUSTADO: Aplica os filtros na query de Alunos, usando o ID do estado
    def apply_filters(scope)
        # Filtro A: Busca Textual (Nome, Matrícula)
        scope = scope.busca_geral(params[:busca_texto]) if params[:busca_texto].present?

        # Busca por nome da Turma (Excluída se já estamos no escopo de uma turma)
        scope = scope.busca_por_nome_turma(params[:busca_turma]) if params[:busca_turma].present? && !@turma

        # Filtro B: Associação (Escola, Cidade, ESTADO)
        scope = scope.por_escola(params[:escola_id]) if params[:escola_id].present?
        
        # Filtro por CIDADE
        scope = scope.por_cidade(params[:cidade_id]) if params[:cidade_id].present?

        # Filtro por ESTADO (UF)
        # O campo :estado_uf na view agora envia o ID do estado.
        if params[:estado_uf].present?
            estado_id = params[:estado_uf] # Este é o ID do estado
            # Filtra alunos que pertencem a cidades com o estado_id correspondente
            scope = scope.joins(:cidade)
                         .where(cidades: { estado_id: estado_id }) # <--- FILTRA PELO ID
        end
        # ----------------------------------------------------------------------
        
        # Filtro C: Status de Alocação
        scope = scope.por_status_alocacao(params[:status_alocacao]) if params[:status_alocacao].present?

        # Filtro D: Idade
        if params[:idade_maior] == '1'
            scope = scope.maiores_de_18
        elsif params[:idade_menor] == '1'
            scope = scope.menores_de_18
        end

        scope
    end

    # 💡 AJUSTADO: Define a variável @cidades_filtradas para popular o dropdown de Cidades na View
    def set_cidades_filtradas
        # O params[:estado_uf] agora é o ID do estado, se selecionado no filtro
        # params[:estado_id] é usado apenas no AJAX
        estado_id_selecionado = params[:estado_uf].presence || params[:estado_id].presence
        
        if estado_id_selecionado.present?
            # Tenta buscar por ID
            estado = Estado.find_by(id: estado_id_selecionado)
            @cidades_filtradas = estado.present? ? estado.cidades.order(:nome) : []
        elsif @aluno.try(:cidade).try(:estado)
            # Caso new/edit de um aluno existente (preenche com as cidades do estado atual do aluno)
            @cidades_filtradas = @aluno.cidade.estado.cidades.order(:nome)
        else
            @cidades_filtradas = []
        end
    end

    # Autenticação e Autorização (Inalterado)
    def authenticate_all_users!
        unless super_admin_signed_in? || admin_signed_in? || coordenador_signed_in? || professor_signed_in?
            redirect_to new_user_session_path, alert: 'Acesso negado. Faça login como administrador, professor ou coordenador.'
        end
    end

    def set_escola
        # Lógica inalterada
        if params[:escola_id].present?
            @escola = Escola.find(params[:escola_id])
        elsif super_admin_signed_in?
            @escola = nil
        else
            raise ActiveRecord::RecordNotFound, "Couldn't find Escola without an ID"
        end
    end
    
    def set_turma
        # Lógica inalterada
        @turma = @escola.turmas.find(params[:turma_id]) if params[:turma_id].present? && @escola.present?
    end

    def set_aluno
        # Lógica inalterada
        if @turma
            @aluno = @turma.alunos.find(params[:id])
            @escola = @turma.escola
        elsif @escola
            @aluno = @escola.alunos.find(params[:id])
        elsif super_admin_signed_in?
            @aluno = Aluno.find(params[:id])
            @escola = @aluno.escola
        else
            raise ActiveRecord::RecordNotFound
        end
    end

    # Métodos auxiliares de rotas para DRY (inalterados)
    def path_for_aluno_details(aluno)
        if @turma
            escola_turma_aluno_path(@escola, @turma, aluno)
        elsif @escola
            escola_aluno_path(@escola, aluno)
        else
            aluno_path(aluno)
        end
    end

    def path_for_alunos_index
        if @turma
            escola_turma_alunos_path(@escola, @turma)
        elsif @escola
            escola_alunos_path(@escola)
        else
            alunos_path
        end
    end

    # Parâmetros permitidos (inalterados)
    def aluno_params
        params.require(:aluno).permit(
            :escola_id, 
            :turma_id, 
            :cidade_id,
            :nome, :data_nascimento, :idade, :cpf, :rg, :telefone, :email, :sexo, 
            :cor, :tipo_sanguinio, :observacoes_pcd, :responsavel_1, :responsavel_2, 
            :telefone_responsavel_1, :telefone_responsavel_2, :foto_url, :cpf_url, 
            :comprovante_residencia_url, :historico_academico_url, :matricula,
            :encrypted_password, :reset_password_token, :reset_password_sent_at, 
            :remember_created_at,
            necessidades_especiais_tipo: [], 
            cpf_documento: []
        ).tap do |whitelisted_params|
            whitelisted_params[:cidade_id] = nil if whitelisted_params[:cidade_id].blank?

            if whitelisted_params[:necessidades_especiais_tipo].is_a?(String)
                whitelisted_params[:necessidades_especiais_tipo] = whitelisted_params[:necessidades_especiais_tipo].split(',').map(&:strip)
            end

            if whitelisted_params[:necessidades_especiais_tipo].blank?
                whitelisted_params[:necessidades_especiais_tipo] = ["Nenhuma"]
            end
        end
    end
end