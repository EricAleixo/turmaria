require 'prawn'
require_relative '../../pdfs/declaracao_pdf'

class Aluno::DeclaracoesController < ApplicationController
  layout 'dashboard'

  include Aluno::TurmaLookup
  before_action :authenticate_aluno!

  def index
    @anos_letivos = current_aluno.anos_letivos_com_notas
    @declaracoes = current_aluno.declaracoes.includes(:ano_letivo).order(emitido_em: :desc)
    @declaracoes_por_ano = @declaracoes.index_by(&:ano_letivo_id)
  end

  # GET /aluno/declaracoes/show_por_ano/:id
  # Emite (ou reaproveita) e exibe a declaração para o ano letivo informado
  def show_por_ano
    @ano_letivo = AnoLetivo.find(params[:id])
    @aluno = current_aluno
    @turma = buscar_turma_do_aluno_no_ano(@aluno, @ano_letivo) || @aluno.turma

    if @turma
      @declaracao = Declaracao.emitir!(aluno: @aluno, turma: @turma, ano_letivo: @ano_letivo)

      respond_to do |format|
        format.html
        format.pdf do
          pdf = DeclaracaoPdf.new(@aluno, @turma, @ano_letivo, @declaracao, view_context)
          send_data pdf.render,
                    filename: "declaracao_#{@aluno.matricula}_#{@ano_letivo.ano}.pdf",
                    type: "application/pdf",
                    disposition: "attachment"
        end
      end
    else
      redirect_to aluno_declaracoes_path, alert: "Turma não encontrada para o ano letivo #{@ano_letivo.ano}."
    end
  end
end