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

  private

  def calcular_media_por_disciplina(aluno_id)
    
    tabela_notas = RegistroDeNota.table_name
    
    resumo_agregado = RegistroDeNota
    .where(aluno_id: aluno_id)
    .joins(avaliacao_configuracao: :disciplina)
    .group('disciplinas.nome', 'disciplinas.cor_nome', 'disciplinas.id')
    .select(
      'disciplinas.nome AS nome',
      'disciplinas.cor_nome AS cor_nome',
      'disciplinas.cor_nome AS cor_hex', # alias opcional do mesmo campo
      "COUNT(#{tabela_notas}.id) AS provas_lancadas",
      "AVG(#{tabela_notas}.valor) AS media",
      "SUM(#{tabela_notas}.valor) AS total_notas"
    )
    .order('disciplinas.nome ASC')

      
    # 2. Formatar para o Array de Hashes que a View espera
    resumo_agregado.map do |item|
      media_calculada = item.media.to_f
      
      {
        nome: item.nome,
        # CORREÇÃO CRÍTICA: Acessar o campo pelo novo alias 'cor_hex'
        # Usamos cor_nome ou cor_hex (o valor RGB/HEX) como fallback para o default.
        cor: item.cor_nome || item.cor_hex || '#10B981', 
        media: media_calculada.round(1),
        provas_lancadas: item.provas_lancadas.to_i,
        total_notas: item.total_notas.to_f.round(1)
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
  # 1. Garante que @aluno é o objeto e carrega associações
  @aluno = Aluno.includes(turma: [:ano_letivo]) 
                  .find_by(id: current_aluno.id)
  
  if @aluno.nil?
    @frequencia_percentual = '0.0%'
    @total_faltas = 0
    @media_geral_notas = 0.0
    @ultimas_faltas = []
    @turma_atual = nil
    @titulo_pagina = "Dashboard | Aluno Não Encontrado"
    return
  end

  # Define Turma Atual
  @turma_atual = @aluno.turma 

  # 2. Dados de Frequência (Real) - CÁLCULO ATUALIZADO PARA O NOVO CARD
  total_registros = FrequenciaAluno.where(aluno_id: @aluno.id).count # Total de Aulas (Registros)
  faltas_registradas = FrequenciaAluno.where(aluno_id: @aluno.id).where.not(status: 'presente').count
  presencas_registradas = total_registros - faltas_registradas
  
  # Variáveis para o Card 3 (NOVA ESTRUTURA)
  @total_aulas = total_registros
  @total_presencas = presencas_registradas
  @total_faltas = faltas_registradas # Já existente
  
  # Variáveis para os cálculos de % nos subcards
  @perc_presencas = total_registros.zero? ? 0.0 : ((@total_presencas.to_f / total_registros) * 100).round(1)
  @perc_faltas = total_registros.zero? ? 0.0 : ((@total_faltas.to_f / total_registros) * 100).round(1)
  
  # A variável @frequencia_percentual (para o Doughnut Chart) continua sendo a de Presença
  @frequencia_percentual = @perc_presencas
  
  # 3. Dados de Notas (Real) - Cálculo mantido
  notas_registradas = RegistroDeNota.where(aluno_id: @aluno.id)
  
  if notas_registradas.present?
    media_simples = notas_registradas.average(:valor)
    @media_geral_notas = (media_simples || 0.0).round(1) 
  else
    @media_geral_notas = 0.0
  end
  
  # 4. Tabela: Últimas Faltas (Real) - Mantido
  @ultimas_faltas = FrequenciaAluno.where(aluno_id: @aluno.id)
                              .where.not(status: 'presente')
                              .includes(frequencia: [:turma, :disciplina])
                              .order(created_at: :desc)
                              .limit(10)
                                
  # =========================================================
  # 🆕 NOVOS DADOS PARA GRÁFICOS E LISTAS 🆕
  # =========================================================

  # A) Média por Disciplina (USADO PARA LISTA ROLÁVEL)
  # Agrupa os registros de nota pela disciplina e calcula a média.
  @medias_por_disciplina = notas_registradas
    .joins(avaliacao_configuracao: :disciplina) # Associa via config -> disciplina
    .group('disciplinas.nome')
    .average(:valor)
    .map { |nome, media| [nome, media.round(1)] } # Formato: [["Matemática", 8.5], ["Português", 7.2]]

  # B) Frequência Mensal (USADO PARA GRÁFICO DE BARRAS)
  registros_frequencia_mensal = FrequenciaAluno.where(aluno_id: @aluno.id)
    .joins(frequencia: :disciplina)
    .group_by { |fa| fa.frequencia.data_aula.strftime('%m-%Y') } 
    .sort_by { |month_year, _| Date.strptime(month_year, '%m-%Y') } 
    
  @frequencia_mensal = registros_frequencia_mensal.map do |month_year, registros|
    {
      mes_ano: month_year,
      presencas: registros.count { |r| r.status == 'presente' },
      faltas: registros.count { |r| r.status == 'falta' || r.status == 'justificada' }
    }
  end

  # C) EVOLUÇÃO DA MÉDIA GERAL (USADO PARA GRÁFICO DE LINHA)
  # Calcula a média geral por mês.
  @evolucao_notas = notas_registradas
    .joins(avaliacao_configuracao: :disciplina)
    .group_by { |nota| nota.created_at.strftime('%m-%Y') }
    .sort_by { |month_year, _| Date.strptime(month_year, '%m-%Y') }
    .map do |month_year, notas|
        total_valor = notas.sum(&:valor)
        media_mensal = total_valor / notas.count.to_f
        [month_year, media_mensal.round(1)]
    end
    # Formato: [["03-2025", 7.5], ["04-2025", 8.1]]


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
  # Pega apenas as escolas do admin logado
  @escolas_do_admin = current_admin.escolas.includes(:turmas, :alunos)
  
  # Estatísticas principais
  @minhas_escolas = @escolas_do_admin.count
  @total_turmas = @escolas_do_admin.sum(&:turmas_count)
  @total_alunos = @escolas_do_admin.sum(&:alunos_count)
  
  escola_ids = @escolas_do_admin.pluck(:id)
  @total_professores = Professor.where(escola_id: escola_ids).count
  
  # Crescimento no mês atual
  inicio_mes = Date.today.beginning_of_month
  @escolas_mes_atual = @escolas_do_admin.where('created_at >= ?', inicio_mes).count
  @alunos_mes_atual = Aluno.where(escola_id: escola_ids)
                           .where('created_at >= ?', inicio_mes).count
  
  # Médias
  @media_alunos_escola = @minhas_escolas > 0 ? (@total_alunos.to_f / @minhas_escolas).round(1) : 0
  @media_turmas_escola = @minhas_escolas > 0 ? (@total_turmas.to_f / @minhas_escolas).round(1) : 0
  @media_alunos_turma = @total_turmas > 0 ? (@total_alunos.to_f / @total_turmas).round(1) : 0
  
  # Distribuição por tipo
  @escolas_publicas = @escolas_do_admin.publicas.count
  @escolas_privadas = @escolas_do_admin.privadas.count
  @percentual_publicas = @minhas_escolas > 0 ? ((@escolas_publicas.to_f / @minhas_escolas) * 100).round(1) : 0
  @percentual_privadas = @minhas_escolas > 0 ? ((@escolas_privadas.to_f / @minhas_escolas) * 100).round(1) : 0
  
  # Maiores escolas (top 5)
  @maiores_escolas = @escolas_do_admin.order(alunos_count: :desc).limit(5)
  
  # Escolas recentes (últimas 5)
  @escolas_recentes = @escolas_do_admin.order(created_at: :desc).limit(5)
  
  # Todas as escolas para a grid
  @todas_escolas = @escolas_do_admin.order(:nome)
  
  # Dados para gráfico de crescimento (últimos 6 meses)
  # Array com nomes dos meses em português
  meses_pt = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez']
  
  @crescimento_labels = []
  @crescimento_alunos = []
  @crescimento_turmas = []
  
  6.downto(1) do |i|
    data = i.months.ago.end_of_month
    # Usa o array de meses em português
    @crescimento_labels << meses_pt[data.month - 1]
    
    alunos_ate_data = Aluno.where(escola_id: escola_ids)
                           .where('created_at <= ?', data).count
    turmas_ate_data = Turma.where(escola_id: escola_ids)
                           .where('created_at <= ?', data).count
    
    @crescimento_alunos << alunos_ate_data
    @crescimento_turmas << turmas_ate_data
  end
  
  # Dados para gráfico de barras (alunos por escola)
  @escolas_nomes = @escolas_do_admin.order(alunos_count: :desc).pluck(:nome)
  @escolas_alunos = @escolas_do_admin.order(alunos_count: :desc).pluck(:alunos_count)
  end

  # 3. Método: Carrega dados para Professor (Mantido Intacto)
  def load_professor_dashboard_data
    # 1. Dados do Professor (dados reais)
    @professor_nome = current_professor.nome
    
    # 2. Turmas e Disciplinas do Professor (dados reais)
    frequencias = Frequencia.where(professor_id: current_professor.id)
    
    @turmas_ativas = frequencias.distinct.pluck(:turma_id).count
    @disciplinas_contagem = frequencias.distinct.pluck(:disciplina_id).count
    
    # 3. Alunos únicos nas turmas do professor (dados reais)
    turma_ids = frequencias.distinct.pluck(:turma_id)
    @alunos_unicos = Aluno.where(turma_id: turma_ids).count
    
    # 4. Taxa de presença (NIL - necessário modelo de registros de presença individual)
    # TODO: Criar cálculo real quando houver modelo de presença por aluno
    @media_presenca = nil
    
    # 5. Média geral de notas (NIL - necessário modelo de Nota/Avaliacao)
    # TODO: Buscar média real das notas quando modelo estiver disponível
    @media_geral_notas = nil
    
    # 6. Lista de Disciplinas/Turmas (dados reais)
    @disciplinas_e_turmas = frequencias
        .includes(:turma, :disciplina)
        .select(:turma_id, :disciplina_id)
        .distinct
        .map do |freq|
          {
            disciplina_id: freq.disciplina_id,
            disciplina: freq.disciplina&.nome || "Disciplina não encontrada",
            turma_id: freq.turma_id,
            turma: freq.turma&.nome || "Turma não encontrada"
          }
      end
    
    # 7. Gráfico de Desempenho por Disciplina (NIL - necessário modelo de Nota)
    # TODO: Calcular médias reais por disciplina
    @grafico_desempenho_disciplinas = nil
    
    # 8. Calendário de Presença do Mês (NIL)
    # TODO: Implementar com dados reais de frequência por dia
    @calendario_presenca = nil
    
    # 9. Presença Semanal (NIL)
    # TODO: Calcular presença dos últimos 5 dias úteis
    @presenca_semanal = nil
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
