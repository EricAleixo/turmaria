class AdminConteudosController < ApplicationController
  layout 'dashboard'

  before_action :authorize_admin_or_super_admin
  before_action :set_scope_objects, only: [:new, :create, :index, :show, :edit, :update, :destroy]
  before_action :set_conteudo, only: %i[show edit update destroy remove_material]
  before_action :set_disciplinas, only: [:new, :edit, :create, :update]
  before_action :prepare_form_data, only: [:new, :create, :edit, :update]



  # GET /escolas/:escola_id/conteudos
  def index
    load_context
    load_collections
    apply_filters
    paginate_and_render
  end


  # GET /conteudos/1
  def show
    render template: 'conteudos/show'
  end

  # GET /conteudos/new
  def new
    if @escola
      @conteudo = @escola.conteudos.new
    else
      @conteudo = Conteudo.new
    end

    @turmas = @escola.turmas
    
    render template: 'conteudos/new'
  end

  # GET /conteudos/1/edit
  def edit
    @bimestres = @conteudo.turma.ano_letivo.numero_bimestre
    render template: 'conteudos/edit'
  end

  # POST /conteudos
  def create
    @conteudo = if @escola
                  @escola.conteudos.new(conteudo_params)
                else
                  Conteudo.new(conteudo_params)
                end
    
    # Associação da escola
    unless @conteudo.escola_id.present?
      @conteudo.escola = @escola if @escola.present?
    end

    # Validação adicional de segurança para Admin
    if current_user.is_a?(Admin) && @conteudo.escola_id.present?
      unless current_user.escolas.pluck(:id).include?(@conteudo.escola_id)
        respond_to do |format|
          format.html { redirect_to conteudos_path, alert: "Você não tem permissão para criar conteúdos nesta escola." }
          format.json { render json: { error: "Sem permissão" }, status: :forbidden }
        end
        return
      end
    end

    if @conteudo.save
      respond_to do |format|
        format.html { redirect_to redirect_path, notice: "Conteúdo criado com sucesso." }
        format.turbo_stream { redirect_to redirect_path, notice: "Conteúdo criado com sucesso." }
        format.json { render :show, status: :created, location: @conteudo }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @conteudo.errors, status: :unprocessable_entity }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace('conteudo_form', 
                                                     partial: 'conteudos/form', 
                                                     locals: { conteudo: @conteudo }), 
                 status: :unprocessable_entity
        end
      end
    end
  end

  # PATCH/PUT /conteudos/1
  def update
    if current_user.is_a?(Admin) && @conteudo.escola_id.present?
      unless current_user.escolas.pluck(:id).include?(@conteudo.escola_id)
        respond_to do |format|
          format.html { redirect_to conteudos_path, alert: "Você não tem permissão para editar este conteúdo." }
          format.json { render json: { error: "Sem permissão" }, status: :forbidden }
        end
        return
      end
    end

    if params[:conteudo][:materiais].present? && !params[:conteudo][:materiais].is_a?(Array)
      params[:conteudo][:materiais] = [params[:conteudo][:materiais]]
    end

    respond_to do |format|
      if @conteudo.update(conteudo_params.except(:materiais))
        if params[:conteudo][:materiais].present?
          @conteudo.materiais.attach(params[:conteudo][:materiais])
        end

        processar_materiais(@conteudo)

        format.html { redirect_to redirect_path, notice: "Conteúdo atualizado com sucesso." }
        format.turbo_stream { redirect_to redirect_path, notice: "Conteúdo atualizado com sucesso." }
        format.json { render :show, status: :ok, location: @conteudo }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @conteudo.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /conteudos/1
  def destroy
    if current_user.is_a?(Admin) && @conteudo.escola_id.present?
      unless current_user.escolas.pluck(:id).include?(@conteudo.escola_id)
        puts "Sem permissão"
        redirect_to conteudos_path, alert: "Você não tem permissão para deletar este conteúdo."
        return
      end
    end

    @conteudo.destroy!
    redirect_to redirect_path, notice: "Conteúdo deletado com sucesso."
  end

  # DELETE /conteudos/:id/remove_material
  def remove_material
    arquivo = @conteudo.materiais.find(params[:arquivo_id])
    arquivo.purge

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to conteudo_path(@conteudo), notice: "Arquivo removido com sucesso." }
    end
  end

  # GET /conteudos/search_escolas
  def search_escolas
    query = params[:q].to_s.strip
    
    escolas = if current_user.is_a?(SuperAdmin)
                # SuperAdmin vê todas as escolas
                Escola.where("LOWER(nome) LIKE ?", "%#{query.downcase}%").limit(10)
              else # Admin
                # Admin só vê suas escolas
                current_user.escolas.where("LOWER(nome) LIKE ?", "%#{query.downcase}%").limit(10)
              end
    
    render json: escolas.select(:id, :nome)
  end

  private

  def prepare_form_data
    @turmas = @escola.turmas
  end
  

  def load_context
    if @escola
      @context = :escola
    elsif current_user.is_a?(SuperAdmin)
      @context = :super_admin
    else
      @context = :multi_escola
    end
  end

  def load_collections
    @conteudos =
      case @context
      when :escola
        @disciplinas = @escola.disciplinas
        @professors = @escola.professors
        @turmas      = @escola.turmas
        @escola.conteudos
      when :super_admin
        @disciplinas = Disciplina.all
        @professors = Professor.all
        @turmas      = Turma.all
        Conteudo.all
      else
        escolas_ids  = current_user.escolas.pluck(:id)
        @disciplinas = Disciplina.where(escola_id: escolas_ids)
        @professors = Professor.where(escola_id: escolas_ids)
        @turmas      = Turma.where(escola_id: escolas_ids)
        Conteudo.where(escola_id: escolas_ids)
      end
  end


  def apply_filters
    @conteudos = @conteudos.where(disciplina_id: params[:disciplina_id]) if params[:disciplina_id].present?
    @conteudos = @conteudos.where(professor_id: params[:professor_id])   if params[:professor_id].present?
    @conteudos = @conteudos.where(turma_id: params[:turma_id])           if params[:turma_id].present?
    @conteudos = @conteudos.where(bimestre: params[:bimestre])           if params[:bimestre].present?
    @conteudos = @conteudos.where(tipo: params[:tipo])                   if params[:tipo].present?

    if params[:search].present?
      @conteudos = @conteudos.where(
        "titulo ILIKE :q OR descricao ILIKE :q",
        q: "%#{params[:search]}%"
      )
    end

    load_bimestres
  end


  def load_bimestres
    return @bimestres_disponiveis = [] unless params[:turma_id].present?

    turma = @turmas.find_by(id: params[:turma_id])
    @bimestres_disponiveis = turma ? (1..turma.ano_letivo.numero_bimestre).to_a : []
  end


  def paginate_and_render
    @conteudos = @conteudos
                  .includes(:disciplina, :professor, :turma, :escola)
                  .order(created_at: :desc)
                  .page(params[:page])

    render "conteudos/index"
  end



  def authorize_admin_or_super_admin
    unless current_user.is_a?(Admin) || current_user.is_a?(SuperAdmin)
      redirect_to root_path, alert: "Acesso negado."
    end
  end

  def set_scope_objects
    if params[:escola_id].present?
      @escola = Escola.find(params[:escola_id])
      # Admin precisa ter acesso à escola
      authorize_escola_access(@escola) if current_user.is_a?(Admin)
    end
  end

  def authorize_escola_access(escola)
    unless current_user.escolas.include?(escola)
      redirect_to conteudos_path, alert: "Você não tem permissão para acessar esta escola."
    end
  end

  def set_conteudo
    if @escola
      @conteudo = @escola.conteudos.find(params[:id])
    elsif current_user.is_a?(SuperAdmin)
      # SuperAdmin tem acesso total
      @conteudo = Conteudo.find(params[:id])
    else # Admin
      # Admin só vê conteúdos das suas escolas
      @conteudo = Conteudo.where(escola_id: current_user.escolas.pluck(:id)).find(params[:id])
    end
    
  rescue ActiveRecord::RecordNotFound
    redirect_to conteudos_path, alert: "Conteúdo não encontrado ou você não tem permissão para acessá-lo."
  end

  def redirect_path
    if @escola
      escola_conteudos_path(@escola)
    else
      conteudos_path
    end
  end

  def set_disciplinas
    @disciplinas =
      if @escola
        @escola.disciplinas
      elsif current_user.is_a?(SuperAdmin)
        Disciplina.all
      else # Admin
        Disciplina.where(escola_id: current_user.escolas.pluck(:id))
      end
  end


  def processar_materiais(conteudo)
    return unless conteudo.materiais.attached?

    conteudo.materiais.each do |arquivo|
      if arquivo.content_type == "application/pdf"
        processar_pdf(arquivo)
      elsif arquivo.content_type == "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        processar_docx(arquivo)
      end
    end
  end

  def processar_docx(arquivo)
    require 'docx'

    arquivo.blob.open do |file|
      doc = Docx::Document.open(file.path)
      doc.paragraphs.each { |p| puts p.text }
    end
  end


  def processar_pdf(arquivo)
    require 'combine_pdf'
    require 'tempfile'

    arquivo.blob.open do |file|
      pdf = CombinePDF.load(file.path)
      puts pdf.pages.count
    end
  end


  def conteudo_params
    params.require(:conteudo).permit(
      :titulo, :bimestre, :descricao, :markdown, 
      :disciplina_id, :escola_id, :tipo, :turma_id, :professor_id,
      materiais: []
    )
  end
end