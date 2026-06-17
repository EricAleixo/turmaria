# app/controllers/professor/notas/avaliacoes_controller.rb
class Professor::Notas::AvaliacoesController < Professor::BaseController
  layout 'dashboard'
  before_action :authenticate_professor!

  before_action :set_professor
  before_action :set_turma_disciplina
  before_action :set_avaliacao_configuracao, only: [:edit, :update, :destroy]

  # GET /professor/turmas/:turma_id/disciplinas/:disciplina_id/notas/avaliacoes
  def index
    @avaliacoes = @disciplina.avaliacoes_configuracoes
                              .where(turma: @turma)
                              .order(bimestre: :asc, created_at: :asc)
  end

  def destroy
    nome_avaliacao = @avaliacao_configuracao.nome # Captura o nome antes de destruir
    
    if @avaliacao_configuracao.destroy
      # Redireciona para o index com mensagem de sucesso
      redirect_to professor_turma_disciplina_notas_avaliacoes_path(@turma, @disciplina), 
                  notice: "Configuração de avaliação '#{nome_avaliacao}' excluída com sucesso."
    else
      # Se a exclusão falhar (ex: devido a callbacks como 'before_destroy'), 
      # redireciona com um alerta de erro.
      redirect_to professor_turma_disciplina_notas_avaliacoes_path(@turma, @disciplina), 
                  alert: "Não foi possível excluir a avaliação '#{nome_avaliacao}'. Verifique se há notas atreladas."
    end
  end

  # GET /professor/turmas/:turma_id/disciplinas/:disciplina_id/notas/avaliacoes/new
  def new
    @avaliacao_configuracao = AvaliacaoConfiguracao.new(
      turma: @turma, 
      disciplina: @disciplina
    )
    # 🚨 NOTA: A lógica antiga de recuperação (prepara_avaliacoes_padrao_para_recuperacao) 
    # foi removida daqui, pois a busca agora é feita dinamicamente via AJAX/Stimulus.
  end

  # GET /professor/turmas/:turma_id/disciplinas/:disciplina_id/notas/avaliacoes/:id/edit
  def edit
    # 🚨 NOTA: A lógica antiga de recuperação (prepara_avaliacoes_padrao_para_recuperacao) 
    # foi removida daqui, pois a busca agora é feita dinamicamente via AJAX/Stimulus.
  end

  # 🚨 NOVO MÉTODO: Endpoint AJAX para o Stimulus buscar opções de recuperação 🚨
  # GET /professor/turmas/:turma_id/disciplinas/:disciplina_id/notas/avaliacoes/filter_by_bimestre
  def filter_by_bimestre
    # Garante que o parâmetro essencial exista e seja válido
    bimestre = params[:bimestre].to_i
    
    # Se o valor não for um bimestre válido (1 a 4), retorna vazio
    unless @turma.bimestres_disponiveis.include?(bimestre)
      render json: [], status: :ok and return
    end

    # Busca apenas as avaliações PADRÃO (is_recuperacao: false)
    avaliacoes = AvaliacaoConfiguracao
                   .padrao
                   .do_bimestre(bimestre)
                   .where(turma: @turma, disciplina: @disciplina)
                   .order(created_at: :asc)
    
    # Formata a lista para o JavaScript consumir (JSON)
    options = avaliacoes.map do |avaliacao|
      { id: avaliacao.id, nome: avaliacao.nome }
    end

    render json: options, status: :ok
  end
  
  # POST /professor/turmas/:turma_id/disciplinas/:disciplina_id/notas/avaliacoes
  def create
    @avaliacao_configuracao = AvaliacaoConfiguracao.new(avaliacao_configuracao_params)
    @avaliacao_configuracao.turma = @turma
    @avaliacao_configuracao.disciplina = @disciplina
    
    if @avaliacao_configuracao.save
      redirect_to professor_turma_disciplina_notas_avaliacoes_path(@turma, @disciplina), 
                  notice: "Configuração de avaliação '#{@avaliacao_configuracao.nome}' criada com sucesso."
    else
      # 🚨 REMOVIDO: A chamada prepara_avaliacoes_padrao_para_recuperacao, pois o form_with
      # falhará se não tiver as opções de select preenchidas, mas como o campo agora é dinâmico,
      # o Stimulus fará a chamada de busca se necessário após o re-render.
      render :new, status: :unprocessable_entity
    end
  end
  
  # PATCH/PUT /professor/turmas/:turma_id/disciplinas/:disciplina_id/notas/avaliacoes/:id
  def update
    if @avaliacao_configuracao.update(avaliacao_configuracao_params)
      redirect_to professor_turma_disciplina_notas_avaliacoes_path(@turma, @disciplina), 
                  notice: "Configuração de avaliação '#{@avaliacao_configuracao.nome}' atualizada com sucesso."
    else
      # 🚨 REMOVIDO: A chamada prepara_avaliacoes_padrao_para_recuperacao
      render :edit, status: :unprocessable_entity
    end
  end

  # ... (Método destroy segue a mesma lógica)

  private
    def set_professor
      @professor = current_professor 
    end

    def set_turma_disciplina
      @turma = Turma.find(params[:turma_id])
      @disciplina = Disciplina.find(params[:disciplina_id])
      # **IMPORTANTE**: Adicionar validação de autorização (se o professor leciona essa disciplina/turma)
    end

    def set_avaliacao_configuracao
      @avaliacao_configuracao = AvaliacaoConfiguracao.find(params[:id])
    end
    
    # 🚨 MÉTODO ANTIGO REMOVIDO: Não é mais necessário, pois a busca é dinâmica. 
    # def prepara_avaliacoes_padrao_para_recuperacao ... end

    def avaliacao_configuracao_params
      params.require(:avaliacao_configuracao).permit(
        :nome, 
        :bimestre, 
        :is_recuperacao, 
        :avaliacao_original_id
      ).tap do |whitelisted|
        # 🚨 CORREÇÃO: Define explicitamente como nil se não for recuperação
        unless whitelisted[:is_recuperacao] == '1'
          whitelisted[:avaliacao_original_id] = nil
        end
      end
    end
end