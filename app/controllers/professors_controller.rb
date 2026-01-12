# app/controllers/professors_controller.rb

class ProfessorsController < ApplicationController
  layout 'dashboard'
  before_action :set_professor, only: [:show, :edit, :update, :destroy]

  def index
    # =========================
    # 1. Definição do escopo base
    # =========================
    professors =
      if current_user.is_a?(Admin)
        @escola = Escola.find(params[:escola_id])
        @escola.professors
      elsif current_user.is_a?(SuperAdmin)
        if params[:escola_id].present?
          @escola = Escola.find(params[:escola_id])
          @escola.professors
        else
          Professor.all
        end
      else
        Professor.none
      end

    # =========================
    # 2. Busca por nome
    # =========================
    professors = professors.por_nome(params[:busca]) if params[:busca].present?

    # =========================
    # 3. Filtros do modal
    # =========================
    if params[:filtros].present?
      formacao_options = %w[mestrado doutorado pos_graduado graduado]
      tipo_options     = %w[concursado contratado]

      formacoes_selecionadas = formacao_options & params[:filtros]
      tipos_selecionados     = tipo_options & params[:filtros]

      professors = professors.por_formacao(formacoes_selecionadas) if formacoes_selecionadas.any?
      professors = professors.por_tipo(tipos_selecionados) if tipos_selecionados.any?
    end

    # =========================
    # 4. Ordenação e paginação
    # =========================
    @professores = professors
                     .order(nome: :asc)
                     .page(params[:page])
                     .per(15)
  end

  def selecionar_escola
    @escolas = current_admin.escolas
  end

  def show
    @escola = Escola.find(params[:escola_id])
    @disciplinas = @escola.disciplinas
    @disciplinas_por_area = @disciplinas.group_by { |d| d.area_disciplina }
    @conteudos = @professor.conteudos
  end

  def update_conteudos
    @professor = Professor.find(params[:id])
    @professor.conteudo_ids = params[:conteudo_ids] || []
    redirect_to @professor, notice: "Conteúdos atualizados com sucesso!"
  end

  def new
    @escola = Escola.find(params[:escola_id])
    @professor = Professor.new
  end

  def create
    @professor = Professor.new(professor_params)
    @escola = Escola.find(params[:escola_id])
    @professor.escola = @escola
    @professor.confirmed_at = Time.current
    
    # Processa foto em Base64
    process_base64_foto(@professor)
    
    if @professor.save
      redirect_to @professor, notice: "Professor criado com sucesso!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # @professor é definido por set_professor
  end

  def update
    update_params = professor_params
    
    # Se a senha estiver vazia, remove os campos de senha
    if update_params[:password].blank?
      update_params = update_params.except(:password, :password_confirmation)
    end
    
    # CORRIGIDO: Processa foto Base64 ANTES de tentar atualizar
    if params[:professor][:foto_base64].present?
      process_base64_foto(@professor)
    end
    
    # Remove foto_base64 dos params para não dar erro
    update_params = update_params.except(:foto_base64)
    
    if @professor.update(update_params)
      redirect_to @professor, notice: "Professor atualizado com sucesso!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @professor.destroy
    redirect_to professors_path, notice: "Professor excluído com sucesso!"
  end

  def update_disciplinas
    @professor = Professor.find(params[:id])
    @professor.disciplina_ids = params[:disciplina_ids] || [] 
    redirect_to @professor, notice: "Disciplinas atualizadas com sucesso!"
  end

  private

  def set_escola
    @escola = current_admin.escolas.find(params[:escola_id])
  end

  def set_professor
    @professor = Professor.find(params[:id])
  end

  # CORRIGIDO: Método separado para processar Base64
  def process_base64_foto(professor)
    return unless params[:professor][:foto_base64].present?
    
    begin
      data_uri = params[:professor][:foto_base64]
      
      # Extrai tipo de conteúdo e dados
      content_type = data_uri[%r{data:(.*?);base64}, 1]
      encoded_image = data_uri.split(',')[1]
      
      # Decodifica Base64
      decoded_image = Base64.decode64(encoded_image)
      
      # Cria arquivo temporário
      tempfile = Tempfile.new(['foto', '.png'])
      tempfile.binmode
      tempfile.write(decoded_image)
      tempfile.rewind
      
      # Anexa ao professor
      professor.foto.attach(
        io: tempfile,
        filename: "foto_professor_#{Time.current.to_i}.png",
        content_type: content_type || 'image/png'
      )
      
      tempfile.close
      tempfile.unlink
      
      Rails.logger.info "📸 Foto anexada com sucesso via Base64"
    rescue => e
      Rails.logger.error "❌ Erro ao processar foto Base64: #{e.message}"
    end
  end

  def professor_params
    params.require(:professor).permit(
      :nome, 
      :email, 
      :password, 
      :password_confirmation, 
      :cpf,
      :telefone, 
      :escola_id, 
      :tipo_professor, 
      :formacao,
      :data_nascimento,
      :foto,
      :foto_base64  # Permitir mas não processar aqui
    )
  end
end