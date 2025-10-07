# app/controllers/professor/disciplinas_controller.rb
class Professor::DisciplinasController < ApplicationController
  layout 'dashboard'
  before_action :authenticate_professor!
  before_action :set_turma
  
  # GET /professor/turmas/:turma_id/disciplinas
  def index
    # 1. Busca todas as disciplinas associadas à Turma
    disciplinas_da_turma = @turma.disciplinas.includes(:professor)
    
    # 2. Filtra para exibir apenas as disciplinas que são lecionadas pelo Professor logado (current_user)
    # ATENÇÃO: Assumimos que o modelo 'Disciplina' tem uma associação ou atributo 'professor'
    # que aponta para o professor responsável. Se o seu modelo for diferente (ex: usando TurmaDisciplina),
    # você precisará ajustar o filtro aqui.
    @disciplinas = disciplinas_da_turma.select do |disciplina|
      disciplina.professor_id == current_user.id
    end
    
    # Se o modelo Disciplina já tiver uma associação direta com o professor, 
    # a linha acima pode ser mais performática no banco de dados, se reescrita assim:
    # @disciplinas = @turma.disciplinas.where(professor: current_user)
  end

  private

  # Reutiliza a lógica de set_turma do TurmasController para garantir autorização
  def set_turma
    # current_user é um Professor, então current_user.turmas funciona.
    @turma = current_user.turmas.find(params[:turma_id])
    # Se a turma não for encontrada ou não for do professor, o Rails levanta um 404
  end
end