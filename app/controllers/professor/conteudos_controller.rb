class Professor::ConteudosController < ApplicationController
  layout 'dashboard'

  # Define os escopos (@professor, @escola) ANTES de tentar encontrar o @conteudo
  before_action :set_scope_objects, only: [:new, :create, :index, :show, :edit, :update, :destroy, :selecionar_turma]
  
  # Encontra o @conteudo específico (com permissão) para as ações de membro
  before_action :set_conteudo, only: %i[ show edit update destroy remove_material]

  before_action :set_escola, only: [:show, :edit, :update, :destroy]

  before_action :set_form_collections, only: [:new, :edit, :create, :update]


  # GET /conteudos
  def index
    if current_user.is_a?(SuperAdmin)
      # SuperAdmin vê TUDO
      @conteudos = Conteudo.all.order(created_at: :desc)
    elsif current_user.is_a?(Admin)
      # Admin vê apenas o conteúdo das escola que ele administra
      @conteudos = Conteudo.where(escola_id: current_user.escola.pluck(:id)).order(created_at: :desc)
    else
      @turma = Turma.find(params[:turma_id])
      @conteudos = @turma.conteudos.where(professor_id: current_user.id).order(created_at: :desc)
    end
  end


  def selecionar_turma
    @turmas = @professor.turmas.includes(:ano_letivo, :escola)
                        .order('ano_letivos.ano DESC, turmas.serie ASC, turmas.nome ASC')
  end

  # GET /conteudos/1
  def show; end

  # GET /conteudos/new
  def new
    if @professor
      @turma = Turma.find(params[:turma_id])

      @conteudo = @turma.conteudos.new(
        professor: @professor,
        escola: @escola
      )

    elsif @escola
      # Se o escopo é a escola, usa ela
      @conteudo = @escola.conteudos.new
    else
      # Para SuperAdmin/Admin sem escopo aninhado, apenas inicializa globalmente
      # Eles poderão escolher a escola/professor no formulário
      @conteudo = Conteudo.new
    end
  end

  # GET /conteudos/1/edit
  def edit
    # O @conteudo já foi carregado pelo before_action :set_conteudo
  end

  # POST /conteudos
  def create
    creator = @professor || @escola || Conteudo 

    @conteudo =
      if creator.is_a?(Class)
        Conteudo.new(conteudo_params)
      else
        creator.conteudos.new(conteudo_params)
      end

    if current_user.is_a?(Professor)
      @conteudo.professor ||= current_user
      @conteudo.escola ||= @escola
    end

    if params[:turma_id].present?
      @conteudo.turma = Turma.find(params[:turma_id])
    end

    if @conteudo.save
      redirect_to professor_turma_conteudos_path(@conteudo.turma), notice: "Conteúdo criado com sucesso."
    else
      render :new, status: :unprocessable_entity
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

        format.html { redirect_to professor_conteudos_path, notice: "Conteúdo atualizado com sucesso." }
        format.turbo_stream { redirect_to professor_conteudos_path, notice: "Conteúdo atualizado com sucesso." }
        format.json { render :show, status: :ok, location: @conteudo }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @conteudo.errors, status: :unprocessable_entity }
        # Adiciona resposta turbo para erros de update
        format.turbo_stream { render turbo_stream: turbo_stream.replace('conteudo_form', partial: 'form', locals: { conteudo: @conteudo }), status: :unprocessable_entity }
      end
    end
  end

  # DELETE /conteudos/1
  def destroy
    @conteudo.destroy!
    
    # Lógica de redirecionamento baseada no contexto
    if current_user.is_a?(SuperAdmin) && !@escola && !@professor
      # SuperAdmin em modo global
      redirect_to professor_conteudos_path, notice: "Conteúdo deletado com sucesso."
    elsif current_user.is_a?(Admin) && !@escola && !@professor
      # Admin em modo global
      redirect_to professor_conteudos_path, notice: "Conteúdo deletado com sucesso."
    elsif @escola
      # Admin/SuperAdmin com escopo de escola
      redirect_to escola_conteudos_path(@escola), notice: "Conteúdo deletado com sucesso."
    else
      # Professor logado ou Admin/SuperAdmin com escopo de professor
      redirect_to professor_conteudos_path(@professor || current_user), notice: "Conteúdo deletado com sucesso."
    end
  end

  def remove_material
    # @conteudo já é carregado pelo set_conteudo
    arquivo = @conteudo.materiais.find(params[:arquivo_id])
    arquivo.purge

    respond_to do |format|
      format.turbo_stream 
      format.html { redirect_to [current_user, @conteudo], notice: "Arquivo removido com sucesso." }
    end
  end

  def search_escola
    query = params[:q].to_s.strip
    escola = Escola.where("LOWER(nome) LIKE ?", "%#{query.downcase}%").limit(10)
    render json: escola.select(:id, :nome)
  end

  private

  def set_scope_objects
    # 1. Caso Principal: Professor logado
    if current_user.is_a?(Professor)
      @professor = current_user
      @escola = @professor.escola # Assume a primeira escola do professor como escopo
      
    # 2. Caso Secundário: Rotas aninhadas (Admin/SuperAdmin)
    elsif params[:professor_id].present?
      @professor = Professor.find(params[:professor_id])
      @escola = @professor.escola
      # TODO: Adicionar verificação se o Admin logado pode ver este professor
      
    elsif params[:escola_id].present?
      @escola = Escola.find(params[:escola_id])
      # TODO: Adicionar verificação se o Admin logado pode ver esta escola
    end
    # Se for SuperAdmin ou Admin sem rota aninhada, @professor e @escola ficam nil
  end

  # Busca e AUTORIZA o conteúdo
  def set_conteudo
    begin
      if current_user.is_a?(SuperAdmin) 
        # SuperAdmin pode ver/editar/deletar QUALQUER conteúdo
        @conteudo = Conteudo.find(params[:id])
        
      elsif current_user.is_a?(Admin)
        # Admin só pode ver/editar/deletar conteúdos DAS SUAS escola
        @conteudo = Conteudo.where(escola_id: current_user.escola.pluck(:id)).find(params[:id])
        
      elsif current_user.is_a?(Professor)
        # Professor só pode ver/editar/deletar os SEUS PRÓPRIOS conteúdos
        @conteudo = current_user.conteudos.find(params[:id])
        
      else
        # Se não for nenhum desses, nega o acesso
        raise ActiveRecord::RecordNotFound
      end
      
    rescue ActiveRecord::RecordNotFound
      # Redireciona para a index se o conteúdo não for encontrado NO ESCOPO do usuário
      redirect_to professor_conteudos_path(@professor), alert: "Conteúdo não encontrado ou você não tem permissão para acessá-lo."
    end
  end

  # Permitir :professor_id e :escola_id para Admins/SuperAdmins
  def conteudo_params
    permitted = [:titulo, :bimestre, :descricao, :markdown, :disciplina_id, :tipo, { materiais:[] }]
    
    # Apenas Admin e SuperAdmin podem definir a escola e o professor
    if current_user.is_a?(Admin) || current_user.is_a?(SuperAdmin)
      permitted << :professor_id
      permitted << :escola_id
    end
    
    params.require(:conteudo).permit(permitted)
  end
  
  # --- Métodos de Processamento de Arquivos ---
  
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

  def set_escola
    if params[:escola_id].present?
      @escola = Escola.find(params[:escola_id])
    end
  end

  def set_form_collections
    return unless @professor

    # No edit, a turma vem do conteúdo
    @turma ||= @conteudo&.turma || Turma.find_by(id: params[:turma_id])

    return unless @turma

    @bimestres = @turma.ano_letivo.numero_bimestre
    @disciplinas = @professor.disciplinas.order(:nome)
    @disciplinas_da_turma_ids = @turma.disciplinas.pluck(:id)
  end

  
end