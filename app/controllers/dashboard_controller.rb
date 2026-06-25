class DashboardController < ApplicationController
  # 1. Lógica de autenticação flexível (Mantida)
  before_action :authenticate_any_user!

  
  
  def index
    if current_super_admin
      load_super_admin_dashboard_data
    elsif current_admin
      load_admin_dashboard_data 
    elsif current_professor
      load_professor_dashboard_data
    elsif current_aluno
      load_aluno_dashboard_data
    end
  end

  def professores_da_turma
    load_aluno_data_for_pages
    return if performed?
    
    load_professores_da_turma_data

    @titulo_pagina = "Meus Professores | #{@aluno.nome}"
    render 'aluno/meus_professores'
  end

  def minhas_notas
    load_aluno_data_for_pages
    return if performed?
    
    # Carrega todas as notas
    @registros_notas = @aluno.registros_de_notas
                         .includes(avaliacao_configuracao: [:disciplina])
                         .order(created_at: :desc)
    
    # NOVO: Carrega o Resumo da Média por Disciplina
    # Passamos apenas o ID do aluno, e não a coleção, para uma consulta mais limpa no método privado
    @media_por_disciplina = calcular_media_por_disciplina(@aluno.id) 
    
    @titulo_pagina = "Minhas Notas | #{@aluno.nome}"
    render 'aluno/minhas_notas'
  end
  
  def minha_frequencia
    load_aluno_data_for_pages
  return if performed? 
  
  # 1. Carrega o HISTÓRICO (Consulta Limpa, sem o GROUP BY que falhava)
  @registros_frequencia = FrequenciaAluno.includes(frequencia: [:disciplina, :turma])
                                         .where(aluno_id: @aluno.id)
                                         # O ORDER BY da sua query original era incompatível com o GROUP BY seguinte
                                         # Mas como esta consulta só carrega o histórico, podemos manter um ORDER BY:
                                         .order('frequencias.data_aula DESC') 
  
  # =========================================================
  # 💡 NOVO CÁLCULO: Frequência Percentual por Disciplina 💡
  #    -> Usamos uma NOVA CONSULTA, focada APENAS em obter dados agregados.
  # =========================================================
  
  aluno_id = @aluno.id # Cache o ID para a consulta
  
  # 1. Agrupar os registros. Adicionamos 'disciplinas.id' ao GROUP BY para evitar a falha
  # e garantimos que apenas os campos agrupados e agregados são usados no SELECT.
  frequencia_agrupada = FrequenciaAluno
    .joins(frequencia: :disciplina)
    .where(aluno_id: aluno_id)
    .group('disciplinas.id', 'disciplinas.nome', 'disciplinas.cor_nome')
    .select(
      'disciplinas.id AS disciplina_id',
      'disciplinas.nome AS nome',
      'disciplinas.cor_nome AS cor',
      'COUNT(frequencia_alunos.id) AS total_aulas',
      "SUM(CASE WHEN frequencia_alunos.status = 'presente' THEN 1 ELSE 0 END) AS total_presencas"
    )


  # 2. Calcular o percentual e formatar para a View (melhoramos a busca por cor)
  @frequencia_por_disciplina = frequencia_agrupada.map do |item|
    total_aulas = item.total_aulas.to_i
    total_presencas = item.total_presencas.to_i
    
    percentual = total_aulas.zero? ? 0.0 : ((total_presencas.to_f / total_aulas) * 100).round(1)
    
    # Buscamos a cor usando o ID retornado pela consulta agrupada.
    # Isso é mais eficiente do que buscar no banco novamente com Disciplina.find(id)
    # se o objeto Discipline já estiver carregado em memória.
    # Caso 'cor' não esteja na lista de atributos do `item`, mantenha a lógica de buscar a cor separadamente.
    
    # Vamos manter a busca por cor simples, usando a associação do primeiro registro,
    # ou usando uma busca mais direta:
    
    disciplina_obj = Disciplina.find_by(id: item.disciplina_id)
    
    {
      nome: item.nome,
      total_aulas: total_aulas,
      total_presencas: total_presencas,
      percentual: percentual,
      cor: disciplina_obj&.cor_nome || '#10B981' # Fallback da cor
    }
  end
  # =========================================================
  
  @titulo_pagina = "Minha Frequência | #{@aluno.nome}"
  render 'aluno/minha_frequencia'
  end

  def minhas_atividades
    load_aluno_data_for_pages
    return if performed?
    
    # ----------------------------------------------------------------------
    # 💡 Lógica para carregar os Conteúdos (Atividades) para o Aluno
    # ----------------------------------------------------------------------
    
    if @turma_atual.present?
      # 1. Encontra todas as disciplinas associadas à turma do aluno.
      disciplina_ids = @turma_atual.disciplinas.pluck(:id)
      
      # 2. Carrega todos os Conteúdos (Atividades) que pertencem a essas disciplinas.
      @atividades = Conteudo.includes(:disciplina)
                            .where(disciplina_id: disciplina_ids)
                            .order(created_at: :desc)
    else
      @atividades = []
    end
    
    @titulo_pagina = "Minhas Atividades | #{@aluno.nome}"
    redirect_to aluno_minhas_atividades_e_path # Renderiza a view na pasta aluno/
  end

  def filtrar_calendario
    # Verificar autenticação
    unless current_professor
      render json: { error: 'Unauthorized' }, status: :unauthorized
      return
    end
    
    disciplina_id = params[:disciplina_id]
    turma_id = params[:turma_id]
    
    # Frequências do professor (base)
    frequencias = Frequencia.where(professor_id: current_professor.id)
    
    # Aplicar filtros se existirem
    frequencias = frequencias.where(disciplina_id: disciplina_id) if disciplina_id.present?
    frequencias = frequencias.where(turma_id: turma_id) if turma_id.present?
    
    # Filtrar por mês atual
    inicio_mes = Date.current.beginning_of_month
    fim_mes = Date.current.end_of_month
    frequencias_mes = frequencias.where(data_aula: inicio_mes..fim_mes)
    
    # Calcular calendário de presença
    calendario_presenca = frequencias_mes
      .joins(:frequencia_alunos)
      .group("frequencias.data_aula")
      .pluck(
        "frequencias.data_aula",
        Arel.sql("SUM(CASE WHEN frequencia_alunos.status = 'presente' THEN 1 ELSE 0 END)"),
        Arel.sql("COUNT(frequencia_alunos.id)")
      )
      .map do |data_aula, presentes, total|
        {
          dia: data_aula.day,
          taxa_presenca: ((presentes.to_f / total) * 100).round
        }
      end
    
    render json: { calendario_presenca: calendario_presenca }
  rescue => e
    render json: { error: e.message }, status: :internal_server_error
  end

  private

  def calcular_media_por_disciplina(aluno_id)
    tabela_notas = RegistroDeNota.table_name

    resumo_agregado = RegistroDeNota
      .where(aluno_id: aluno_id)
      .where.not(valor: nil) # exclui registros de conceito
      .joins(avaliacao_configuracao: :disciplina)
      .group('disciplinas.nome', 'disciplinas.cor_nome', 'disciplinas.id')
      .select(
        'disciplinas.nome AS nome',
        'disciplinas.cor_nome AS cor_nome',
        "COUNT(#{tabela_notas}.id) AS provas_lancadas",
        "AVG(#{tabela_notas}.valor) AS media",
        "SUM(#{tabela_notas}.valor) AS total_notas"
      )
      .order('disciplinas.nome ASC')

    resumo_agregado.map do |item|
      media_calculada = item.media.to_f
      {
        nome:            item.nome,
        cor:             item.cor_nome || '#10B981',
        media:           media_calculada.round(1),
        provas_lancadas: item.provas_lancadas.to_i,
        total_notas:     item.total_notas.to_f.round(1)
      }
    end
  end

  def load_professores_da_turma_data
    if @turma_atual.nil?
      @professores_da_turma = []
      return 
    end

    # Consulta Validada e Confirmada pelas suas Associações
    @professores_da_turma = @turma_atual.professores.includes(disciplinas: :turmas)
  end


  def load_aluno_data_for_pages
    # Garante que é um aluno logado para evitar NoMethodError em find_by
    unless current_aluno
      redirect_to dashboard_path, alert: "Acesso negado: Somente alunos podem ver esta página."
      return
    end

    # Carrega o objeto Aluno e pré-carrega a associação 'turma' (singular!)
    @aluno = Aluno.includes(turma: [:ano_letivo]).find_by(id: current_aluno.id)
    
    if @aluno.nil?
      redirect_to dashboard_path, alert: 'Seu perfil de aluno não foi encontrado ou está incompleto.'
      return
    end
    
    @turma_atual = @aluno.turma # Objeto Turma ou nil
  end

  
 def load_aluno_dashboard_data
  @aluno = Aluno.includes(turma: [:ano_letivo]).find_by(id: current_aluno.id)

  if @aluno.nil?
    @frequencia_percentual  = '0.0%'
    @total_faltas           = 0
    @media_geral_notas      = 0.0
    @ultimas_faltas         = []
    @turma_atual            = nil
    @titulo_pagina          = "Dashboard | Aluno Não Encontrado"
    return
  end

  @turma_atual = @aluno.turma

  # Frequência
  total_registros       = FrequenciaAluno.where(aluno_id: @aluno.id).count
  faltas_registradas    = FrequenciaAluno.where(aluno_id: @aluno.id).where.not(status: 'presente').count
  presencas_registradas = total_registros - faltas_registradas

  @total_aulas      = total_registros
  @total_presencas  = presencas_registradas
  @total_faltas     = faltas_registradas
  @perc_presencas   = total_registros.zero? ? 0.0 : ((@total_presencas.to_f / total_registros) * 100).round(1)
  @perc_faltas      = total_registros.zero? ? 0.0 : ((@total_faltas.to_f / total_registros) * 100).round(1)
  @frequencia_percentual = @perc_presencas

  # Notas — exclui registros de conceito (valor nil)
  notas_registradas = RegistroDeNota.where(aluno_id: @aluno.id).where.not(valor: nil)

  if notas_registradas.exists?
    media_simples      = notas_registradas.average(:valor)
    @media_geral_notas = (media_simples || 0.0).round(1)
  else
    @media_geral_notas = 0.0
  end

  # Últimas faltas
  @ultimas_faltas = FrequenciaAluno.where(aluno_id: @aluno.id)
                                   .where.not(status: 'presente')
                                   .includes(frequencia: [:turma, :disciplina])
                                   .order(created_at: :desc)
                                   .limit(10)

  # Média por disciplina
  @medias_por_disciplina = notas_registradas
    .joins(avaliacao_configuracao: :disciplina)
    .group('disciplinas.nome')
    .average(:valor)
    .map { |nome, media| [nome, (media || 0.0).round(1)] }

    # Conceitos por disciplina (para turmas de conceito)
  if @turma_atual&.usa_conceito?
    config_ids = AvaliacaoConfiguracao
                  .where(turma: @turma_atual)
                  .pluck(:id)

    @conceitos_por_disciplina = RegistroDeNota
      .where(aluno_id: @aluno.id, avaliacao_configuracao_id: config_ids)
      .where.not(conceito: nil)
      .joins(avaliacao_configuracao: :disciplina)
      .select("disciplinas.nome AS disciplina_nome, registros_de_notas.conceito, registros_de_notas.created_at")
      .order("disciplinas.nome ASC, registros_de_notas.created_at DESC")
      .each_with_object({}) { |r, h| h[r.disciplina_nome] ||= r.conceito }
      .map { |disciplina, conceito| { disciplina: disciplina, conceito: conceito } }
  end

  # Frequência mensal
  registros_frequencia_mensal = FrequenciaAluno.where(aluno_id: @aluno.id)
    .joins(frequencia: :disciplina)
    .group_by { |fa| fa.frequencia.data_aula.strftime('%m-%Y') }
    .sort_by { |month_year, _| Date.strptime(month_year, '%m-%Y') }

  @frequencia_mensal = registros_frequencia_mensal.map do |month_year, registros|
    {
      mes_ano:  month_year,
      presencas: registros.count { |r| r.status == 'presente' },
      faltas:    registros.count { |r| r.status == 'falta' || r.status == 'justificada' }
    }
  end

  # Evolução da média geral mensal
  @evolucao_notas = notas_registradas
    .joins(avaliacao_configuracao: :disciplina)
    .group_by { |nota| nota.created_at.strftime('%m-%Y') }
    .sort_by { |month_year, _| Date.strptime(month_year, '%m-%Y') }
    .map do |month_year, notas|
      total_valor  = notas.sum { |n| n.valor.to_f }
      media_mensal = total_valor / notas.count.to_f
      [month_year, media_mensal.round(1)]
    end

  @titulo_pagina = "Dashboard | #{@aluno.nome}"
