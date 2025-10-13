class Professor::Notas::RegistrosController < ApplicationController
  # before_action :authenticate_professor! 
  before_action :set_turma_disciplina_e_configuracao
  layout 'dashboard'
  before_action :authenticate_professor!
  
  # Ação NEW: Exibe o formulário de lançamento de notas para todos os alunos
  def new
    # Carrega todos os alunos da turma
    @alunos = @turma.alunos.order(:nome)
    
    # Prepara os objetos RegistroDeNota para o formulário
    # Itera sobre cada aluno e encontra ou constrói o RegistroDeNota
    @registros = @alunos.map do |aluno|
      RegistroDeNota.find_or_initialize_by(
        aluno: aluno,
        avaliacao_configuracao: @avaliacao_configuracao
      )
    end
    
    # Cria um objeto pai artificial para o form_with usar (simples Hash ou Struct)
    @registros_form = OpenStruct.new(registros: @registros)
  end

  # Ação CREATE: Salva as notas submetidas
  def create
    # Acessa o hash de notas submetido pelo formulário
    registros_data = registros_params[:registros]

    # Itera sobre os dados e salva/atualiza cada registro individualmente
    success = true
    ActiveRecord::Base.transaction do
      registros_data.each do |aluno_id, data|
        # Busca ou cria o registro
        registro = RegistroDeNota.find_or_initialize_by(
          aluno_id: aluno_id,
          avaliacao_configuracao: @avaliacao_configuracao
        )
        
        # Atualiza o valor. Se o valor estiver em branco, remove a nota (opcional, mas comum)
        valor_nota = data[:valor].presence 
        
        if valor_nota
          registro.valor = valor_nota
          registro.data_registro = Date.current # Ou use um campo de data no formulário
          unless registro.save
            success = false
            # O ideal é coletar todos os erros e exibi-los
            raise ActiveRecord::Rollback 
          end
        elsif registro.persisted?
          # Se o valor foi removido (deixado em branco), exclui o registro
          registro.destroy 
        end
      end
    end

    if success
      # CORREÇÃO DE ROTA: Usando professor_turma_disciplina_notas_avaliacoes_path
      redirect_to professor_turma_disciplina_notas_avaliacoes_path(@turma, @disciplina), 
                  notice: 'Notas salvas e/ou atualizadas com sucesso!'
    else
      # Se falhar, você precisa reconstruir a tela NEW com os erros
      flash.now[:alert] = 'Erro ao salvar as notas. Verifique os valores.'
      # TODO: Recarregar @alunos e @registros para renderizar :new novamente
      @alunos = @turma.alunos.order(:nome)
      @registros = @alunos.map do |aluno|
        RegistroDeNota.find_or_initialize_by(
          aluno: aluno,
          avaliacao_configuracao: @avaliacao_configuracao
        )
      end
      @registros_form = OpenStruct.new(registros: @registros)
      render :new, status: :unprocessable_entity
    end
  end

  private
  
  # Define o contexto Turma, Disciplina e AvaliacaoConfiguracao
  def set_turma_disciplina_e_configuracao
    @turma = Turma.find(params[:turma_id])
    @disciplina = Disciplina.find(params[:disciplina_id])
    # CORREÇÃO DE ROTA: Usa params[:avaliaco_id] (sem o 'a' no final)
    @avaliacao_configuracao = AvaliacaoConfiguracao.find(params[:avaliaco_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: 'Recurso não encontrado.' 
  end

  # Strong Parameters para lidar com múltiplos registros aninhados
  # Aceita um hash onde a chave é o aluno_id e o valor é um hash com a nota
  def registros_params
  # Permite que 'registros' seja um Hash onde as chaves (aluno_id) são arbitrárias
  # e o valor é um hash que contém o 'valor' da nota.
  params.require(:open_struct).permit(registros: data_para_salvar) 
  end

  def data_para_salvar
  # Permite todos os IDs de aluno que vierem no hash 'registros'
  params.require(:open_struct).fetch(:registros, {}).keys.map do |aluno_id|
    { aluno_id.to_sym => [:valor] }
  end.reduce({}, :merge)
  end
end