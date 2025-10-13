# app/controllers/professor/notas/resultados_controller.rb
# app/controllers/professor/notas/resultados_controller.rb

class Professor::Notas::ResultadosController < Professor::BaseController 
  before_action :set_turma_e_disciplina
  layout 'dashboard'
  before_action :authenticate_professor!

  # CORREÇÃO APLICADA: Renomear de 'def index' para 'def show'
  def show
    # 1. Alunos da turma, ordenados para exibição
    @alunos = @turma.alunos.order(:nome)
    
    # 2. Médias Finais (AvaliacoesBimestrais) da disciplina/turma.
    @medias_finais = AvaliacaoBimestral.where(
      turma: @turma, 
      disciplina: @disciplina
    ).index_by { |media| [media.aluno_id, media.bimestre] }
  end
  
  private

  # ... (O restante do código private está correto) ...
  def set_turma_e_disciplina
    @turma = current_professor.turmas.find(params[:turma_id])
    @disciplina = Disciplina.find(params[:disciplina_id])
    
    unless current_professor.disciplinas.include?(@disciplina)
      redirect_to minhas_turmas_path, alert: 'Você não está autorizado a acessar esta disciplina.'
      return
    end

  rescue ActiveRecord::RecordNotFound
    redirect_to minhas_turmas_path, alert: 'Turma ou Disciplina não encontrada ou você não tem acesso.'
  end
end