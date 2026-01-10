class DisciplinasController < ApplicationController
  before_action :set_disciplina, only: %i[show edit update destroy]
  layout 'dashboard'

  # ---------------------------
  # INDEX
  # ---------------------------
  def index
    @escola = Escola.find_by(id: params[:escola_id])
    @disciplinas = @escola ? @escola.disciplinas : Disciplina.all

    if params[:professor_id].present?
      @professor = Professor.find_by(id: params[:professor_id])
      return unless @professor

      @disciplinas = @disciplinas
                      .joins(:professores)
                      .where(professores: { id: @professor.id })
    end
  end



  def selecionar_escola 
    @escolas = current_user.escolas
  end

  # ---------------------------
  # BUSCAR ESCOLAS (NOVA ACTION)
  # ---------------------------
  def buscar_escolas
    # SuperAdmin pode buscar qualquer escola
    # Admin só pode buscar suas próprias escolas
    authorize Disciplina, :buscar_escolas?
    
    escolas = if current_user.is_a?(SuperAdmin)
      Escola.all
    elsif current_user.is_a?(Admin)
      current_user.escolas
    else
      Escola.none
    end

    # Filtros opcionais
    if params[:escola_busca].present?
      escolas = escolas.where("nome ILIKE ?", "%#{params[:escola_busca]}%")
    end

    if params[:tipo].present?
      escolas = escolas.where(tipo: params[:tipo])
    end

    escolas = escolas.order(:nome).limit(50)

    respond_to do |format|
      format.json do
        render json: {
          escolas: escolas.as_json(only: [:id, :nome, :tipo])
        }
      end
    end
  end

  # ---------------------------
  # SHOW
  # ---------------------------
  def show
    authorize @disciplina
  end

  # ---------------------------
  # NEW
  # ---------------------------
  def new
    @escola = Escola.find(params[:escola_id])

    @disciplina = @escola.disciplinas.build
    authorize @disciplina

    @disciplinas_areas = AreaDisciplina.all.order(:nome)
    load_professores
  end



  # ---------------------------
  # EDIT
  # ---------------------------
  def edit
    authorize @disciplina

    @disciplinas_areas = AreaDisciplina.all.order(:nome)
    @escolas = Escola.all if current_user.is_a?(SuperAdmin)
  end

  # ---------------------------
  # CREATE
  # ---------------------------
    def create
      @escola = Escola.find(params[:escola_id])

      @disciplina = @escola.disciplinas.build(
        disciplina_params.except(:professor_ids)
      )
      authorize @disciplina

      assign_professores

      if @disciplina.save
        redirect_to escola_disciplinas_path(@escola),
                    notice: "Disciplina criada com sucesso!"
      else
        @disciplinas_areas = AreaDisciplina.all.order(:nome)
        load_professores
        render :new, status: :unprocessable_entity
      end
    end


  # ---------------------------
  # UPDATE
  # ---------------------------
  def update
    authorize @disciplina

    if @disciplina.update(disciplina_params.except(:professor_ids))
      assign_professores
      redirect_to @disciplina, notice: "Disciplina atualizada com sucesso."
    else
      @disciplinas_areas = AreaDisciplina.all.order(:nome)
      render :edit, status: :unprocessable_entity
    end
  end

  # ---------------------------
  # DESTROY
  # ---------------------------
  def destroy
    authorize @disciplina
    escola = @disciplina.escola
    @disciplina.destroy

    redirect_to escola_disciplinas_path(escola), notice: "Disciplina removida com sucesso."
  end

  # ---------------------------
  # PRIVATE
  # ---------------------------
  private

  def set_disciplina
    @disciplina = Disciplina.find(params[:id])
  end

  def assign_professores
    return unless disciplina_params[:professor_ids].present?

    ids = disciplina_params[:professor_ids].reject(&:blank?)
    @disciplina.professores = Professor.where(id: ids, escola_id: @disciplina.escola_id)
  end

  def load_professores
    if params[:professor_busca].present? && params[:escola_id].present?
      @professores = Professor.where(escola_id: params[:escola_id])
                              .where("nome ILIKE ?", "%#{params[:professor_busca]}%")
                              .order(:nome)
                              .limit(20)
    elsif params[:professor_busca].present?
      @professores = Professor.where("nome ILIKE ?", "%#{params[:professor_busca]}%")
                              .order(:nome)
                              .limit(20)
    else
      @professores = []
    end
  end

  def respond_to_json_if_needed
    return unless request.format.json?

    render json: {
      escolas: (@escolas || []).as_json(only: [:id, :nome]),
      professores: @professores.as_json(only: [:id, :nome, :escola_id])
    }
  end

  def disciplina_params
    params.require(:disciplina).permit(
      :nome,
      :escola_id,
      :cor_nome,
      :area_nome_temp,
      :area_cor_temp,
      :area_disciplina_id,
      professor_ids: []
    )
  end
end