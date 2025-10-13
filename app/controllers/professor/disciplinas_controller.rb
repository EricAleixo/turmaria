# app/controllers/professor/disciplinas_controller.rb
# app/controllers/professor/disciplinas_controller.rb
class Professor::DisciplinasController < Professor::BaseController
  # Assumindo que Professor::BaseController herda de ApplicationController e inclui autenticação/layout
  before_action :set_turma
  layout 'dashboard'
  before_action :authenticate_professor!
  
  # GET /professor/turmas/:turma_id/disciplinas
  def index
    # CRÍTICO: Filtra as disciplinas da TURMA que o PROFESSOR logado está habilitado a lecionar.
    
    # 1. Encontra as IDs das disciplinas associadas ao professor LOGADO (professor_disciplinas)
    disciplina_ids_do_professor = current_professor.disciplinas.pluck(:id)

    # 2. Encontra a INTERSEÇÃO: Disciplinas da turma (@turma.disciplinas) que estão na lista do professor.
    @disciplinas = @turma.disciplinas
                         .where(id: disciplina_ids_do_professor)
                         .order(:nome)
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