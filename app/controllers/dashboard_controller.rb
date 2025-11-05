# app/controllers/dashboard_controller.rb

class DashboardController < ApplicationController
  # 1. Nova lógica de autenticação flexível para SuperAdmin e Professor
  before_action :authenticate_any_user!
  
  def index
    if current_super_admin
      load_super_admin_dashboard_data # Carrega seus dados reais
    elsif current_professor
      load_professor_dashboard_data   # Carrega dados mockados
    elsif current_aluno
      load_aluno_dashboard_data
    end
    
    # A view index.html.erb usará 'current_super_admin' ou 'current_professor'
    # para decidir qual partial renderizar (e já terá os dados carregados)
  end

  private


  def load_aluno_dashboard_data
    # Garante que temos o objeto do aluno logado
    aluno = current_aluno
    @aluno = current_aluno
    
    # Exemplo de dados da dashboard do aluno
    @aluno_nome = aluno.nome rescue "Aluno Teste"
    @escola_nome = aluno.escola.nome rescue "Não Informada"

    # Dados principais para exibição
    # *Os dados abaixo são mockados ou simplificados. Você deve ajustá-los
    # para carregar informações reais do seu modelo `Aluno` e suas associações (Notas, Turmas, Presença, etc).*
    
    # Turma atual do aluno (se houver)
    @turma_atual = aluno.turma.nome rescue "Turma não atribuída"
    
    # Últimas 5 notas (exemplo mockado)
    @ultimas_notas = [
      { disciplina: "Matemática", nota: 8.5 },
      { disciplina: "Português", nota: 7.0 },
      { disciplina: "História", nota: 9.2 },
      { disciplina: "Ciências", nota: 6.8 },
      { disciplina: "Inglês", nota: 8.0 }
    ]
    
    # Média geral (exemplo mockado)
    @media_geral = 7.9 
    
    # Total de faltas no mês (exemplo mockado)
    @total_faltas = 3
  end


  # Método para garantir que o acesso é liberado para SuperAdmin ou Professor
  def authenticate_any_user!
    unless super_admin_signed_in? || professor_signed_in? || aluno_signed_in?
      # Pode ajustar o redirecionamento conforme sua rota de login/Devise
      redirect_to new_user_session_path, alert: 'Acesso negado. Faça login para acessar o painel.'
    end
  end
  
  # 2. Método: Carrega dados para Super Admin (Seu código original)
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

  # 3. Método: Carrega dados para Professor (MOCK)
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

  # 4. Mantenha o método de cálculo de crescimento (Seu código original)
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
  
  # Removi seu 'authenticate_user!' original, pois ele não é mais necessário
  # já que 'authenticate_any_user!' e Devise cuidam disso agora.
end
