class TurmaDisciplinasController < ApplicationController

  layout "dashboard"

  def index
    @turma = Turma.find(params[:turma_id])
    @disciplinas = @turma.disciplinas.includes(:area_disciplina)
    @disciplinas_associadas = @turma.disciplinas.includes(:area_disciplina)
    @disciplinas_disponiveis = Disciplina.where(escola_id: @turma.escola_id)
                                         .where.not(id: @disciplinas_associadas.ids)
                                         .includes(:area_disciplina)  
  end

  def processar_associacao
    @turma = Turma.find(params[:turma_id])
    
    # Adicionar disciplinas
    if params[:disciplinas_adicionar].present?
      params[:disciplinas_adicionar].each do |disciplina_id|
        @turma.disciplinas << Disciplina.find(disciplina_id) unless @turma.disciplinas.exists?(disciplina_id)
      end
    end
    
    # Remover disciplinas
    if params[:disciplinas_remover].present?
      params[:disciplinas_remover].each do |disciplina_id|
        @turma.disciplinas.delete(Disciplina.find(disciplina_id))
      end
    end
    
    redirect_to escola_turma_disciplinas_path(@turma.escola, @turma), notice: 'Disciplinas atualizadas com sucesso!'
  rescue => e
    redirect_to associar_escola_turma_disciplinas_path(@turma.escola, @turma), alert: "Erro ao processar: #{e.message}"
  end
end