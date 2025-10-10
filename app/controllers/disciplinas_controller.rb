class DisciplinasController < ApplicationController
  before_action :set_disciplina, only: %i[show edit update destroy]
  layout 'dashboard'

  # GET /disciplinas
  def index
    if params[:professor_id]
      @professor = Professor.find(params[:professor_id])
      puts "PROFESSOR ENCONTRADO: #{@professor.inspect}"
      @disciplinas = @professor.disciplinas.includes(:escola)
    else
      @disciplinas = Disciplina.includes(:escola, :professores).all
    end
  end

  # GET /disciplinas/1
  def show
  end

  # GET /disciplinas/new
  def new
    @disciplina = Disciplina.new

    # Filtro de escolas
    escolas = if params[:escola_busca].present?
                @escolas = Escola.where("nome ILIKE ?", "%#{params[:escola_busca]}%").limit(20)
              else
                @escolas = []
              end

    # Filtro de professores
    professores = []
    if params[:professor_busca].present? && params[:escola_id].present?
      professores = Professor.where(escola_id: params[:escola_id])
                              .where("nome ILIKE ?", "%#{params[:professor_busca]}%")
                              .order(:nome)
                              .limit(20)
    elsif params[:professor_busca].present?
      professores = Professor.where("nome ILIKE ?", "%#{params[:professor_busca]}%")
                              .order(:nome)
                              .limit(20)
    end

    # Se for JSON, retorna só os dados para autocomplete e encerra
    if request.format.json?
      return render json: {
        escolas: @escolas.as_json(only: [:id, :nome]),
        professores: professores.as_json(only: [:id, :nome, :escola_id])
      }
    end
  end

  # GET /disciplinas/1/edit
  def edit
  end

  # POST /disciplinas
  def create
    @disciplina = Disciplina.new(disciplina_params.except(:professor_ids))

    # atribuindo professores many-to-many
    if disciplina_params[:professor_ids].present?
      @disciplina.professores = Professor.where(id: disciplina_params[:professor_ids])
    end

    if @disciplina.save
      redirect_to disciplinas_path, notice: "Disciplina criada com sucesso!"
    else
      render :new
    end
  end

  # PATCH/PUT /disciplinas/1
  def update
    if @disciplina.update(disciplina_params.except(:professor_ids))
      if disciplina_params[:professor_ids].present?
        @disciplina.professores = Professor.where(id: disciplina_params[:professor_ids].reject(&:blank?))
      end
    
      redirect_to @disciplina, notice: "Disciplina atualizada com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end
  # DELETE /disciplinas/1
  def destroy
    @disciplina.destroy
    redirect_to disciplinas_url, notice: "Disciplina removida com sucesso."
  end

  private

  def set_disciplina
    @disciplina = Disciplina.find(params[:id])
  end

  def disciplina_params
    params.require(:disciplina).permit(:nome, :area, :escola_id, professor_ids: [])
  end

end
