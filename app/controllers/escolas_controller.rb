class EscolasController < ApplicationController
  layout 'dashboard'
  before_action :set_escola, only: %i[show edit update destroy]

  def index
    # Tenta usar Pundit, com fallback para todos os registros
    begin
      authorize Escola
      @escolas = policy_scope(Escola).includes(:turmas, :alunos, :endereco, :admin)
    rescue Pundit::NotDefinedError => e
      Rails.logger.warn "Pundit error: #{e.message}"
      @escolas = Escola.includes(:turmas, :alunos, :endereco, :admin).all
    end
     
    # Statistics for dashboard
    @total_escolas = @escolas.count
    @total_escolas_publicas = @escolas.publicas.count
    @total_escolas_privadas = @escolas.privadas.count
    @total_turmas = Turma.count
    @total_alunos = Aluno.count
    @media_alunos_escola = @total_escolas > 0 ? (@total_alunos.to_f / @total_escolas).round(1) : 0

    # Data for charts
    @escolas_with_counts = @escolas.left_joins(:turmas, :alunos)
                                  .group('escolas.id', 'escolas.nome')
                                  .select('escolas.*, COUNT(DISTINCT turmas.id) as turmas_count, COUNT(DISTINCT alunos.id) as alunos_count')

    respond_to do |format|
      format.html # renderiza a página normal
      format.turbo_stream # deixa o turbo funcionar
    end

    # Apply search filter
    if params[:busca].present?
      @escolas = @escolas.where("escolas.nome ILIKE ?", "%#{params[:busca]}%")
    end

    # Apply modal filter
    @escolas = @escolas.where(tipo: "publica") if params[:filtros]&.include?("publicas")
    @escolas = @escolas.where(tipo: "privada") if params[:filtros]&.include?("privadas")
    @escolas = @escolas.where.not(cnpj: [nil, ""]) if params[:filtros]&.include?("with_cnpj")
    @escolas = @escolas.where(cnpj: [nil, ""]) if params[:filtros]&.include?("without_cnpj")

    if params[:filtros]&.include?("most_students")
      @escolas = @escolas.left_joins(:alunos).group('escolas.id').order('COUNT(alunos.id) DESC')
    elsif params[:filtros]&.include?("least_students")
      @escolas = @escolas.left_joins(:alunos).group('escolas.id').order('COUNT(alunos.id) ASC')
    elsif params[:filtros]&.include?("most_classes")
      @escolas = @escolas.left_joins(:turmas).group('escolas.id').order('COUNT(turmas.id) DESC')
    elsif params[:filtros]&.include?("least_classes")
      @escolas = @escolas.left_joins(:turmas).group('escolas.id').order('COUNT(turmas.id) ASC')
    end
  end

  def show
    # Autorização com Pundit
    begin
      authorize @escola
    rescue Pundit::NotDefinedError => e
      Rails.logger.warn "Pundit error: #{e.message}"
      # Continua sem autorização se Pundit não funcionar
    end
    
    # Carrega todos os alunos da escola com a mesma lógica do alunos controller
    @alunos = Aluno.where(escola_id: @escola.id).includes(:turma)

    @disciplinas = @escola.disciplinas
    @disciplinas_por_area = @disciplinas.group(:area).count
  end

  def new
    @escola = Escola.new
    @escola.build_endereco
  end

  def welcome
    @escola = Escola.new
    @escola.build_endereco
  end

  def edit
    @escola.build_endereco if @escola.endereco.nil?
  end

  def create
    @escola = Escola.new(escola_params)
    
    # Se for um admin logado, associa automaticamente
    if current_admin.present?
      @escola.admin = current_admin
    end

    respond_to do |format|
      if @escola.save
        # Se for um admin, associa também na direção inversa
        if current_admin.present? && current_admin.escolas.nil?
          current_admin.update(escola: @escola)
        end
        
        format.html { redirect_to escola_url(@escola), notice: "Escola foi criada com sucesso." }
        format.json { render :show, status: :created, location: @escola }
      else
        @escola.build_endereco if @escola.endereco.nil?
        
        # Se veio da página de welcome, renderiza welcome em caso de erro
        if request.referer&.include?('welcome')
          format.html { render :welcome, status: :unprocessable_entity }
        else
          format.html { render :new, status: :unprocessable_entity }
        end
        format.json { render json: @escola.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @escola.update(escola_params)
        format.html { redirect_to @escola, notice: "Escola foi atualizada com sucesso." }
        format.json { render :show, status: :ok, location: @escola }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @escola.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @escola.destroy!

    respond_to do |format|
      format.html { redirect_to escolas_path, status: :see_other, notice: "Escola foi excluída com sucesso." }
      format.json { head :no_content }
    end
  end

  private

  def set_escola
    @escola = Escola.find(params[:id])
  end

  def escola_params
    params.require(:escola).permit(
      :nome, :cnpj, :telefone, :email, :site, :tipo, :admin_id,
      endereco_attributes: [
        :id, :logradouro, :numero, :complemento, :bairro, :cidade_id, :cep, :_destroy
      ]
    )
  end

end
