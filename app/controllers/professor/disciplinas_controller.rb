# app/controllers/professor/disciplinas_controller.rb
# app/controllers/professor/disciplinas_controller.rb
class Professor::DisciplinasController < Professor::BaseController
  # Assumindo que Professor::BaseController herda de ApplicationController e inclui autenticação/layout
  layout 'dashboard'
  before_action :authenticate_professor!
  
  # GET /professor/turmas/:turma_id/disciplinas
  def index
    if params[:turma_id].present?
      # 1. Tenta definir @turma. Se falhar, redireciona.
      set_turma 
      
      # 2. Define @disciplinas como a INTERSEÇÃO (Turma + Professor)
      disciplina_ids_do_professor = current_professor.disciplinas.pluck(:id)
      @disciplinas = @turma.disciplinas
                           .where(id: disciplina_ids_do_professor)
                           .order(:nome)
      
      # Adicionei um indicador para a view saber que é um contexto de Turma
      @contexto_turma = true 
    else
      # Contexto Geral: /professor/disciplinas (Sidebar)
      @turma = nil # Garantimos que @turma é nil (opcional, mas bom para clareza)
      @disciplinas = current_professor.disciplinas.order(:nome)
      @contexto_turma = false
    end
  end

  private
  
  def set_turma
    # Ajuste de Segurança: Garante que o professor só pode ver a Turma que ele leciona.
    # Se o professor não estiver associado a Turma via 'professor_turmas', o find falhará.
    @turma = current_professor.turmas.find(params[:turma_id])
    
  rescue ActiveRecord::RecordNotFound
    # Melhor usar uma rota genérica, pois 'minhas_turmas_path' pode não estar definida.
    redirect_to professor_turmas_path, alert: 'Turma não encontrada ou você não tem permissão.'
  end
end