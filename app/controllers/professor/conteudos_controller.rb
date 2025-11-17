class Professor::ConteudosController < ApplicationController
  layout 'dashboard'

  before_action :set_scope_objects, only: [:new, :create, :index, :show, :edit, :update, :destroy]
  before_action :set_conteudo, only: %i[ show edit update destroy remove_material]

  # GET /conteudos
  def index
    if current_user.is_a?(SuperAdmin)
      @conteudos = Conteudo.all
    elsif current_user.is_a?(Admin)
      @conteudos = Conteudo.where(escola_id: current_user.escolas.pluck(:id))
    else # Professor
      @conteudos = current_user.conteudos
    end
  end

  # GET /conteudos/1
  def show; end

  # GET /conteudos/new
  def new
    # @professor ou @escola será definido por set_scope_objects
    if @professor
      # Se o escopo é o professor, use ele para construir o novo conteúdo
      @conteudo = @professor.conteudos.new(escola_id: @professor.escola_id)
    elsif @escola
      @conteudo = @escola.conteudos.new
    else
      # Para SuperAdmin sem escopo, apenas inicializa
      @conteudo = Conteudo.new
    end
  end

  def edit
    # O @conteudo já foi carregado pelo before_action :set_conteudo
  end

  # POST /conteudos
  def create
  if @professor
    @conteudo = @professor.conteudos.new(conteudo_params)
    @conteudo.escola_id = @professor.escola_id
  elsif @escola
    @conteudo = @escola.conteudos.new(conteudo_params)
  else # SuperAdmin sem restrição
    @conteudo = Conteudo.new(conteudo_params)
  end

  # ✅ Estrutura de controle de fluxo CORRIGIDA
  if @conteudo.save
    
    redirect_path =
      if @professor
        [@professor, @conteudo] 
      elsif @escola
        [@escola, @conteudo]
      else
        @conteudo
      end

    respond_to do |format|
      # 1. Resposta de SUCESSO
      format.html { redirect_to redirect_path, notice: "Conteúdo criado com sucesso." }
      format.json { render :show, status: :created, location: @conteudo }
      # Se usar Turbo: format.turbo_stream
    end
  else
    # 2. Resposta de FALHA
    respond_to do |format|
      format.html { render :new, status: :unprocessable_entity }
      format.json { render json: @conteudo.errors, status: :unprocessable_entity }
      # Se usar Turbo: format.turbo_stream
      puts @conteudo.errors.full_messages
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
      # 👉 Aqui ele adiciona novos arquivos em vez de substituir
      if params[:conteudo][:materiais].present?
        @conteudo.materiais.attach(params[:conteudo][:materiais])
      end

      processar_materiais(@conteudo)

      format.html { redirect_to @conteudo, notice: "Conteúdo atualizado com sucesso." }
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
    if current_user.is_a?(SuperAdmin)
      redirect_to conteudos_path, notice: "Conteúdo deletado com sucesso."
    elsif current_user.is_a?(Admin)
      redirect_to escola_conteudos_path(@escola), notice: "Conteúdo deletado com sucesso."
    else current_user.is_a?(Professor)
      redirect_to professor_conteudos_path(@professor), notice: "Conteúdo deletado com sucesso."
    end
  end

  def search_escolas
    query = params[:q].to_s.strip
    escolas = Escola.where("LOWER(nome) LIKE ?", "%#{query.downcase}%").limit(10)
    render json: escolas.select(:id, :nome)
  end

  private

  def set_scope_objects
  # 1. Caso Principal: Professor logado (POST /professor/conteudos)
  if current_user.is_a?(Professor)
    @professor = current_user
    @escola = @professor.escola
    
  # 2. Caso Secundário: Rotas aninhadas (Admin/SuperAdmin)
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
  doc.paragraphs.each { |p| puts p.text } # Exemplo de leitura
end

def processar_pdf(arquivo)
  require 'combine_pdf'
  arquivo_path = ActiveStorage::Blob.service.send(:path_for, arquivo.blob.key)
  pdf = CombinePDF.load(arquivo_path)
  puts pdf.pages.count # Exemplo de leitura
end

  def set_conteudo
    if @professor
      @conteudo = @professor.conteudos.find(params[:id])
    elsif @escola
      @conteudo = @escola.conteudos.find(params[:id])
    else
      @conteudo = Conteudo.find(params[:id])
    end
  end


  # Permitir professor_id para Admins/SuperAdmins
  def conteudo_params
    permitted = [:titulo, :bimestre, :descricao, :markdown, :disciplina_id, :escola_id,{ materiais:[] }]
    permitted << :professor_id if current_user.is_a?(Admin) || current_user.is_a?(SuperAdmin)
    params.require(:conteudo).permit(permitted)
  end
end