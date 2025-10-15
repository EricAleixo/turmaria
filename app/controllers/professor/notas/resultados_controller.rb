# app/controllers/professor/notas/resultados_controller.rb

class Professor::Notas::ResultadosController < Professor::BaseController 
  before_action :set_turma_e_disciplina
  layout 'dashboard'
  before_action :authenticate_professor!


  def show
    # 1. Alunos da turma, ordenados para exibição
    @alunos = @turma.alunos.order(:nome)
    
    # 2. Médias Finais (AvaliacoesBimestrais) da disciplina/turma.
    @medias_finais = AvaliacaoBimestral.where(
      turma_id: @turma.id, 
      disciplina_id: @disciplina.id
    ).index_by { |media| [media.aluno_id, media.bimestre] }
    
    # CORREÇÃO: Usando ordenação estável (bimestre e id) em vez de uma coluna 'ordem' inexistente.
    @avaliacoes_por_bimestre = @disciplina.avaliacoes_configuracoes
                                           .order(bimestre: :asc, id: :asc)
                                           .group_by(&:bimestre)
  end


  def detalhes
    # Usando o parâmetro de ID correto, assumindo que é o ID do AvaliacaoBimestral
    @media_bimestral = AvaliacaoBimestral.find(params[:media_bimestral_id] || params[:id])
    
    # 1. Carrega as configurações de avaliação (nomes), já filtradas por bimestre.
    @avaliacoes_configuracoes = @disciplina.avaliacoes_configuracoes
                                           .where(bimestre: @media_bimestral.bimestre)
                                           # CORREÇÃO: Ordenação estável por ID, já que está filtrado por bimestre.
                                           .order(id: :asc) 
    
    # Coleta os IDs das configurações que pertencem ao bimestre.
    config_ids = @avaliacoes_configuracoes.pluck(:id)

    # 2. Busca os registros de nota filtrando pelos IDs das configurações.
    @registros_de_nota = RegistroDeNota.where(
      aluno_id: @media_bimestral.aluno_id,
      avaliacao_configuracao_id: config_ids # Filtra pelos IDs de configuração
    ).index_by(&:avaliacao_configuracao_id) 

    render layout: false
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end
  
  private

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