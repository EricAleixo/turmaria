class ConteudosController < ApplicationController
  layout 'dashboard'

  before_action :set_scope_objects, only: [:new, :create, :index, :show, :edit, :update, :destroy]
  before_action :set_conteudo, only: %i[show edit update destroy remove_material]

  # GET /conteudos
  def index
    if current_user.is_a?(SuperAdmin)
      @conteudos = Conteudo.all
    elsif current_user.is_a?(Admin)
      @conteudos = Conteudo.where(escola_id: current_user.escolas.pluck(:id))
    else
      @conteudos = current_user.conteudos
    end
  end

  def show; end

  def edit

  end

  # GET /conteudos/new
  def new
    if @professor
      @conteudo = @professor.conteudos.new(escola_id: @professor.escola_id)
    elsif @escola
      @conteudo = @escola.conteudos.new
    else
      @conteudo = Conteudo.new
    end
  end

  # POST /conteudos
  def create
    @conteudo =
      if @professor
        @professor.conteudos.new(conteudo_params)
      elsif @escola
        @escola.conteudos.new(conteudo_params)
      else
        Conteudo.new(conteudo_params)
      end

    unless @conteudo.escola_id.present?
      @conteudo.escola = @escola if @escola.present?
    end

    unless @conteudo.escola_id.present?
      @conteudo.escola = @professor.escolas.first if @professor.present?
    end

    if @conteudo.save
      respond_to do |format|
        format.html { redirect_to after_save_path, notice: "Conteúdo criado com sucesso." }
        format.turbo_stream { redirect_to after_save_path, notice: "Conteúdo criado com sucesso." }
        format.json { render :show, status: :created, location: @conteudo }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @conteudo.errors, status: :unprocessable_entity }

        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "conteudo_form",
            partial: "form",
            locals: { conteudo: @conteudo }
          ),
          status: :unprocessable_entity
        end
      end
    end
  end

  # PATCH/PUT /conteudos/1
  def update
    if params[:conteudo][:materiais].present? && !params[:conteudo][:materiais].is_a?(Array)
      params[:conteudo][:materiais] = [params[:conteudo][:materiais]]
    end

    respond_to do |format|
      if @conteudo.update(conteudo_params.except(:materiais))

        if params[:conteudo][:materiais].present?
          @conteudo.materiais.attach(params[:conteudo][:materiais])
        end

        processar_materiais(@conteudo)

        format.html { redirect_to after_save_path, notice: "Conteúdo atualizado com sucesso." }
        format.turbo_stream { redirect_to after_save_path, notice: "Conteúdo atualizado com sucesso." }
        format.json { render :show, status: :ok, location: @conteudo }

      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @conteudo.errors, status: :unprocessable_entity }
      end
    end
  end

  def remove_material
    @conteudo = Conteudo.find(params[:id])
    arquivo = @conteudo.materiais.find(params[:arquivo_id])
    arquivo.purge

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @conteudo, notice: "Arquivo removido com sucesso." }
    end
  end

  # DELETE /conteudos/1
  def destroy
    @conteudo.destroy!

    redirect_to after_delete_path, notice: "Conteúdo deletado com sucesso."
  end

  def search_escolas
    query = params[:q].to_s.strip
    escolas = Escola.where("LOWER(nome) LIKE ?", "%#{query.downcase}%").limit(10)
    render json: escolas.select(:id, :nome)
  end

  private

  # ROTAS CERTAS PARA CADA PERFIL
  def after_save_path
    if current_user.is_a?(SuperAdmin)
      conteudos_path
    elsif current_user.is_a?(Admin)
      escola_conteudos_path(@escola)
    else
      professor_conteudos_path
    end
  end

  def after_delete_path
    after_save_path
  end

  # Escopo
  def set_scope_objects
    if current_user.is_a?(Professor)
      @professor = current_user
      @escola = @professor.escola
    elsif params[:professor_id].present?
      @professor = Professor.find(params[:professor_id])
      @escola = @professor.escola
    elsif params[:escola_id].present?
      @escola = Escola.find(params[:escola_id])
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
    arquivo_path = ActiveStorage::Blob.service.send(:path_for, arquivo.blob.key)
    doc = Docx::Document.open(arquivo_path)
    doc.paragraphs.each { |p| puts p.text }
  end

  def processar_pdf(arquivo)
    require 'combine_pdf'
    arquivo_path = ActiveStorage::Blob.service.send(:path_for, arquivo.blob.key)
    pdf = CombinePDF.load(arquivo_path)
    puts pdf.pages.count
  end

  # Carregar @conteudo respeitando escopo
  def set_conteudo
    if current_user.is_a?(Professor)
      @conteudo = current_user.conteudos.find(params[:id])
    elsif @professor
      @conteudo = @professor.conteudos.find(params[:id])
    elsif @escola
      @conteudo = @escola.conteudos.find(params[:id])
    else
      @conteudo = Conteudo.find(params[:id])
    end

  rescue ActiveRecord::RecordNotFound
    redirect_to after_save_path, alert: "Conteúdo não encontrado ou você não tem permissão."
  end

  def conteudo_params
    permitted = [:titulo, :bimestre, :descricao, :markdown, :disciplina_id, :escola_id, :tipo, { materiais: [] }]
    permitted << :professor_id if current_user.is_a?(Admin) || current_user.is_a?(SuperAdmin)
    params.require(:conteudo).permit(permitted)
  end
end
