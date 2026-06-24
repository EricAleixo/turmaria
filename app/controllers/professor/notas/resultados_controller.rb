class Professor::Notas::ResultadosController < Professor::BaseController
  before_action :set_turma_e_disciplina, only: [ :show, :index, :detalhes ]
  layout 'dashboard'
  before_action :authenticate_professor!

  def show
    @alunos = @turma.alunos.order(:nome)

    @medias_finais = AvaliacaoBimestral.where(
      turma_id: @turma.id,
      disciplina_id: @disciplina.id
    ).index_by { |media| [ media.aluno_id, media.bimestre ] }

    @avaliacoes_por_bimestre = @disciplina.avaliacoes_configuracoes
                                          .order(bimestre: :asc, id: :asc)
                                          .group_by(&:bimestre)

    # Busca conceitos direto de RegistroDeNota para turmas de conceito
    if @turma.usa_conceito?
      config_ids = @disciplina.avaliacoes_configuracoes
                              .where(turma: @turma)
                              .pluck(:id)

      @conceitos_por_aluno_bimestre = RegistroDeNota
        .where(avaliacao_configuracao_id: config_ids)
        .joins(:avaliacao_configuracao)
        .select("registros_de_notas.aluno_id, avaliacoes_configuracoes.bimestre, registros_de_notas.conceito")
        .each_with_object({}) do |r, hash|
          hash[[r.aluno_id, r.bimestre]] = r.conceito
        end
    end
  end

  def detalhes
    expires_now

    @media_bimestral = AvaliacaoBimestral.find(params[:media_bimestral])

    aluno    = @media_bimestral.aluno
    bimestre = @media_bimestral.bimestre

    @avaliacoes_configuracoes = AvaliacaoConfiguracao
                                  .do_bimestre(bimestre)
                                  .where(turma: @turma, disciplina: @disciplina)
                                  .order(created_at: :asc)

    config_ids = @avaliacoes_configuracoes.pluck(:id)

    registros = RegistroDeNota.where(aluno: aluno, avaliacao_configuracao_id: config_ids)

    @registros_de_nota = registros.index_by(&:avaliacao_configuracao_id)

    render partial: 'detalhes', layout: false

  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  def todos_alunos
    @disciplina = current_professor.disciplinas.find(params[:disciplina_id])

    turma_ids_distintos = current_professor.turmas
                                           .joins(:disciplinas)
                                           .where(disciplinas: { id: @disciplina.id })
                                           .distinct
                                           .pluck(:id)

    @turmas_da_disciplina = Turma.where(id: turma_ids_distintos).order(:nome)

    turma_ids = turma_ids_distintos

    @medias_finais_por_turma = AvaliacaoBimestral.where(
      turma_id: turma_ids,
      disciplina_id: @disciplina.id
    ).index_by { |media| [ media.turma_id, media.aluno_id, media.bimestre ] }

  rescue ActiveRecord::RecordNotFound
    redirect_to professor_turmas_path, alert: "Disciplina não encontrada ou você não está associado a ela."
  end

  def selecionar_disciplina
    @disciplinas = current_professor.disciplinas.distinct

    @disciplinas_com_turmas = {}

    @disciplinas.each do |disciplina|
      turmas = current_professor.turmas
                                .joins(:disciplinas)
                                .where(disciplinas: { id: disciplina.id })
                                .includes(:alunos, :ano_letivo)
                                .distinct
                                .order(:serie, :nome)

      turmas_data = turmas.map do |turma|
        {
          turma:        turma,
          total_alunos: turma.alunos.count,
          ano_letivo:   turma.ano_letivo&.ano
        }
      end

      @disciplinas_com_turmas[disciplina] = turmas_data if turmas_data.any?
    end
  end

  private

  def set_turma_e_disciplina
    @turma      = current_professor.turmas.find(params[:turma_id])
    @disciplina = Disciplina.find(params[:disciplina_id])

    unless current_professor.disciplinas.include?(@disciplina)
      redirect_to professor_turmas_path, alert: 'Você não está autorizado a acessar esta disciplina.'
      return
    end

  rescue ActiveRecord::RecordNotFound
    redirect_to professor_turmas_path, alert: 'Turma ou Disciplina não encontrada ou você não tem acesso.'
  end
end