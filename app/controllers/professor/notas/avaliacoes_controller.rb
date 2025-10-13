# app/controllers/professor/notas/avaliacoes_controller.rb
class Professor::Notas::AvaliacoesController < Professor::BaseController
  layout 'dashboard'
  before_action :authenticate_professor!


  before_action :set_turma_disciplina
  before_action :set_avaliacao_configuracao, only: [:edit, :update, :destroy]

  # GET /professor/turmas/:turma_id/disciplinas/:disciplina_id/notas/avaliacoes
  def index
    # Lista todas as configurações de avaliação (colunas de nota) para a disciplina/turma
    @avaliacoes = @disciplina.avaliacoes_configuracoes
                              .where(turma: @turma)
                              .order(:bimestre, :ordem)
  end

  # GET /professor/turmas/:turma_id/disciplinas/:disciplina_id/notas/avaliacoes/new
  def new
    @avaliacao_configuracao = AvaliacaoConfiguracao.new
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
      render :new, status: :unprocessable_entity
    end
  end
  
  # ... (Métodos edit, update, destroy seguem a mesma lógica)

  private

  def set_turma_disciplina
    @turma = Turma.find(params[:turma_id])
    @disciplina = Disciplina.find(params[:disciplina_id])
    # **IMPORTANTE**: Adicionar validação de autorização (se o professor leciona essa disciplina/turma)
  end

  def set_avaliacao_configuracao
    @avaliacao_configuracao = AvaliacaoConfiguracao.find(params[:id])
  end

  def avaliacao_configuracao_params
    params.require(:avaliacao_configuracao).permit(:nome, :bimestre, :is_recuperacao, :ordem)
  end
end
