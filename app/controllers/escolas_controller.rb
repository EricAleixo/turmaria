class EscolasController < ApplicationController
  layout 'dashboard'

  # SuperAdmin é exigido em tudo, EXCETO:
  # index, show, new, edit, update (admin acessa via policy)
  before_action :required_super_admin!, except: %i[index show new edit update]
  before_action :set_escola, only: %i[show edit update destroy]

  # --------------------------
  # INDEX
  # --------------------------
  def index
    authorize Escola

    # Admin → só as dele
    # SuperAdmin → todas
    @escolas = policy_scope(Escola)
                .includes(:turmas, :alunos, :endereco, :admin)

    # === ESCOLAS DINÂMICAS ===
    scope = current_super_admin? ? Escola : @escolas

    @total_escolas = scope.count
    @total_escolas_publicas = scope.where(tipo: "publica").count
    @total_escolas_privadas = scope.where(tipo: "privada").count

    # === ALUNOS DINÂMICOS ===
    if current_super_admin?
      @total_alunos = Aluno.count
    else
      # alunos SOMENTE das escolas do admin
      @total_alunos = Aluno.where(escola_id: @escolas.ids).count
    end

    # === TURMAS DINÂMICAS ===
    if current_super_admin?
      @total_turmas = Turma.count
    else
      # turmas SOMENTE das escolas do admin
      @total_turmas = Turma.where(escola_id: @escolas.ids).count
    end

    # === MÉDIA DE ALUNOS POR ESCOLA ===
    if @total_escolas > 0
      @media_alunos_escola = (@total_alunos.to_f / @total_escolas).round(1)
    else
      @media_alunos_escola = 0
    end

    # === BUSCA (depois dos stats) ===
    if params[:busca].present?
      @escolas = @escolas.where("escolas.nome ILIKE ?", "%#{params[:busca]}%")
    end

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end


  # --------------------------
  # SHOW
  # --------------------------
  def show
    authorize @escola

    @alunos = @escola.alunos.includes(:turma)
    @professores = @escola.professors.includes(:disciplinas).order(:nome)
    @disciplinas = @escola.disciplinas
    @frequencias = Frequencia.da_escola(@escola.id)
                        .includes(:turma, :disciplina, :professor)
                        .order(data_aula: :desc)
                        .limit(10)
  end

  # --------------------------
  # NEW
  # --------------------------
  def new
    @escola = Escola.new
    @escola.build_endereco
  end

  # --------------------------
  # EDIT
  # --------------------------
  def edit
    authorize @escola
    @escola.build_endereco if @escola.endereco.nil?
  end

  # --------------------------
  # CREATE
  # --------------------------
  def create
    @escola = Escola.new(escola_params)

    # Admin que cria → vira dono
    if current_admin.present?
      @escola.admin = current_admin
    end

    if @escola.save
      redirect_to escolas_path, notice: "Escola criada com sucesso."
    else
      @escola.build_endereco if @escola.endereco.nil?
      render :new, status: :unprocessable_entity
    end
  end

  # --------------------------
  # UPDATE
  # --------------------------
  def update
    authorize @escola

    update_params =
      if current_admin.present?
        escola_params.except(:admin_id) # Admin não pode trocar dono
      else
        escola_params
      end

    if @escola.update(update_params)
      redirect_to escolas_path, notice: "Escola atualizada com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # --------------------------
  # DESTROY
  # --------------------------
  def destroy
    authorize @escola
    @escola.destroy
    redirect_to escolas_path, notice: "Escola excluída com sucesso."
  end

  # --------------------------
  # PRIVATE
  # --------------------------
  private

  def set_escola
    @escola = Escola.find(params[:id])
  end

  def escola_params
    params.require(:escola).permit(
      :nome, :cnpj, :telefone, :email, :site, :tipo, :admin_id,
      endereco_attributes: [
        :id, :logradouro, :numero, :complemento, 
        :bairro, :cidade_id, :cep, :_destroy
      ]
    )
  end

  def current_super_admin?
    current_user.is_a?(SuperAdmin) || current_admin.is_a?(SuperAdmin) rescue false
  end
end
