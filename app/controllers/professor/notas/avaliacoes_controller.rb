class Professor::Notas::AvaliacoesController < Professor::BaseController
  layout 'dashboard'
  before_action :authenticate_professor!

  before_action :set_professor
  before_action :set_turma_disciplina
  before_action :set_avaliacao_configuracao, only: [ :edit, :update, :destroy ]

  # GET /professor/turmas/:turma_id/disciplinas/:disciplina_id/notas/avaliacoes
  def index
    @avaliacoes = @disciplina.avaliacoes_configuracoes
                             .where(turma: @turma)
                             .order(bimestre: :asc, created_at: :asc)
  end

  # GET /professor/turmas/:turma_id/disciplinas/:disciplina_id/notas/avaliacoes/new
  def new
    @avaliacao_configuracao = AvaliacaoConfiguracao.new(turma: @turma, disciplina: @disciplina)
  end

  # GET /professor/turmas/:turma_id/disciplinas/:disciplina_id/notas/avaliacoes/:id/edit
  def edit; end

  # GET /professor/turmas/:turma_id/disciplinas/:disciplina_id/notas/avaliacoes/filter_by_bimestre
  def filter_by_bimestre
    # Turmas de conceito não têm recuperação — endpoint não deve ser chamado, mas protegemos.
    if @turma.usa_conceito?
      render json: [], status: :ok and return
    end

    bimestre = params[:bimestre].to_i

    unless @turma.bimestres_disponiveis.include?(bimestre)
      render json: [], status: :ok and return
    end

    avaliacoes = AvaliacaoConfiguracao.padrao
                                      .do_bimestre(bimestre)
                                      .where(turma: @turma, disciplina: @disciplina)
                                      .order(created_at: :asc)

    render json: avaliacoes.map { |a| { id: a.id, nome: a.nome } }, status: :ok
  end

  # POST /professor/turmas/:turma_id/disciplinas/:disciplina_id/notas/avaliacoes
  def create
    @avaliacao_configuracao = AvaliacaoConfiguracao.new(avaliacao_configuracao_params)
    @avaliacao_configuracao.turma      = @turma
    @avaliacao_configuracao.disciplina = @disciplina

    if @avaliacao_configuracao.save
      redirect_to professor_turma_disciplina_notas_avaliacoes_path(@turma, @disciplina),
                  notice: "Avaliação '#{@avaliacao_configuracao.nome}' criada com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /professor/turmas/:turma_id/disciplinas/:disciplina_id/notas/avaliacoes/:id
  def update
    if @avaliacao_configuracao.update(avaliacao_configuracao_params)
      redirect_to professor_turma_disciplina_notas_avaliacoes_path(@turma, @disciplina),
                  notice: "Avaliação '#{@avaliacao_configuracao.nome}' atualizada com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /professor/turmas/:turma_id/disciplinas/:disciplina_id/notas/avaliacoes/:id
  def destroy
    nome = @avaliacao_configuracao.nome

    if @avaliacao_configuracao.destroy
      redirect_to professor_turma_disciplina_notas_avaliacoes_path(@turma, @disciplina),
                  notice: "Avaliação '#{nome}' excluída com sucesso."
    else
      redirect_to professor_turma_disciplina_notas_avaliacoes_path(@turma, @disciplina),
                  alert: "Não foi possível excluir '#{nome}'. Verifique se há notas atreladas."
    end
  end

  private

  def set_professor
    @professor = current_professor
  end

  def set_turma_disciplina
    @turma      = Turma.find(params[:turma_id])
    @disciplina = Disciplina.find(params[:disciplina_id])
    # TODO: validar autorização (professor leciona esta turma/disciplina?)
  end

  def set_avaliacao_configuracao
    @avaliacao_configuracao = AvaliacaoConfiguracao.find(params[:id])
  end

  def avaliacao_configuracao_params
    params.require(:avaliacao_configuracao).permit(
      :nome,
      :bimestre,
      :is_recuperacao,
      :avaliacao_original_id
    ).tap do |whitelisted|
      # Garante que recuperação e avaliacao_original_id nunca existam
      # em turmas de conceito, independente do que vier no payload.
      if @turma.usa_conceito?
        whitelisted[:is_recuperacao]      = false
        whitelisted[:avaliacao_original_id] = nil
      elsif whitelisted[:is_recuperacao] != '1'
        whitelisted[:avaliacao_original_id] = nil
      end
    end
  end
end