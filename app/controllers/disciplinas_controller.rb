class DisciplinasController < ApplicationController
  before_action :set_disciplina, only: %i[show edit update destroy]
  layout 'dashboard'

  # GET /disciplinas
  def index
    @disciplinas = Disciplina.includes(:escola, :professores).all

    
  end

  # GET /disciplinas/1
  def show
  end

  # GET /disciplinas/new
  def new
    @disciplina = Disciplina.new

    if params[:buscar_professor].present? && params[:disciplina].present?
      busca = params[:disciplina][:busca_professor]
      @professores_selecionaveis = Professor.where("nome ILIKE ?", "%#{busca}%").order(:nome)
    else
      @professores_selecionaveis = Professor.all.order(:nome)
    end
  end


  # GET /disciplinas/1/edit
  def edit
  end

  # POST /disciplinas
  def create
    @disciplina = Disciplina.new(disciplina_params)

    if @disciplina.save
      redirect_to @disciplina, notice: "Disciplina criada com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /disciplinas/1
  def update
    if @disciplina.update(disciplina_params)
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
    # aceitando escola_id e múltiplos professores
    params.require(:disciplina).permit(:nome, :escola_id, professor_ids: [])
  end
end
