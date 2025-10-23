class DisciplinasController < ApplicationController
  before_action :set_disciplina, only: %i[show edit update destroy]
  layout 'dashboard'

  # GET /disciplinas
  def index
    @disciplinas = if current_user.is_a?(SuperAdmin)
                     Disciplina.all
                   else
                     Disciplina.where(escola: current_user.escola)
                   end
                 
    # Se houver professor, filtra ainda mais
    if params[:professor_id].present?
      @professor = Professor.find(params[:professor_id])
      @disciplinas = @disciplinas.joins(:professores).where(professores: { id: @professor.id })
    end
    
    # Inclui associações para evitar N+1
    @disciplinas = @disciplinas.includes(:escola, :professores)
  end

  # GET /disciplinas/1
  def show
  end

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
    @disciplina = Disciplina.new

    # Autocomplete ou listagem de escolas apenas para SuperAdmin
    if current_user.is_a?(SuperAdmin)
      @escolas = Escola.all
    end

    # Professores apenas para autocomplete
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

    # JSON para autocomplete
    if request.format.json?
      render json: {
        escolas: (@escolas || []).as_json(only: [:id, :nome]),
        professores: @professores.as_json(only: [:id, :nome, :escola_id])
      }
    end
  end

  # GET /disciplinas/1/edit
  def edit
  end

  # POST /disciplinas
  def create
    # Define a escola automaticamente
    @escola = if current_user.is_a?(Admin)
                current_user.escolas.first
              elsif current_user.is_a?(SuperAdmin) && params[:disciplina][:escola_id].present?
                Escola.find(params[:disciplina][:escola_id])
              else
                nil
              end

              raise "Escola inválida: #{@escola.inspect}" unless @escola.present?
              raise "Classe do objeto: #{@escola.class}" unless @escola.is_a?(Escola)
    unless @escola
      flash.now[:alert] = "Escolha uma escola válida"
      @disciplina = Disciplina.new(disciplina_params)
      render :new and return
    end

    # Cria disciplina associada à escola
    @disciplina = @escola.disciplinas.new(disciplina_params.except(:professor_ids))

    # Associa professores se houver
    if disciplina_params[:professor_ids].present?
      valid_ids = disciplina_params[:professor_ids].reject(&:blank?)
      @disciplina.professores = Professor.where(id: valid_ids)
    end

    if @disciplina.save
      redirect_to escola_disciplinas_path(@escola), notice: "Disciplina criada com sucesso!"
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
    params.require(:disciplina).permit(:nome, :area, :escola_id, :cor, :cor_nome, professor_ids: [] )
  end

end
