# app/controllers/planos_de_ensino_controller.rb
#
# Nested em /escolas/:escola_id/planos_de_ensino — sem module/namespace Ruby
# (é isso que te deixa livre pra usar `authorize`/`policy_scope` do jeito que
# o resto do app já usa pra admin/super_admin).
#
# ATENÇÃO: reaproveito EscolaPolicy (authorize @escola) pra decidir permissão,
# igual o EscolasController faz. Não criei uma PlanoDeEnsinoPolicy porque não
# tenho o código das suas policies pra acertar a convenção exata. Se o Pundit
# reclamar de algo, me manda sua EscolaPolicy que eu ajusto.

class PlanosDeEnsinoController < ApplicationController
  layout 'dashboard'

  PER_PAGE = 15

  # Só destroy exige super admin de verdade — igual ao padrão do EscolasController
  before_action :required_super_admin!, only: %i[destroy]
  before_action :set_escola, except: %i[selecionar_escola]
  before_action :set_plano_de_ensino, only: %i[show edit update destroy]
  before_action :set_form_collections, only: %i[index new create edit update]

  # --------------------------
  # SELECIONAR ESCOLA
  # --------------------------
  # GET /escolas/planos_de_ensino
  def selecionar_escola
    authorize Escola, :index?
    @escolas = policy_scope(Escola).includes(:turmas).order(:nome)
  end

  # --------------------------
  # INDEX
  # --------------------------
  def index
    authorize @escola, :show?

    planos = @escola.planos_de_ensino
                     .includes(:turma, :disciplina, :professor, turma: :ano_letivo)

    # Contadores do resumo sempre olham pra TODOS os planos da escola,
    # não só pra página filtrada — pra não mudar o painel quando filtra.
    @total_planos = @escola.planos_de_ensino.count
    @total_publicados = @escola.planos_de_ensino.publicado.count
    @total_em_elaboracao = @escola.planos_de_ensino.em_elaboracao.count
    @total_rascunhos = @escola.planos_de_ensino.rascunho.count

    planos = planos.where(professor_id: params[:professor_id]) if params[:professor_id].present?
    planos = planos.where(turma_id: params[:turma_id]) if params[:turma_id].present?
    planos = planos.where(disciplina_id: params[:disciplina_id]) if params[:disciplina_id].present?
    planos = planos.where(status: params[:status]) if params[:status].present?

    if params[:q].present?
      termo = "%#{params[:q].strip.downcase}%"
      planos = planos.joins(:professor).where(
        "LOWER(professors.nome) LIKE :t OR LOWER(planos_de_ensino.ementa) LIKE :t",
        t: termo
      )
    end

    @page = [params[:page].to_i, 1].max
    @total_filtrado = planos.count
    @planos_de_ensino = planos.order(updated_at: :desc)
                               .offset((@page - 1) * PER_PAGE)
                               .limit(PER_PAGE)
  end

  # --------------------------
  # SHOW
  # --------------------------
  def show
    authorize @escola, :show?
  end

  # --------------------------
  # NEW
  # --------------------------
  def new
    authorize @escola, :create?
    @plano_de_ensino = PlanoDeEnsino.new
    @plano_de_ensino.turma_id = params[:turma_id] if params[:turma_id].present?
    @plano_de_ensino.disciplina_id = params[:disciplina_id] if params[:disciplina_id].present?
    @plano_de_ensino.bimestre = params[:bimestre].to_i if params[:bimestre].present?
  end

  # --------------------------
  # CREATE
  # --------------------------
  def create
    authorize @escola, :create?
    @plano_de_ensino = PlanoDeEnsino.new(plano_de_ensino_params)

    if plano_fora_da_escola?
      @plano_de_ensino.errors.add(:turma_id, "deve pertencer a #{@escola.nome}")
      return render :new, status: :unprocessable_entity
    end

    if @plano_de_ensino.save
      redirect_to escola_plano_de_ensino_path(@escola, @plano_de_ensino), notice: "Plano de ensino criado com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # --------------------------
  # EDIT
  # --------------------------
  def edit
    authorize @escola, :update?
  end

  # --------------------------
  # UPDATE
  # --------------------------
  def update
    authorize @escola, :update?

    if plano_fora_da_escola?(plano_de_ensino_params)
      @plano_de_ensino.errors.add(:turma_id, "deve pertencer a #{@escola.nome}")
      return render :edit, status: :unprocessable_entity
    end

    if @plano_de_ensino.update(plano_de_ensino_params)
      redirect_to escola_plano_de_ensino_path(@escola, @plano_de_ensino), notice: "Plano de ensino atualizado com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # --------------------------
  # DESTROY
  # --------------------------
  def destroy
    @plano_de_ensino.destroy
    redirect_to escola_planos_de_ensino_path(@escola), notice: "Plano de ensino excluído com sucesso.", status: :see_other
  end

  private

  def set_escola
    @escola = Escola.find(params[:escola_id])
  end

  # has_many :planos_de_ensino, through: :turmas é somente leitura pra criação
  # (PlanoDeEnsino não tem escola_id próprio), então buscamos sempre através
  # da escola pra garantir que ninguém acesse o plano de outra escola pela URL.
  def set_plano_de_ensino
    @plano_de_ensino = @escola.planos_de_ensino
                               .includes(:turma, :disciplina, :professor, turma: :ano_letivo)
                               .find(params[:id])
  end

  def set_form_collections
    @professores_filtro = @escola.professors.order(:nome)
    @turmas_filtro = @escola.turmas.order(:nome)
    @disciplinas_filtro = @escola.disciplinas.order(:nome)
  end

  # Confere que a turma escolhida (do params, não ainda salva) é da @escola —
  # necessário porque @plano_de_ensino.turma_id vem de fora e poderia,
  # em tese, apontar pra turma de outra escola.
  def plano_fora_da_escola?(attrs = plano_de_ensino_params)
    turma_id = attrs[:turma_id].presence
    return false if turma_id.blank?

    !@escola.turmas.exists?(id: turma_id)
  end

  def plano_de_ensino_params
    params.require(:plano_de_ensino).permit(
      :professor_id, :turma_id, :disciplina_id, :bimestre, :status, :curso,
      :ementa, :objetivos_gerais, :objetivos_especificos, :competencias, :habilidades,
      :conteudos_programaticos, :metodologia, :recursos_didaticos, :criterios_avaliacao,
      :cronograma_unidades, :bibliografia_basica, :bibliografia_complementar, :observacoes
    )
  end
end