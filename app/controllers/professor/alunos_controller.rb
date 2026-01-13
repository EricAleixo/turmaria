class Professor::AlunosController < Professor::ApplicationController
  layout 'dashboard'
  
  # Ação SHOW exige que a turma seja definida (para escopo aninhado)
  # ATENÇÃO: Se for usar resources :alunos, only: [:show] no routes, a rota não é aninhada. 
  # Se for aninhada, precisamos do set_turma.
  # Vamos manter a sua lógica aninhada para show, que é mais segura, mas exige a rota aninhada.
  before_action :set_turma_and_aluno, only: [:show] # <-- NOVO: Combina a segurança para a rota aninhada

  # -------------------------------
  # INDEX (Condicional: Global OU Por Turma)
  # -------------------------------
  # GET /professor/alunos (Sidebar)  OU  /professor/turmas/:turma_id/alunos
  def index
    if params[:turma_id].present?
      # --- LÓGICA ANINHADA (Lista de alunos de UMA turma específica) ---
      set_turma 
      @alunos = @turma.alunos.order(:nome).includes(:escola, :turma)
      
      # *** ADICIONA A LÓGICA DE PESQUISA POR NOME AQUI (Se o usuário estiver filtrando por uma turma) ***
      if params[:search].present?
        search_term = "%#{params[:search].downcase}%"
        @alunos = @alunos.where("LOWER(alunos.nome) LIKE ?", search_term)
      end
      
      render :index
    else
      # --- LÓGICA GLOBAL (Lista de todos os alunos do professor - Sidebar) ---
      
      # 1. Busca os IDs de todas as turmas do professor logado
      turma_ids = current_professor.turmas.pluck(:id)
      
      # 2. Busca todos os alunos nessas turmas (Query inicial)
      @alunos = Aluno.where(turma_id: turma_ids)
                     .order(:nome)
                     .includes(:escola, :turma)
                     
      # --- LÓGICA DE FILTRO E PESQUISA GLOBAL ---
      
      # 1. Filtro por Turma
      if params[:turma].present? && params[:turma] != 'todos'
        # Garante que o professor não está tentando filtrar por uma turma que não é dele
        if turma_ids.include?(params[:turma].to_i)
            @alunos = @alunos.where(turma_id: params[:turma])
        end
      end
      
      # 2. Pesquisa por Nome (Barra de Pesquisa)
      if params[:search].present?
        search_term = "%#{params[:search].downcase}%"
        # Adiciona a condição WHERE na query
        @alunos = @alunos.where("LOWER(alunos.nome) LIKE ?", search_term) 
      end

      # Define variáveis como nil para evitar erros na view
      @turma = nil
      @escola = nil

      # Renderiza a view de lista global (index_geral.html.erb)
      render :index_geral
    end
  end

  # GET /professor/turmas/:turma_id/alunos/:id
  def show
    # @aluno e @turma já estão definidos e seguros pelo before_action :set_turma_and_aluno
    # Lógica adicional aqui, se houver
  end
  
  
  # -------------------------------
  # PRIVATE METHODS
  # -------------------------------
  private

  # Setar a turma é crucial para a segurança das rotas aninhadas
  def set_turma
    # ⚠️ A segurança é aplicada aqui: só busca turmas que o professor pertence
    @turma = current_professor.turmas.find(params[:turma_id])
  rescue ActiveRecord::RecordNotFound
    # Impede que o professor acesse turmas que não são dele
    redirect_to professor_turmas_path, alert: "Turma não encontrada ou você não tem acesso a ela."
  end

  # Método para garantir a segurança da rota SHOW (aninhada: turma/aluno)
  def set_turma_and_aluno
    set_turma
    # Garante que o aluno pertence à turma correta (já segura via @turma)
    @aluno = @turma.alunos.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to professor_turma_alunos_path(@turma), alert: "Aluno não encontrado ou não pertence a esta turma."
  end

  # Os parâmetros não são usados para Professor, mas são boas práticas para ter no Controller
  def aluno_params
    # O professor DEVE apenas ter acesso de leitura, então este método não será chamado.
    # Se precisar de update, você precisa criar uma rota e ação específicas, 
    # mas mantenha-o aqui como referência.
    params.require(:aluno).permit(:nome, :email, :telefone) 
  end
end