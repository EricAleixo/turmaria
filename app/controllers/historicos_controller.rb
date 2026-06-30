class HistoricosController < ApplicationController
  layout 'dashboard'
  before_action :authenticate_any_user!
  before_action :set_aluno
  before_action :set_aluno, only: [:gerar, :index]

  helper HistoricosHelper
  include HistoricosHelper

  def index
    @historicos = HistoricoEscolar
      .includes(:escola, :ano_letivo, :historico_disciplinas)
      .where(aluno_id: @aluno.id)
      .order('ano_letivos.ano ASC')
      .joins(:ano_letivo)
  end

  # POST /historicos/gerar
  def gerar
    @ano_letivo = AnoLetivo.find(params[:ano_letivo_id])
    @turma      = buscar_turma_do_aluno_no_ano(@aluno, @ano_letivo)

    unless @turma
      redirect_back fallback_location: root_path,
                    alert: "Turma não encontrada para o ano #{@ano_letivo.ano}."
      return
    end

    avaliacoes = AvaliacaoBimestral
      .includes(:disciplina)
      .where(aluno_id: @aluno.id, turma_id: @turma.id)
      .order('disciplinas.nome', :bimestre)

    boletim_disciplinas       = avaliacoes.group_by(&:disciplina)
    frequencia_por_disciplina = calcular_frequencia_por_disciplina(@turma, @aluno)

    @historico = HistoricoEscolar.gerar!(
      aluno:                     @aluno,
      turma:                     @turma,
      ano_letivo:                @ano_letivo,
      boletim_disciplinas:       boletim_disciplinas,
      frequencia_por_disciplina: frequencia_por_disciplina
    )

    redirect_to historico_path(aluno_id: @aluno.id), notice: "Histórico gerado com sucesso."
  rescue StandardError => e
    redirect_back fallback_location: root_path,
                  alert: "Erro ao gerar histórico: #{e.message}"
  end

  private

  def set_aluno
    if params[:aluno_id].present?
      authorize_staff!
      @aluno = Aluno.find(params[:aluno_id])
    elsif aluno_signed_in?
      @aluno = current_aluno
    elsif admin_signed_in? || super_admin_signed_in? || professor_signed_in?
      # Staff acessando show — o aluno vem do próprio histórico
      # Só resolve no set_historico, então deixa @aluno nil por ora
      @aluno = nil
    else
      redirect_to root_path, alert: "Acesso negado."
    end
  end

  def set_historico
    @historico = HistoricoEscolar
      .includes(:escola, :ano_letivo, :historico_disciplinas)
      .find(params[:id])

    # Se @aluno ainda não foi definido (staff acessando direto), pega do histórico
    @aluno ||= @historico.aluno

    # Aluno só pode ver o próprio histórico
    if aluno_signed_in? && @historico.aluno_id != @aluno.id
      redirect_to root_path, alert: "Acesso negado."
    end
  end

  def authorize_staff!
    unless admin_signed_in? || super_admin_signed_in? || professor_signed_in?
      redirect_to root_path, alert: "Acesso negado."
    end
  end

  def authenticate_any_user!
    unless aluno_signed_in? || admin_signed_in? || super_admin_signed_in? || professor_signed_in?
      redirect_to new_user_session_path, alert: "Faça login para continuar."
    end
  end

  def buscar_turma_do_aluno_no_ano(aluno, ano_letivo)
    turma = Turma.joins(:avaliacoes_bimestrais)
                 .where(ano_letivo_id: ano_letivo.id,
                        avaliacoes_bimestrais: { aluno_id: aluno.id })
                 .first

    turma ||= Turma.joins(avaliacoes_configuracoes: :registros_de_notas)
                   .where(ano_letivo_id: ano_letivo.id,
                          registros_de_notas: { aluno_id: aluno.id })
                   .first

    turma ||= aluno.turma if aluno.turma&.ano_letivo_id == ano_letivo.id
    turma
  end

  def calcular_frequencia_por_disciplina(turma, aluno)
    aulas_dadas = Frequencia
      .where(turma_id: turma.id)
      .group(:disciplina_id)
      .count

    faltas = FrequenciaAluno
      .joins(:frequencia)
      .where(aluno_id: aluno.id, frequencias: { turma_id: turma.id }, status: 'falta')
      .group('frequencias.disciplina_id')
      .count

    aulas_dadas.each_with_object({}) do |(disciplina_id, total_aulas), hash|
      hash[disciplina_id] = {
        total_aulas:  total_aulas,
        total_faltas: faltas[disciplina_id] || 0
      }
    end
  end
end