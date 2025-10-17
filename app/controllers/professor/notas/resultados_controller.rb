# app/controllers/professor/notas/resultados_controller.rb

class Professor::Notas::ResultadosController < Professor::BaseController 
  before_action :set_turma_e_disciplina, only: [:show, :index, :detalhes]
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
    # 🚨 FIX TURBO CACHE: Garante que o Rails sempre envie o corpo da resposta (Status 200)
    expires_now 

    # 1. Encontra a Média Bimestral final que foi clicada (AvaliacaoBimestral)
    @media_bimestral = AvaliacaoBimestral.find(params[:media_bimestral])
    
    # Variáveis de contexto
    aluno = @media_bimestral.aluno
    bimestre = @media_bimestral.bimestre
    
    # 2. Busca TODAS as configurações de avaliação (colunas de nota) para o bimestre
    @avaliacoes_configuracoes = AvaliacaoConfiguracao
                                  .do_bimestre(bimestre)
                                  .where(turma: @turma, disciplina: @disciplina)
                                  .order(created_at: :asc)
                                  
    # 3. Busca os IDs das configurações
    config_ids = @avaliacoes_configuracoes.pluck(:id)
    
    # 4. Busca os Registros de Nota filtrando pelo aluno e pelas configurações
    registros = RegistroDeNota.where(aluno: aluno, avaliacao_configuracao_id: config_ids)

    # 5. Constrói um Hash para acesso rápido na view
    @registros_de_nota = registros.index_by(&:avaliacao_configuracao_id)
    
    # Renderiza o partial da modal
    render partial: 'detalhes', layout: false
    
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