end
  # ===================================================================


  # Método para garantir que o acesso é liberado (Mantido)
  def authenticate_any_user!
    unless super_admin_signed_in? || admin_signed_in? || professor_signed_in? || aluno_signed_in?
      redirect_to new_user_session_path, alert: 'Acesso negado. Faça login para acessar o painel.'
    end
  end
  
  # 2. Método: Carrega dados para Super Admin (Mantido Intacto)
  def load_super_admin_dashboard_data
    # System-wide statistics
    @total_schools = Escola.count
    @total_classes = Turma.count
    @total_teachers = Professor.count rescue 0
    @total_students = Aluno.count
    @total_admins = Admin.count
    @total_super_admins = SuperAdmin.count
    
    # Recent activity metrics
    @schools_this_month = Escola.where('created_at >= ?', 1.month.ago).count
    @students_this_month = Aluno.where('created_at >= ?', 1.month.ago).count
    @classes_this_month = Turma.where('created_at >= ?', 1.month.ago).count
    
    # Average calculations
    @avg_students_per_school = @total_schools > 0 ? (@total_students.to_f / @total_schools).round(1) : 0
    @avg_classes_per_school = @total_schools > 0 ? (@total_classes.to_f / @total_schools).round(1) : 0
    @avg_students_per_class = @total_classes > 0 ? (@total_students.to_f / @total_classes).round(1) : 0
    
    # Top performing schools (by student count)
    @top_schools = Escola.joins(:alunos)
                         .group('escolas.id, escolas.nome')
                         .order('COUNT(alunos.id) DESC')
                         .limit(5)
                         .pluck('escolas.nome', 'COUNT(alunos.id)')
    
    # Recent schools
    @recent_schools = Escola.order(created_at: :desc).limit(5)
    
    # Recent students (Se não for usado na tela do Super Admin, pode ser removido)
    @recent_students = Aluno.includes(:escola).order(created_at: :desc).limit(5) 
    
    # System growth data for charts
    @monthly_growth = calculate_monthly_growth
  end

  def load_admin_dashboard_data
  escola_ids = current_admin.escola_ids

  cache_key = "admin_dashboard_#{current_admin.id}_#{current_admin.updated_at.to_i}"

  cached = Rails.cache.fetch(cache_key, expires_in: 5.minutes) do

    if escola_ids.empty?
      total_escolas = total_alunos = total_turmas = total_publicas = total_privadas = total_professores = 0
      escolas_mes = alunos_mes = 0
      labels = crescimento_alunos = crescimento_turmas = []
      maiores_escolas = escolas_recentes = todas_escolas = escolas_grafico = []
    else
      result = ActiveRecord::Base.connection.execute(<<~SQL)
        SELECT
          COUNT(*) as total,
          COALESCE(SUM(alunos_count), 0) as total_alunos,
          COALESCE(SUM(turmas_count), 0) as total_turmas,
          COALESCE(SUM(CASE WHEN tipo = 'publica' THEN 1 ELSE 0 END), 0) as publicas,
          COALESCE(SUM(CASE WHEN tipo = 'privada' THEN 1 ELSE 0 END), 0) as privadas
        FROM escolas
        WHERE id IN (#{escola_ids.map { |id| "'#{id}'" }.join(',')})
      SQL

      row = result.first
      total_escolas  = row['total'].to_i
      total_alunos   = row['total_alunos'].to_i
      total_turmas   = row['total_turmas'].to_i
      total_publicas = row['publicas'].to_i
      total_privadas = row['privadas'].to_i

      total_professores = Professor.where(escola_id: escola_ids).count

      inicio_mes  = Date.today.beginning_of_month
      escolas_mes = Escola.where(id: escola_ids).where('created_at >= ?', inicio_mes).count
      alunos_mes  = Aluno.where(escola_id: escola_ids).where('created_at >= ?', inicio_mes).count

      seis_meses_atras = 6.months.ago.beginning_of_month

      alunos_por_mes = Aluno.where(escola_id: escola_ids)
                            .where('created_at >= ?', seis_meses_atras)
                            .group("DATE_TRUNC('month', created_at)")
                            .count

      turmas_por_mes = Turma.where(escola_id: escola_ids)
                            .where('created_at >= ?', seis_meses_atras)
                            .group("DATE_TRUNC('month', created_at)")
                            .count

      acumulado_alunos = Aluno.where(escola_id: escola_ids).where('created_at < ?', seis_meses_atras).count
      acumulado_turmas = Turma.where(escola_id: escola_ids).where('created_at < ?', seis_meses_atras).count

      meses_pt = %w[Jan Fev Mar Abr Mai Jun Jul Ago Set Out Nov Dez]
      labels = []
      crescimento_alunos = []
      crescimento_turmas = []

      6.downto(1) do |i|
        data = i.months.ago.beginning_of_month
        labels << meses_pt[data.month - 1]
        acumulado_alunos += alunos_por_mes[data] || 0
        acumulado_turmas += turmas_por_mes[data] || 0
        crescimento_alunos << acumulado_alunos
        crescimento_turmas << acumulado_turmas
      end

      maiores_escolas  = Escola.where(id: escola_ids).order(alunos_count: :desc).limit(5)
      escolas_recentes = Escola.where(id: escola_ids).order(created_at: :desc).limit(5)
      todas_escolas    = Escola.where(id: escola_ids).order(:nome)
      escolas_grafico  = Escola.where(id: escola_ids).order(alunos_count: :desc).pluck(:nome, :alunos_count)
    end

    {
      total_escolas:, total_alunos:, total_turmas:, total_professores:,
      total_publicas:, total_privadas:,
      escolas_mes:, alunos_mes:,
      labels:, crescimento_alunos:, crescimento_turmas:,
      maiores_escolas:, escolas_recentes:, todas_escolas:, escolas_grafico:
    }
  end

  @minhas_escolas    = cached[:total_escolas]
  @total_alunos      = cached[:total_alunos]
  @total_turmas      = cached[:total_turmas]
  @total_professores = cached[:total_professores]
  @escolas_publicas  = cached[:total_publicas]
  @escolas_privadas  = cached[:total_privadas]
  @escolas_mes_atual = cached[:escolas_mes]
  @alunos_mes_atual  = cached[:alunos_mes]
  @crescimento_labels  = cached[:crescimento_labels] || cached[:labels]
  @crescimento_alunos  = cached[:crescimento_alunos]
  @crescimento_turmas  = cached[:crescimento_turmas]

  @media_alunos_escola = @minhas_escolas > 0 ? (@total_alunos.to_f  / @minhas_escolas).round(1) : 0
  @media_turmas_escola = @minhas_escolas > 0 ? (@total_turmas.to_f  / @minhas_escolas).round(1) : 0
  @media_alunos_turma  = @total_turmas   > 0 ? (@total_alunos.to_f  / @total_turmas).round(1)   : 0
  @percentual_publicas = @minhas_escolas > 0 ? ((@escolas_publicas.to_f / @minhas_escolas) * 100).round(1) : 0
  @percentual_privadas = @minhas_escolas > 0 ? ((@escolas_privadas.to_f / @minhas_escolas) * 100).round(1) : 0

  # Objetos ActiveRecord fora do cache — não são serializáveis
  @maiores_escolas  = cached[:maiores_escolas].presence  || Escola.where(id: escola_ids).order(alunos_count: :desc).limit(5)
  @escolas_recentes = cached[:escolas_recentes].presence || Escola.where(id: escola_ids).order(created_at: :desc).limit(5)
  @todas_escolas    = cached[:todas_escolas].presence    || Escola.where(id: escola_ids).order(:nome)

  escolas_grafico  = cached[:escolas_grafico]
  @escolas_nomes   = escolas_grafico.map(&:first)
  @escolas_alunos  = escolas_grafico.map(&:last)
end

  # 3. Método: Carrega dados para Professor (Mantido Intacto)
  def load_professor_dashboard_data
    # 1. Dados do Professor
    @professor_nome = current_professor.nome
    
    # Captura os filtros da URL
    @disciplina_selecionada_id = params[:disciplina_id]
    @turma_selecionada_id = params[:turma_id]
    
    # 2. Frequências do professor (base)
    frequencias = Frequencia.where(professor_id: current_professor.id)
    
    # Aplicar filtros se existirem
    frequencias = frequencias.where(disciplina_id: @disciplina_selecionada_id) if @disciplina_selecionada_id.present?
    frequencias = frequencias.where(turma_id: @turma_selecionada_id) if @turma_selecionada_id.present?
    
    @turmas_ativas = frequencias.distinct.pluck(:turma_id).count
    @disciplinas_contagem = frequencias.distinct.pluck(:disciplina_id).count
    
    # 3. Alunos únicos nas turmas do professor
    turma_ids = frequencias.distinct.pluck(:turma_id)
    @alunos_unicos = Aluno.where(turma_id: turma_ids).count
    
    # 4. Média de presença (global do mês)
    inicio_mes = Date.current.beginning_of_month
    fim_mes = Date.current.end_of_month
    frequencias_mes = frequencias.where(data_aula: inicio_mes..fim_mes)
    
    presencas_mes = FrequenciaAluno
      .joins(:frequencia)
      .where(frequencias: { id: frequencias_mes.select(:id) })
    
    total_registros = presencas_mes.count
    total_presentes = presencas_mes.where(status: 'presente').count
    
    @media_presenca = if total_registros.positive?
      "#{((total_presentes.to_f / total_registros) * 100).round}%"
    else
      nil
    end
    
    # 5. Média geral de notas (ainda não implementado)
    @media_geral_notas = nil
    
    # 6. Lista de Disciplinas do Professor (para o primeiro dropdown)
    frequencias_base = Frequencia.where(professor_id: current_professor.id)
    
    @disciplinas_professor = frequencias_base
      .includes(:disciplina)
      .select(:disciplina_id)
      .distinct
      .map { |freq| { id: freq.disciplina_id, nome: freq.disciplina&.nome || "Disciplina não encontrada" } }
      .sort_by { |d| d[:nome] }
    
    # 7. Turmas disponíveis baseado na disciplina selecionada (para o segundo dropdown)
    if @disciplina_selecionada_id.present?
      @turmas_disponiveis = frequencias_base
        .where(disciplina_id: @disciplina_selecionada_id)
        .includes(:turma)
        .select(:turma_id)
        .distinct
        .map { |freq| { id: freq.turma_id, nome: freq.turma&.nome || "Turma não encontrada" } }
        .sort_by { |t| t[:nome] }
    else
      @turmas_disponiveis = []
    end
    
    # 8. Lista combinada (para referência, se necessário)
    @disciplinas_e_turmas = current_professor.turmas.flat_map do |turma|
      current_professor.disciplinas.map do |disciplina|
        {
          disciplina_id: disciplina.id,
          disciplina: disciplina.nome,
          turma_id: turma.id,
          turma: turma.nome
        }
      end
    end
    
    # 9. Gráfico de desempenho (pendente)
    @grafico_desempenho_disciplinas = {
      labels: ["Matemática", "Português"],
      data: [8.5, 7.2]
    }
    
    # 10. 📅 CALENDÁRIO DE PRESENÇA DO MÊS (REAL e FILTRADO)
    @calendario_presenca = frequencias_mes
      .joins(:frequencia_alunos)
      .group("frequencias.data_aula")
      .pluck(
        "frequencias.data_aula",
        Arel.sql("SUM(CASE WHEN frequencia_alunos.status = 'presente' THEN 1 ELSE 0 END)"),
        Arel.sql("COUNT(frequencia_alunos.id)")
      )
      .map do |data_aula, presentes, total|
        {
          dia: data_aula.day,
          taxa_presenca: ((presentes.to_f / total) * 100).round
        }
      end
    
    # 11. Presença semanal
    @presenca_semanal = frequencias
    .joins(:frequencia_alunos)
    .group("EXTRACT(DOW FROM frequencias.data_aula)")
    .pluck(
      Arel.sql("EXTRACT(DOW FROM frequencias.data_aula)"),
      Arel.sql("SUM(CASE WHEN frequencia_alunos.status = 'presente' THEN 1 ELSE 0 END)"),
      Arel.sql("COUNT(frequencia_alunos.id)")
    )
    .map do |dow, presentes, total|

      percentual_presentes = total.positive? ? ((presentes.to_f / total) * 100).round : 0

        {
          dia: {
            0 => "Domingo",
            1 => "Segunda",
            2 => "Terça",
            3 => "Quarta",
            4 => "Quinta",
            5 => "Sexta",
            6 => "Sábado"
          }[dow.to_i],
        presentes: presentes,
        total: total,
        percentual_presentes: percentual_presentes,
        percentual_ausentes: 100 - percentual_presentes
      }
    end
    @ultimas_chamadas = frequencias
      .includes(:turma, :disciplina, :frequencia_alunos)
      .order(data_aula: :desc)
      .limit(5)
      .map do |frequencia|

        total = frequencia.frequencia_alunos.count
        presentes = frequencia.frequencia_alunos.where(status: 'presente').count

        {
          data: frequencia.data_aula,
          turma: frequencia.turma&.nome,
          disciplina: frequencia.disciplina&.nome,
          presentes: presentes,
          total: total,
          percentual: total.positive? ? ((presentes.to_f / total) * 100).round : 0
        }
      end
  end


  # 4. Mantenha o método de cálculo de crescimento (Mantido Intacto)
  def calculate_monthly_growth
    # Calculate growth for the last 12 months
    12.times.map do |i|
      month_start = i.months.ago.beginning_of_month
      month_end = i.months.ago.end_of_month
      
      {
        month: month_start.strftime('%b'),
        schools: Escola.where(created_at: month_start..month_end).count,
        students: Aluno.where(created_at: month_start..month_end).count,
        classes: Turma.where(created_at: month_start..month_end).count
      }
    end.reverse
  end
  
end
