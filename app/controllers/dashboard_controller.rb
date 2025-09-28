class DashboardController < ApplicationController
  before_action :authenticate_super_admin!

  def index
    # System-wide statistics
    @total_schools = Escola.count
    @total_classes = Turma.count
    @total_teachers = Professor.count rescue 0  # In case Professor model doesn't exist yet
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
    
    # Recent students
    @recent_students = Aluno.includes(:escola).order(created_at: :desc).limit(5)
    
    # System growth data for charts
    @monthly_growth = calculate_monthly_growth
  end

  private

  def authenticate_user!
    unless super_admin_signed_in? || admin_signed_in?
      redirect_to new_user_session_path, alert: 'Acesso negado. Faça login como administrador.'
    end
  end

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
