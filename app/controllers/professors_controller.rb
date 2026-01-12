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

  # ---

  def show
    @escola = Escola.find(params[:escola_id])

    # @professor é definido por set_professor
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

    # Preenche confirmed_at para que o Devise permita o login imediato.
    @professor.confirmed_at = Time.current
    
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

  def professor_params
    permitted = params.require(:professor).permit(
      :nome, :email, :password, :password_confirmation, :cpf,
      :telefone, :escola_id, :tipo_professor, :formacao,
      :data_nascimento, :foto
    )

    # Converte Base64 para ActiveStorage
    if params[:professor][:foto_base64].present?
      data_uri = params[:professor].delete(:foto_base64)
      content_type = data_uri[%r{data:(.*?);base64}, 1]
      encoded_image = data_uri.split(',')[1]
      io = StringIO.new(Base64.decode64(encoded_image))
      io.class.class_eval { attr_accessor :original_filename, :content_type }
      io.original_filename = "foto.png"
      io.content_type = content_type
      permitted[:foto] = io
    end

    permitted
  end

end