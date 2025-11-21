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
  @conteudo = (@professor || @escola).conteudos.new(conteudo_params)
  
  # 2. ASSOCIAÇÃO DA ESCOLA (CORREÇÃO)
  # Se o Conteúdo ainda não tem um escola_id, use o da @escola do escopo.
  # A @escola deve ter sido definida no set_scope_objects.
  unless @conteudo.escola_id.present?
    @conteudo.escola = @escola if @escola.present?
  end
  
  # Caso o professor esteja logado, e o conteúdo não tenha escola,
  # usa a primeira escola do professor.
  unless @conteudo.escola_id.present?
     @conteudo.escola = @professor.escolas.first if @professor.present? && @professor.escolas.present?
  end

  if @conteudo.save
    respond_to do |format|
      # Resposta HTML padrão (garante a compatibilidade)
      format.html { redirect_to professor_conteudos_path, notice: "Conteúdo criado com sucesso." } 
      
      # CORREÇÃO CHAVE: Redireciona o cliente Turbo Stream para a index
      format.turbo_stream { redirect_to professor_conteudos_path, notice: "Conteúdo criado com sucesso." }
      
      format.json { render :show, status: :created, location: @conteudo }
    end
  else
    # Opcional: Se a validação falhar, você deve saber como responder.
    respond_to do |format|
      format.html { render :new, status: :unprocessable_entity }
      format.json { render json: @conteudo.errors, status: :unprocessable_entity }
      # Se usar Turbo, inclua o turbo_stream aqui também para renderizar erros
      format.turbo_stream { render turbo_stream: turbo_stream.replace('conteudo_form', partial: 'form', locals: { conteudo: @conteudo }), status: :unprocessable_entity }
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

      # 1. Resposta HTML (para requisições que não são Turbo/AJAX)
      format.html { redirect_to professor_conteudos_path, notice: "Conteúdo atualizado com sucesso." }
      
      # 🚨 2. CORREÇÃO: Resposta TURBO STREAMS
      # Quando o formulário envia via Turbo (padrão), ele recebe este comando
      # para redirecionar o navegador de volta para a Index.
      format.turbo_stream { redirect_to professor_conteudos_path, notice: "Conteúdo atualizado com sucesso." }
      
      # 3. Resposta JSON
      format.json { render :show, status: :ok, location: @conteudo }
    else
      # 4. Respostas em caso de erro (aqui o Turbo renderizaria a view edit)
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

  # Professor::ConteudosController (Deve estar assim)
private
def set_conteudo
  # 1. Prioriza o Professor logado (checa apenas os conteúdos dele)
  if current_user.is_a?(Professor) 
    @conteudo = current_user.conteudos.find(params[:id])
  # 2. Se for Admin/SuperAdmin, verifica se há um escopo de professor na URL
  elsif @professor
    @conteudo = @professor.conteudos.find(params[:id])
  # 3. Se for Admin/SuperAdmin, verifica se há um escopo de escola na URL
  elsif @escola
    @conteudo = @escola.conteudos.find(params[:id])
  # 4. Busca global (para SuperAdmin sem escopo)
  else
    @conteudo = Conteudo.find(params[:id])
  end
  
rescue ActiveRecord::RecordNotFound
  # Ação de resgate se o conteúdo não for encontrado no escopo
  redirect_to professor_conteudos_path, alert: "Conteúdo não encontrado ou você não tem permissão para acessá-lo."
end


  # Permitir professor_id para Admins/SuperAdmins
  def conteudo_params
    # ⚠️ Inclua :tipo e :bimestre na lista de parâmetros permitidos
    permitted = [:titulo, :bimestre, :descricao, :markdown, :disciplina_id, :escola_id, :tipo, { materiais:[] }]
    permitted << :professor_id if current_user.is_a?(Admin) || current_user.is_a?(SuperAdmin)
    params.require(:conteudo).permit(permitted)
  end
end