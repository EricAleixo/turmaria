class DashboardController < ApplicationController
  # 1. Lógica de autenticação flexível (Mantida)
  before_action :authenticate_any_user!
  
  def index
    if current_super_admin
      load_super_admin_dashboard_data
    elsif current_professor
      load_professor_dashboard_data
    elsif current_aluno
      load_aluno_dashboard_data # <--- Esta função será corrigida
    end
  end

  def minhas_notas
    load_aluno_data_for_pages
    return if performed? # Sai se houve redirecionamento na autenticação/carregamento
    
    # Carrega todas as notas com inclusão de disciplina (via avaliacao_configuracao)
    @registros_notas = RegistroDeNota.includes(avaliacao_configuracao: [:disciplina])
                                     .where(aluno_id: @aluno.id)
                                     .order(created_at: :desc)
    
    @titulo_pagina = "Minhas Notas | #{@aluno.nome}"
    render 'aluno/minhas_notas' # Renderiza a view na pasta aluno/
  end
  
  def minha_frequencia
    load_aluno_data_for_pages
    return if performed? # Sai se houve redirecionamento na autenticação/carregamento
    
    # Carrega todos os registros de frequência
    @registros_frequencia = FrequenciaAluno.includes(frequencia: [:disciplina, :turma])
                                          .where(aluno_id: @aluno.id)
                                          .order(created_at: :desc)
    
    @titulo_pagina = "Minha Frequência | #{@aluno.nome}"
    render 'aluno/minha_frequencia' # Renderiza a view na pasta aluno/
  end

  private

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

  

  # ===================================================================
  # 🛑 MÉTODO DO ALUNO CORRIGIDO (Substitui o mockado) 🛑
  # ===================================================================
  def load_aluno_dashboard_data
  # 1. Garante que @aluno é o objeto e carrega associações
  # CORRIGIDO: 'turmas' -> 'turma' (Nome sugerido pelo erro do Rails)
  @aluno = Aluno.includes(turma: [:ano_letivo]) 
                .find_by(id: current_aluno.id)
  
  # Se @aluno for nil, define padrões seguros e sai
  if @aluno.nil?
    @frequencia_percentual = '0.0%'
    @total_faltas = 0
    @media_geral_notas = 0.0 # <-- Garante que é Float
    @ultimas_faltas = []
    @turma_atual = nil
    @titulo_pagina = "Dashboard | Aluno Não Encontrado"
    return
  end

  # 2. Dados de Frequência (Real)
  total_registros = FrequenciaAluno.where(aluno_id: @aluno.id).count
  faltas_registradas = FrequenciaAluno.where(aluno_id: @aluno.id).where.not(status: 'presente').count
  
  @frequencia_percentual = if total_registros.zero?
    '0.0%'
  else
    presencas = total_registros - faltas_registradas
    media = (presencas.to_f / total_registros) * 100
    "%.1f%%" % media
  end
  
  @total_faltas = faltas_registradas
  
  # 3. Dados de Notas (Real) - CORRIGE O TypeError
  notas_registradas = RegistroDeNota.where(aluno_id: @aluno.id)
  
  if notas_registradas.present?
    media_simples = notas_registradas.average(:valor)
    # Define @media_geral_notas (com 's') e garante que é 0.0 se for nil
    @media_geral_notas = (media_simples || 0.0).round(1) 
  else
    @media_geral_notas = 0.0 # Garante que é 0.0 (Float)
  end
  
  # 4. Tabela: Últimas Faltas (Real)
  @ultimas_faltas = FrequenciaAluno.where(aluno_id: @aluno.id)
                                .where.not(status: 'presente')
                                .includes(frequencia: [:turma, :disciplina])
                                .order(created_at: :desc)
                                .limit(10)
                                
  # 5. Turma Atual (Real) - CORRIGE O NoMethodError
  # AJUSTADO: Usando a associação singular '@aluno.turma' para buscar a turma principal.
  @turma_atual = @aluno.turma 
  
  @titulo_pagina = "Dashboard | #{@aluno.nome}"
end
  # ===================================================================


  # Método para garantir que o acesso é liberado (Mantido)
  def authenticate_any_user!
    unless super_admin_signed_in? || professor_signed_in? || aluno_signed_in?
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

  # 3. Método: Carrega dados para Professor (Mantido Intacto)
  def load_professor_dashboard_data
    # 1. Dados do Professor
    @professor_nome = current_professor.nome rescue "Professor Teste Mock"

    # 2. Cartões Principais
    @turmas_ativas = 5
    @disciplinas_contagem = 3
    @alunos_unicos = 185
    @media_presenca = "94.2%"
    
    # 3. Cartões Secundários
    @media_geral_notas = "7.8"
    @pior_turma_media = "6.5 (9º ano A - Matemática)"
    @notas_lancadas_mes = 320

    # 4. Lista de Disciplinas/Turmas
    @disciplinas_e_turmas = [
      { disciplina: "Matemática", turma: "9º ano A" },
      { disciplina: "Física", turma: "2º ano A" },
      { disciplina: "Robótica", turma: "7º ano Única" },
    ]

    # 5. Dados dos Gráficos (Estrutura para Chart.js)
    @grafico_desempenho_disciplinas = {
      labels: ["Matemática", "Física", "Robótica"],
      data: [7.8, 8.5, 9.1]
    }
    @grafico_evolucao_notas = {
      labels: ["Fev", "Mar", "Abr", "Mai", "Jun", "Jul"],
      data: [7.2, 7.5, 7.8, 7.7, 8.0, 7.9]
    }
    @grafico_presenca_turmas = {
      labels: ["9º A", "9º B", "2º A", "2º B"],
      data: [96.0, 91.5, 94.8, 92.0]
    }
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
