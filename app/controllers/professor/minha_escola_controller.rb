class Professor::MinhaEscolaController < Professor::BaseController
  layout "dashboard"
  
  def index
    @escola = current_professor.escola
    @minhas_turmas_count = current_professor.turmas.count
    
    # Buscar alunos das turmas do professor
    @meus_alunos_count = current_professor.turmas.joins(:alunos).distinct.count('alunos.id')
    
    @minhas_disciplinas = current_professor
      .disciplinas
      .joins(:turmas)
      .select(
        'disciplinas.id as disciplina_id',
        'disciplinas.nome as disciplina_nome',
        'turmas.id as turma_id',
        'turmas.nome as turma_nome',
        'COUNT(alunos.id) as total_alunos'
      )
      .joins('LEFT JOIN alunos ON alunos.turma_id = turmas.id')
      .group('disciplinas.id, turmas.id')
      .map do |d|
        {
          disciplina_nome: d.disciplina_nome,
          turma_nome: d.turma_nome,
          total_alunos: d.total_alunos,
          turma_id: d.turma_id,
          disciplina_id: d.disciplina_id
        }
      end
  end
end