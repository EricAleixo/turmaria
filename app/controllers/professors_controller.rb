class ProfessorsController < ApplicationController
  layout 'dashboard'
  before_action :set_professor, only: [:show, :edit, :update, :destroy]

  def index
    @escola = Escola.find(params[:escola_id])

    if (current_user.is_a?(SuperAdmin))
          @professores = Professor.all
                            .por_nome(params[:busca])
                            .por_formacao(params[:formacao])
                            .por_tipo(params[:tipo])
    else
          @professores = @escola.professors
                            .por_nome(params[:busca])
                            .por_formacao(params[:formacao])
                            .por_tipo(params[:tipo])
    end



    if params[:filtros].present?
      formacoes = %w[mestrado doutorado pos_graduados graduados] & params[:filtros]
      tipos     = %w[concursado contratado] & params[:filtros]

      @professores = @professores.por_formacao(formacoes) if formacoes.any?
      @professores = @professores.por_tipo(tipos) if tipos.any?
    end
  end

  def show
    # Não precisa de código aqui, @professor é definido por set_professor
    @disciplinas = Disciplina.all

    @disciplinas_por_area = @disciplinas.group_by { |d| d.area }

    @conteudos_por_disciplina = Conteudo.includes(:disciplina).group_by(&:disciplina)

  end

  def update_conteudos
  @professor = Professor.find(params[:id])
  @professor.conteudo_ids = params[:conteudo_ids] || []
  redirect_to @professor, notice: "Conteúdos atualizados com sucesso!"
  end


  def new
    @professor = Professor.new
  end

  def create
    @professor = Professor.new(professor_params)

    # 🛑 MUDANÇA PRINCIPAL: Preenche confirmed_at para que o Devise permita o login imediato.
    # Isso evita o erro 401 Unauthorized, pois a conta é considerada confirmada.
    @professor.confirmed_at = Time.current
    
    if @professor.save
      redirect_to @professor, notice: "Professor criado com sucesso!"
    else
      render :new, status: :unprocessable_entity
    end
  end


  def edit
    # Não precisa de código aqui, @professor é definido por set_professor
  end

  def update
    # 🛑 MUDANÇA SECUNDÁRIA: Permite a atualização da senha. 
    # Usar .update com 'password' em branco pode falhar em alguns cenários.
    # O Devise tem um helper para lidar com senhas opcionais.
    
    # 🛑 CORREÇÃO NO UPDATE (Se a senha for opcional na atualização)
    # Se 'password' estiver vazio nos params, removemos para evitar que o Devise
    # tente salvar um hash vazio ou falhe nas validações.
    
    update_params = professor_params
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
    # 🛑 MUDANÇA: Adiciona :password_confirmation
    # Embora não esteja no seu 'permit' original, Devise frequentemente o espera
    # para garantir que a senha foi digitada corretamente ao criar/editar.
    params.require(:professor).permit(:nome, :email, :password, :password_confirmation, :cpf, :telefone, :escola_id, :tipo_professor, :formacao)
  end
end