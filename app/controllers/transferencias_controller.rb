# app/controllers/transferencias_controller.rb
class TransferenciasController < ApplicationController
  layout 'dashboard'
  before_action :authenticate_admin!

  def create
    @aluno      = Aluno.find(params[:aluno_id])
    @escola_destino = Escola.find(params[:escola_destino_id])
    @ano_letivo = @aluno.turma&.ano_letivo

    unless @ano_letivo
      redirect_back fallback_location: root_path,
                    alert: "Aluno não está em nenhuma turma ativa."
      return
    end

    turma = @aluno.turma

    avaliacoes = AvaliacaoBimestral
      .includes(:disciplina)
      .where(aluno_id: @aluno.id, turma_id: turma.id)
      .order('disciplinas.nome', :bimestre)

    boletim_disciplinas       = avaliacoes.group_by(&:disciplina)
    frequencia_por_disciplina = calcular_frequencia_por_disciplina(turma, @aluno)

    Transferencia.executar!(
      aluno:                     @aluno,
      escola_destino:            @escola_destino,
      ano_letivo:                @ano_letivo,
      turma:                     turma,
      boletim_disciplinas:       boletim_disciplinas,
      frequencia_por_disciplina: frequencia_por_disciplina,
      motivo:                    params[:motivo]
    )

    redirect_to escola_aluno_path(@escola_destino, @aluno),
                notice: "Aluno transferido com sucesso. Histórico gerado automaticamente."
  rescue StandardError => e
    redirect_back fallback_location: root_path,
                  alert: "Erro ao transferir: #{e.message}"
  end

  private

  def authenticate_admin!
    unless admin_signed_in? || super_admin_signed_in?
      redirect_to root_path, alert: "Acesso negado."
    end
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