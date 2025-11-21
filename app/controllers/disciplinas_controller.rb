# app/controllers/disciplinas_controller.rb
class DisciplinasController < ApplicationController
  before_action :set_disciplina, only: %i[show edit update destroy]
  layout 'dashboard'

  # GET /disciplinas
  def index
    @disciplinas = if current_user.is_a?(Admin) || current_user.is_a?(SuperAdmin)
                     Disciplina.all
                   elsif current_user.is_a?(Escola)
                     current_user.disciplinas
                   elsif current_user.is_a?(Professor)
                     current_user.disciplinas
                   else
                     Disciplina.none
                   end
    
    if params[:professor_id].present?
      @professor = Professor.find(params[:professor_id])
      @disciplinas = @disciplinas.joins(:professores).where(professores: { id: @professor.id })
    end
    
    @disciplinas = @disciplinas.includes(:escola, :professores, :area_disciplina)
  end

  # GET /disciplinas/1
  def show
  end

  # GET /disciplinas/buscar_escolas
  def buscar_escolas
    nome = params[:escola_busca].to_s.strip.downcase
    tipo = params[:tipo].to_s.strip.downcase

    escolas = Escola.all
    escolas = escolas.where("LOWER(nome) LIKE ?", "%#{nome}%") if nome.present?
    escolas = escolas.where(tipo: tipo) if tipo.present?

    render json: { escolas: escolas.as_json(only: %i[id nome tipo]) }
  end

  # GET /disciplinas/new
  def new
    @disciplinas_areas = AreaDisciplina.all.order(:nome)
    @disciplina = Disciplina.new

    if current_user.is_a?(SuperAdmin)
      @escolas = Escola.all
    end

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

    if request.format.json?
      render json: {
        escolas: (@escolas || []).as_json(only: [:id, :nome]),
        professores: @professores.as_json(only: [:id, :nome, :escola_id])
      }
    end
  end

  # GET /disciplinas/1/edit
  def edit
    @disciplinas_areas = AreaDisciplina.all.order(:nome)
    
    if current_user.is_a?(SuperAdmin)
      @escolas = Escola.all
    end
  end

  # POST /disciplinas
  def create
    @escola = if current_user.is_a?(Admin)
                current_user.escolas.first
              elsif current_user.is_a?(SuperAdmin) && params[:disciplina][:escola_id].present?
                Escola.find(params[:disciplina][:escola_id])
              else
                nil
              end

    unless @escola&.is_a?(Escola)
      flash.now[:alert] = "Escolha uma escola válida"
      @disciplinas_areas = AreaDisciplina.all.order(:nome)
      @disciplina = Disciplina.new(disciplina_params)
      render :new and return
    end

    @disciplina = @escola.disciplinas.new(disciplina_params.except(:professor_ids))

    if disciplina_params[:professor_ids].present?
      valid_ids = disciplina_params[:professor_ids].reject(&:blank?)
      @disciplina.professores = Professor.where(id: valid_ids, escola_id: @escola.id)
    end

    if @disciplina.save
      redirect_to escola_disciplinas_path(@escola), notice: "Disciplina criada com sucesso!"
    else
      @disciplinas_areas = AreaDisciplina.all.order(:nome)
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /disciplinas/1
  def update
    if @disciplina.update(disciplina_params.except(:professor_ids))
      if disciplina_params[:professor_ids].present?
        valid_ids = disciplina_params[:professor_ids].reject(&:blank?)
        @disciplina.professores = Professor.where(
          id: valid_ids, 
          escola_id: @disciplina.escola_id
        )
      end
    
      redirect_to @disciplina, notice: "Disciplina atualizada com sucesso."
    else
      @disciplinas_areas = AreaDisciplina.all.order(:nome)
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /disciplinas/1
  def destroy
    escola = @disciplina.escola
    @disciplina.destroy
    
    redirect_to escola_disciplinas_path(escola), notice: "Disciplina removida com sucesso."
  end

  private

  def set_disciplina
    @disciplina = Disciplina.find(params[:id])
  end

  def disciplina_params
    params.require(:disciplina).permit(
      :nome, 
      :escola_id, 
      :cor_nome,
      :area_nome_temp,  # Nome temporário da área
      :area_cor_temp,   # Cor temporária da área
      :area_disciplina_id,
      professor_ids: []
    )
  end
end