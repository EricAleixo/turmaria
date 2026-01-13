# app/controllers/professor/notas/resultados_controller.rb

class Professor::Notas::ResultadosController < Professor::BaseController 
  before_action :set_turma_e_disciplina, only: [:show, :index, :detalhes]
  layout 'dashboard'
  before_action :authenticate_professor!


  def show
    # 1. Alunos da turma, ordenados para exibição
    @alunos = @turma.alunos.order(:nome)
    
    # 2. Médias Finais (AvaliacoesBimestrais) da disciplina/turma.
    @medias_finais = AvaliacaoBimestral.where(
      turma_id: @turma.id, 
      disciplina_id: @disciplina.id
    ).index_by { |media| [media.aluno_id, media.bimestre] }
    
    # CORREÇÃO: Usando ordenação estável (bimestre e id) em vez de uma coluna 'ordem' inexistente.
    @avaliacoes_por_bimestre = @disciplina.avaliacoes_configuracoes
                                           .order(bimestre: :asc, id: :asc)
                                           .group_by(&:bimestre)
  end


  def detalhes
    # 🚨 FIX TURBO CACHE: Garante que o Rails sempre envie o corpo da resposta (Status 200)
    expires_now 

    # 1. Encontra a Média Bimestral final que foi clicada (AvaliacaoBimestral)
    @media_bimestral = AvaliacaoBimestral.find(params[:media_bimestral])
    
    # Variáveis de contexto
    aluno = @media_bimestral.aluno
    bimestre = @media_bimestral.bimestre
    
    # 2. Busca TODAS as configurações de avaliação (colunas de nota) para o bimestre
    @avaliacoes_configuracoes = AvaliacaoConfiguracao
                                  .do_bimestre(bimestre)
                                  .where(turma: @turma, disciplina: @disciplina)
                                  .order(created_at: :asc)
                                  
    # 3. Busca os IDs das configurações
    config_ids = @avaliacoes_configuracoes.pluck(:id)
    
    # 4. Busca os Registros de Nota filtrando pelo aluno e pelas configurações
    registros = RegistroDeNota.where(aluno: aluno, avaliacao_configuracao_id: config_ids)

    # 5. Constrói um Hash para acesso rápido na view
    @registros_de_nota = registros.index_by(&:avaliacao_configuracao_id)
    
    # Renderiza o partial da modal
    render partial: 'detalhes', layout: false
    
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  def todos_alunos
  # 1. Encontra a disciplina pelo ID (e verifica se o professor a leciona)
  @disciplina = current_professor.disciplinas.find(params[:disciplina_id])
  
  # 2. Encontra TODAS as turmas que o professor leciona E que estão associadas a esta disciplina
  #    COLETA APENAS OS IDs DISTINTOS PRIMEIRO para evitar o erro do PostgreSQL.
  turma_ids_distintos = current_professor.turmas
                                         .joins(:disciplinas)
                                         .where(disciplinas: { id: @disciplina.id })
                                         .distinct
                                         .pluck(:id)
                                         
  # 3. Usa os IDs para buscar os objetos Turma e aplica a ordenação.
  #    Isso evita o conflito do DISTINCT e ORDER BY no JOIN complexo.
  @turmas_da_disciplina = Turma.where(id: turma_ids_distintos).order(:nome)
  
  # 4. Define a lista de IDs para buscar as médias em massa
  #    Usamos a array que já coletamos no passo 2.
  turma_ids = turma_ids_distintos 
  
  # 5. Busca as Médias Finais Bimestrais de todos os alunos nessas turmas
  # Índexar as médias por [turma_id, aluno_id, bimestre] para fácil acesso na view
  @medias_finais_por_turma = AvaliacaoBimestral.where(
    turma_id: turma_ids, 
    disciplina_id: @disciplina.id
  ).index_by { |media| [media.turma_id, media.aluno_id, media.bimestre] }
  
  # A view (todosAlunos.html.erb) será renderizada automaticamente.
rescue ActiveRecord::RecordNotFound
  redirect_to professor_turmas_path, alert: "Disciplina não encontrada ou você não está associado a ela."
end

  def selecionar_disciplina
    # Busca todas as disciplinas do professor
    @disciplinas = current_professor.disciplinas.distinct

    # Cria um hash para agrupar turmas por disciplina
    @disciplinas_com_turmas = {}

    @disciplinas.each do |disciplina|
      # Busca turmas que:
      # 1. O professor leciona
      # 2. Têm essa disciplina associada
      turmas = current_professor.turmas
                                .joins(:disciplinas)
                                .where(disciplinas: { id: disciplina.id })
                                .includes(:alunos, :ano_letivo)
                                .distinct
                                .order(:serie, :nome)

      # Monta dados enriquecidos de cada turma
      turmas_data = turmas.map do |turma|
        {
          turma: turma,
          total_alunos: turma.alunos.count,
          ano_letivo: turma.ano_letivo&.ano
        }
      end

      @disciplinas_com_turmas[disciplina] = turmas_data if turmas_data.any?
    end
  end
  
  private

  def set_turma_e_disciplina
    @turma = current_professor.turmas.find(params[:turma_id])
    @disciplina = Disciplina.find(params[:disciplina_id])
    
    unless current_professor.disciplinas.include?(@disciplina)
      redirect_to professor_turmas_path, alert: 'Você não está autorizado a acessar esta disciplina.'
      return
    end

  rescue ActiveRecord::RecordNotFound
    redirect_to professor_turmas_path, alert: 'Turma ou Disciplina não encontrada ou você não tem acesso.'
  end
end