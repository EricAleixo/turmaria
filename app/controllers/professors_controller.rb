# app/controllers/professors_controller.rb

class ProfessorsController < ApplicationController
  layout 'dashboard'
  before_action :set_professor, only: [:show, :edit, :update, :destroy]

  def index
    professors = Professor.all
    professors = professors.por_nome(params[:busca])

    @escola = Escola.find(params[:escola_id])

    # 3. Aplicar os filtros do Modal (Tipo e Formação)
    if params[:filtros].present?
      # Opções baseadas nos ENUMs do Professor.rb (precisa estar alinhado com a view)
      formacao_options = %w[mestrado doutorado pos_graduado graduado]
      tipo_options     = %w[concursado contratado]

      # Intersecção: Seleciona apenas as opções válidas que vieram no array de filtros
      formacoes_selecionadas = formacao_options & params[:filtros]
      tipos_selecionados     = tipo_options & params[:filtros]

      # Aplica o scope por_formacao
      professors = professors.por_formacao(formacoes_selecionadas) if formacoes_selecionadas.any?
      
      # Aplica o scope por_tipo (que usa a coluna tipo_professor)
      professors = professors.por_tipo(tipos_selecionados) if tipos_selecionados.any?
    end

    # 4. Atribuição final, ordenação E PAGINAÇÃO
    professors = professors.order(nome: :asc)
    
    # Adiciona a paginação: 15 itens por página.
    @professores = professors.page(params[:page]).per(15) 
  end

  def selecionar_escola
    @escolas = Escola.all
  end

  # ---

  def show
    @escola = Escola.find(params[:escola_id])

    # @professor é definido por set_professor
    @disciplinas = Disciplina.all
    @disciplinas_por_area = @disciplinas.group_by { |d| d.area_disciplina }

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
      :foto
    )
  end
end