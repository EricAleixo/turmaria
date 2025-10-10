class Professor::Notas::ResultadosController < ApplicationController
  # Se você tem um Professor::BaseController, use-o
  # Se não, mantenha ApplicationController, mas inclua a autenticação
  before_action :authenticate_professor! # Recomendo manter isso!
  before_action :set_turma_e_disciplina

  def index
    # 1. Alunos da turma
    @alunos = @turma.alunos.order(:nome)
    
    # 2. Médias Finais (AvaliacoesBimestrais) da disciplina/turma
    @medias_finais = AvaliacaoBimestral.where(
      turma: @turma, 
      disciplina: @disciplina
    ).index_by { |a| [a.aluno_id, a.bimestre] }
  end
  
  private

  def set_turma_e_disciplina
    # 1. Busca a turma que pertence ao professor logado
    # Isso evita que um professor acesse turmas que ele não leciona
    @turma = current_professor.turmas.find(params[:turma_id])
    
    # 2. Verifica se a disciplina está associada a essa turma e ao professor
    # Isso é feito indiretamente verificando a relação ProfessorDisciplina ou ProfessorTurmaDisciplina
    
    # Vamos buscar a disciplina, e a rota já garante o aninhamento,
    # mas o Turma.find(params[:turma_id]) deve ser substituído por:
    
    @turma = current_professor.turmas.find(params[:turma_id])
    
    # Para garantir que ele leciona essa disciplina nessa turma, 
    # você precisaria de um relacionamento mais forte, mas, por ora, 
    # vamos apenas garantir que a disciplina existe e que o professor leciona a turma.
    
    @disciplina = Disciplina.find(params[:disciplina_id])

    # Melhoria de segurança: Verifique se o professor leciona a disciplina (ProfessorDisciplina)
    unless current_professor.disciplinas.include?(@disciplina)
      redirect_to minhas_turmas_path, alert: 'Você não está autorizado a acessar esta disciplina.'
      return
    end

  rescue ActiveRecord::RecordNotFound
    redirect_to minhas_turmas_path, alert: 'Turma ou Disciplina não encontrada ou você não tem acesso.'
  end
end