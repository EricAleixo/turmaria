class Professor::PlanosDeEnsinoController < ApplicationController
  layout "dashboard"

  before_action :set_plano_de_ensino, only: %i[show edit update destroy]
  before_action :set_turmas_e_disciplinas, only: %i[new edit create update]

  # GET /professor/planos_de_ensino
  def index
    planos = current_professor.planos_de_ensino
                               .includes(:turma, :disciplina, turma: :ano_letivo)

    if params[:q].present?
      termo = "%#{params[:q].strip.downcase}%"
      planos = planos.joins(:disciplina, :turma)
                      .where(
                        "LOWER(disciplinas.nome) LIKE :t OR LOWER(turmas.nome) LIKE :t OR LOWER(planos_de_ensino.ementa) LIKE :t",
                        t: termo
                      )
    end

    planos = planos.where(disciplina_id: params[:disciplina_id]) if params[:disciplina_id].present?
    planos = planos.where(turma_id: params[:turma_id]) if params[:turma_id].present?
    planos = planos.where(status: params[:status]) if params[:status].present?

    if params[:ano_letivo_id].present?
      planos = planos.joins(turma: :ano_letivo).where(ano_letivos: { id: params[:ano_letivo_id] })
    end

    # Contadores do resumo sempre olham pra TODOS os planos do professor,
    # não só pra página filtrada — pra não mudar o painel de resumo quando filtra.
    @total_planos = current_professor.planos_de_ensino.count
    @total_publicados = current_professor.planos_de_ensino.publicado.count
    @total_em_elaboracao = current_professor.planos_de_ensino.em_elaboracao.count
    @total_rascunhos = current_professor.planos_de_ensino.rascunho.count

    @page = [params[:page].to_i, 1].max
    @per_page = 10
    @total_filtrado = planos.count
    @planos_de_ensino = planos.order(updated_at: :desc)
                               .offset((@page - 1) * @per_page)
                               .limit(@per_page)

    # Opções pros selects de filtro — só o que pertence ao professor logado
    @turmas_filtro = current_professor.turmas.order(:nome)
    @disciplinas_filtro = current_professor.disciplinas.order(:nome)
    @anos_letivos_filtro = AnoLetivo.where(id: current_professor.turmas.select(:ano_letivo_id)).distinct
  end

  # GET /professor/planos_de_ensino/:id
  def show
  end

  # GET /professor/planos_de_ensino/new
  def new
    @plano_de_ensino = current_professor.planos_de_ensino.new
  end

  # POST /professor/planos_de_ensino
  def create
    @plano_de_ensino = current_professor.planos_de_ensino.new(plano_de_ensino_params)

    if @plano_de_ensino.save
      redirect_to professor_plano_de_ensino_path(@plano_de_ensino), notice: "Plano de ensino criado com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /professor/planos_de_ensino/:id/edit
  def edit
  end

  # PATCH/PUT /professor/planos_de_ensino/:id
  def update
    if @plano_de_ensino.update(plano_de_ensino_params)
      redirect_to professor_plano_de_ensino_path(@plano_de_ensino), notice: "Plano de ensino atualizado com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /professor/planos_de_ensino/:id
  def destroy
    @plano_de_ensino.destroy
    redirect_to professor_planos_de_ensino_path, notice: "Plano de ensino removido com sucesso.", status: :see_other
  end

  private

  def set_plano_de_ensino
    @plano_de_ensino = current_professor.planos_de_ensino.find(params[:id])
  end

  # Turmas/Disciplinas do próprio professor, pra popular os selects do form
  # sem permitir escolher algo de outro professor.
  def set_turmas_e_disciplinas
    @turmas = current_professor.turmas.includes(:ano_letivo).order(:nome)
    @disciplinas = current_professor.disciplinas.order(:nome)
  end

  def plano_de_ensino_params
    params.require(:plano_de_ensino).permit(
      # Cadastro do plano
      :turma_id,
      :disciplina_id,
      :bimestre,
      :status,
      :curso,
      # Informações do plano
      :ementa,
      :objetivos_gerais,
      :objetivos_especificos,
      :competencias,
      :habilidades,
      :conteudos_programaticos,
      :metodologia,
      :recursos_didaticos,
      :criterios_avaliacao,
      :cronograma_unidades,
      :bibliografia_basica,
      :bibliografia_complementar,
      :observacoes
    )
  end
end