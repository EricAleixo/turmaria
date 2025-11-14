# app/controllers/alunos_controller.rb

class AlunosController < ApplicationController
    # Configurações de layout e autenticação
    layout 'dashboard'
    before_action :authenticate_all_users! 

    # Configurações de callbacks de escopo
    before_action :set_escola
    before_action :set_turma, only: [:index, :new, :create, :edit, :update, :destroy]
    before_action :set_aluno, only: [:show, :edit, :update, :destroy]

    def index
        # 1. DEFINIÇÃO DO ESCOPO BASE
        alunos_scope = define_base_scope
        
        # 2. APLICAÇÃO DOS FILTROS (Delegada a um método privado)
        alunos_scope = apply_filters(alunos_scope)
        
        # 3. CONTAGEM TOTAL
        # A contagem é feita AQUI, antes da paginação.
        @alunos_count = alunos_scope.count 
        
        # 4. EXECUÇÃO DA QUERY PAGINADA
        # Eager loading, ordenação e PAGINAÇÃO (20 por página)
        @alunos = alunos_scope
                    .includes(:escola, :turma, cidade: :estado) # Adicionado :estado para evitar N+1 na listagem/filtro
                    .order(nome: :asc)
                    .page(params[:page])
                    .per(15) # Paginação de 20 alunos por página
    end

    # =====================================================================
    # ACTIONS CRUD
    # =====================================================================

    def show; end

    def new
        @aluno = @escola.alunos.build
        # Garante que @cidades_filtradas esteja disponível, se necessário
        set_cidades_filtradas 
    end

    def create
        @aluno = @escola.alunos.build(aluno_params)
        @aluno.turma = @turma if @turma

        # Remover logs de debug do código de produção/controller, a menos que essenciais
        # Rails.logger.info "========== DEBUG ALUNO ==========" 
        
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

    def edit
        # Garante que @cidades_filtradas esteja disponível, se necessário
        set_cidades_filtradas 
    end

    def update
        respond_to do |format|
            if @aluno.update(aluno_params)
                format.html do
                    # Lógica de redirecionamento unificada para melhor legibilidade
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
    # ALOCAÇÃO DE TURMAS
    # =====================================================================
    
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

    # =====================================================================
    # PRIVATE METHODS
    # =====================================================================
    private

    # Define o escopo inicial baseado na navegação (Turma > Escola > Geral)
    def define_base_scope
        if @turma
            @turma.alunos
        elsif @escola
            @escola.alunos
        else
            # Rota não aninhada sem escola_id (Acesso Super Admin)
            Aluno.all 
        end
    end
    
    # Aplica os filtros na query de Alunos
    def apply_filters(scope)
        # Filtro A: Busca Textual (Nome, Matrícula)
        scope = scope.busca_geral(params[:busca_texto]) if params[:busca_texto].present?

        # Busca por nome da Turma (Excluída se já estamos no escopo de uma turma)
        scope = scope.busca_por_nome_turma(params[:busca_turma]) if params[:busca_turma].present? && !@turma

        # Filtro B: Associação (Escola, Cidade, ESTADO - CORRIGIDO)
        scope = scope.por_escola(params[:escola_id]) if params[:escola_id].present?
        scope = scope.por_cidade(params[:cidade_id]) if params[:cidade_id].present?

        # 🛑 CORREÇÃO DO ERRO PG::UndefinedColumn 🛑
        if params[:estado_uf].present?
            # Se o scope :por_estado no model Aluno não usa 'joins(cidade: :estado)', 
            # é melhor aplicar a lógica correta aqui para garantir.
            # Assumindo que você usa associações: Aluno has_one Cidade, Cidade belongs_to Estado
            scope = scope.joins(cidade: :estado)
                         .where(estados: { sigla: params[:estado_uf] })
            set_cidades_filtradas # Define as cidades para popular o dropdown
        else
            set_cidades_filtradas # Define as cidades como vazias se nenhum estado foi selecionado
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

    # Define a variável de instância para popular o dropdown de Cidades no filtro
    def set_cidades_filtradas
        if params[:estado_uf].present?
            estado = Estado.find_by(sigla: params[:estado_uf])
            @cidades_filtradas = estado.present? ? estado.cidades.order(:nome) : []
        else
            @cidades_filtradas = []
        end
    end

    # Autenticação e Autorização
    def authenticate_all_users!
        unless super_admin_signed_in? || admin_signed_in? || coordenador_signed_in? || professor_signed_in?
            redirect_to new_user_session_path, alert: 'Acesso negado. Faça login como administrador, professor ou coordenador.'
        end
    end

    def set_escola
        # Lógica para definir @escola com base nos params ou no perfil do usuário
        if params[:escola_id].present?
            @escola = Escola.find(params[:escola_id])
        elsif super_admin_signed_in?
            @escola = nil # Super Admin pode ver todas (exceto em rotas aninhadas)
        else
            # Lógica alternativa para coordenadores/admins logados (se aplicável)
            raise ActiveRecord::RecordNotFound, "Couldn't find Escola without an ID"
        end
    end
    
    def set_turma
        @turma = @escola.turmas.find(params[:turma_id]) if params[:turma_id].present? && @escola.present?
    end

    def set_aluno
        # Simplificação da lógica de busca do aluno
        if @turma
            @aluno = @turma.alunos.find(params[:id])
            @escola = @turma.escola # Redefine @escola para garantir consistência
        elsif @escola
            @aluno = @escola.alunos.find(params[:id])
        elsif super_admin_signed_in?
            @aluno = Aluno.find(params[:id])
            @escola = @aluno.escola # Define @escola se Super Admin buscou por ID
        else
            raise ActiveRecord::RecordNotFound
        end
    end

    # Métodos auxiliares de rotas para DRY (Don't Repeat Yourself)
    def path_for_aluno_details(aluno)
        if @turma
            escola_turma_aluno_path(@escola, @turma, aluno)
        elsif @escola
            escola_aluno_path(@escola, aluno)
        else
            aluno_path(aluno) # Para Super Admin, se a rota existir
        end
    end

    def path_for_alunos_index
        if @turma
            escola_turma_alunos_path(@escola, @turma)
        elsif @escola
            escola_alunos_path(@escola)
        else
            alunos_path # Para Super Admin
        end
    end

    # Parâmetros permitidos
    def aluno_params
        params.require(:aluno).permit(
            :escola_id, 
            :turma_id, 
            # ... (seus outros parâmetros) ...
            :cidade_id,
            necessidades_especiais_tipo: [], 
            cpf_documento: []
        ).tap do |whitelisted_params|
            # Tratamento de string vazia para :cidade_id
            whitelisted_params[:cidade_id] = nil if whitelisted_params[:cidade_id].blank?

            # Tratamento de string para array (necessidades especiais)
            if whitelisted_params[:necessidades_especiais_tipo].is_a?(String)
                whitelisted_params[:necessidades_especiais_tipo] = whitelisted_params[:necessidades_especiais_tipo].split(',').map(&:strip)
            end

            # Se vazio, define como ["Nenhuma"]
            if whitelisted_params[:necessidades_especiais_tipo].blank?
                whitelisted_params[:necessidades_especiais_tipo] = ["Nenhuma"]
            end
        end
    end
end