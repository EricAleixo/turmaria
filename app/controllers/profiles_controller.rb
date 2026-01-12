class ProfilesController < ApplicationController
  layout 'dashboard'

  before_action :authenticated_user_type
  before_action :set_profile_user

  # GET /profile
  def show
    if current_super_admin
      render "profiles/super_admin_profile"
    elsif current_admin
      render "profiles/admin_profile"
    elsif current_professor
      render "profiles/professor_profile"
    elsif current_aluno
      preparar_dados_notas_aluno
      render "profiles/aluno_profile"
    else
      redirect_to root_path, alert: "Acesso não permitido"
    end
  end

  # GET /profile/edit
  def edit
  end

  # PATCH/PUT /profile
  # app/controllers/profiles_controller.rb

  def update
    permitted_params = profile_params

    # Remove foto inválida (string que não é base64 nem upload)
    if permitted_params[:foto].is_a?(String) &&
      !permitted_params[:foto].start_with?('data:image')
      permitted_params = permitted_params.except(:foto)
    end


    foto_io = nil

    # === PROCESSAR FOTO BASE64 (CROP) ===
    if permitted_params[:foto].present? &&
      permitted_params[:foto].is_a?(String) &&
      permitted_params[:foto].start_with?('data:image')

      Rails.logger.info "=== PROCESSANDO FOTO BASE64 ==="
      foto_io = io_from_base64(permitted_params[:foto])
      permitted_params = permitted_params.except(:foto)
    end

    # === LÓGICA DO DEVISE (SENHA) ===
    if permitted_params[:password].blank? && permitted_params[:password_confirmation].blank?
      permitted_params = permitted_params.except(:password, :password_confirmation)
    end

    # === REMOVER FOTO ===
    if permitted_params[:remove_foto].to_i == 1 &&
      @user.respond_to?(:foto) &&
      @user.foto.attached?

      Rails.logger.info "=== REMOVENDO FOTO ANTIGA ==="
      @user.foto.purge
      permitted_params = permitted_params.except(:remove_foto)
    end

    # === UPDATE PRINCIPAL ===
    if @user.update(permitted_params)
      
      # IMPORTANTE: Recarregar o usuário do banco para ter certeza que o ID está correto
      @user.reload
      
      # === ATTACH DA FOTO ===
      if foto_io
        Rails.logger.info "=== ANEXANDO FOTO ==="
        Rails.logger.info "User ID após reload: #{@user.id}"
        Rails.logger.info "User ID class: #{@user.id.class}"
        
        @user.foto.purge if @user.foto.attached?

        @user.foto.attach(
          io: foto_io,
          filename: "profile_#{@user.class.name.downcase}_#{@user.id}.png",
          content_type: 'image/png'
        )
        
        Rails.logger.info "Foto attached? #{@user.foto.attached?}"
      end

      redirect_to profile_path, notice: 'Seu perfil foi atualizado com sucesso.'
    else
      Rails.logger.error "=== ERROS DE VALIDAÇÃO ==="
      Rails.logger.error @user.errors.full_messages.join(", ")

      render :edit, status: :unprocessable_entity
    end
  end

  private

  # =========================
  # BASE64 → STRINGIO (CORRETO)
  # =========================
  def io_from_base64(base64_data)
    image_data = base64_data.split(',')[1]
    decoded_image = Base64.decode64(image_data)
    StringIO.new(decoded_image)
  rescue => e
    Rails.logger.error "Erro ao processar base64: #{e.message}"
    nil
  end

  # =========================
  # SET USER
  # =========================
  def set_profile_user
    if professor_signed_in?
      @user = current_professor
    elsif aluno_signed_in?
      @user = current_aluno
    elsif admin_signed_in?
      @user = current_admin
    elsif coordenador_signed_in?
      @user = current_coordenador
    elsif super_admin_signed_in?
      @user = current_super_admin
    else
      redirect_to root_path, alert: 'Você precisa estar logado para acessar seu perfil.'
    end
  end

  # =========================
  # STRONG PARAMS
  # =========================
  def profile_params
    base_params = [:nome, :email, :telefone, :foto, :password, :password_confirmation, :remove_foto]
    model_name_sym = @user.model_name.singular.to_sym
    source = params.fetch(model_name_sym, params)

    if @user.is_a?(Professor)
      source.permit(*base_params, :formacao)
    elsif @user.is_a?(Aluno)
      source.permit(*base_params, :data_nascimento)
    else
      source.permit(:nome, :email, :foto, :password, :password_confirmation, :remove_foto)
    end
  end

  # =========================
  # DADOS DO ALUNO
  # =========================
  def preparar_dados_notas_aluno
    aluno = @user
    @turma_atual = aluno.turma

    @registros_notas = aluno.registros_de_notas
                            .includes(avaliacao_configuracao: [:disciplina, turma: :professores])
                            .order(created_at: :desc)

    notas_por_disciplina = {}

    @registros_notas.each do |registro|
      config = registro.avaliacao_configuracao
      next unless config&.disciplina

      disciplina_id = config.disciplina_id
      bimestre = config.bimestre || 0

      notas_por_disciplina[disciplina_id] ||= {
        disciplina: config.disciplina,
        notas_por_bimestre: { 1 => [], 2 => [], 3 => [], 4 => [] },
        professor: nil
      }

      if bimestre.between?(1, 4)
        notas_por_disciplina[disciplina_id][:notas_por_bimestre][bimestre] << registro.valor.to_f
      end

      if notas_por_disciplina[disciplina_id][:professor].nil?
        professores = config.disciplina.professores
                              .joins(:turmas)
                              .where(turmas: { id: @turma_atual&.id })
                              .distinct
        notas_por_disciplina[disciplina_id][:professor] = professores.first
      end
    end

    @disciplinas_com_medias = notas_por_disciplina.map do |_id, dados|
      medias = {}
      soma = 0.0
      count = 0

      dados[:notas_por_bimestre].each do |bimestre, notas|
        if notas.any?
          media = notas.sum / notas.size.to_f
          medias[bimestre] = media
          soma += media
          count += 1
        else
          medias[bimestre] = nil
        end
      end

      {
        disciplina: dados[:disciplina],
        professor: dados[:professor],
        medias_bimestres: medias,
        media_geral: count.positive? ? soma / count : 0.0
      }
    end

    @disciplinas_com_medias.sort_by! { |d| d[:disciplina].nome }
  end
end
