require 'prawn'
require_relative '../../pdfs/boletim_pdf' 

class Aluno::BoletinsController < ApplicationController
  layout 'dashboard'
  
  include DisciplinaHelper 
  before_action :authenticate_aluno!
  
  # Torna o método privado acessível na View e no PDF (via view_context)
  helper_method :determinar_situacao_final 

  # GET /aluno/boletins
  def index
    @anos_letivos = current_aluno.anos_letivos_com_notas
  end

  # GET /aluno/boletins/show_por_ano/:id
  def show_por_ano
  @ano_letivo = AnoLetivo.find(params[:id])

  # Tenta via AvaliacaoBimestral (nota) ou via RegistroDeNota (conceito)
  @turma = buscar_turma_do_aluno_no_ano(current_aluno, @ano_letivo)

  if @turma
    @aluno = current_aluno

    avaliacoes = AvaliacaoBimestral
      .includes(:disciplina)
      .where(aluno_id: @aluno.id, turma_id: @turma.id)
      .order('disciplinas.nome', :bimestre)

    @boletim_disciplinas = avaliacoes.group_by(&:disciplina)
    @frequencia_por_disciplina = calcular_frequencia_por_disciplina(@turma, @aluno)

    respond_to do |format|
      format.html
      format.pdf do
        pdf = BoletimPdf.new(@aluno, @turma, @ano_letivo, @boletim_disciplinas, @frequencia_por_disciplina, view_context)
        send_data pdf.render,
                  filename: "boletim_#{@aluno.matricula}_#{@ano_letivo.ano}.pdf",
                  type: "application/pdf",
                  disposition: "attachment"
      end
    end
  else
    redirect_to aluno_boletins_path, alert: "Turma não encontrada para o ano letivo #{@ano_letivo.ano}."
  end
end

  def enviar_email
    @aluno = current_aluno
    @ano_letivo = AnoLetivo.find(params[:id])
    @turma = buscar_turma_do_aluno_no_ano(@aluno, @ano_letivo)
    
    # Validação: verificar se a turma existe
    unless @turma
      redirect_back fallback_location: root_path, 
                    alert: "Turma não encontrada para o ano letivo #{@ano_letivo.ano}"
      return
    end
    
    # Carregar os mesmos dados que você carrega no show_por_ano
    avaliacoes = AvaliacaoBimestral
      .includes(:disciplina)
      .where(aluno_id: @aluno.id, turma_id: @turma.id)
      .order('disciplinas.nome', :bimestre)
    
    @boletim_disciplinas = avaliacoes.group_by(&:disciplina)
    @frequencia_por_disciplina = calcular_frequencia_por_disciplina(@turma, @aluno)
    
    # Determinar email de destino
    email_destino = if params[:usar_email_aluno] == 'true'
      @aluno.email
    else
      params[:email_destino]
    end
    
    if email_destino.blank?
      redirect_back fallback_location: root_path, 
                    alert: 'Email de destino não informado'
      return
    end
    
    # Gerar o PDF usando a mesma classe da view
    pdf = BoletimPdf.new(@aluno, @turma, @ano_letivo, @boletim_disciplinas, @frequencia_por_disciplina, view_context)
    pdf_content = pdf.render
    
    # Enviar o email com o PDF anexado
    BoletimMailer.enviar_boletim(@aluno, email_destino, @ano_letivo, pdf_content).deliver_later
    
    redirect_back fallback_location: root_path,
                  notice: "Boletim enviado com sucesso para #{email_destino}"
  rescue StandardError => e
    redirect_back fallback_location: root_path,
                  alert: "Erro ao enviar email: #{e.message}"
  end

  private

  def buscar_turma_do_aluno_no_ano(aluno, ano_letivo)
    # Primeiro tenta via AvaliacaoBimestral (turmas de nota)
    turma = Turma.joins(:avaliacoes_bimestrais)
                .where(ano_letivo_id: ano_letivo.id,
                        avaliacoes_bimestrais: { aluno_id: aluno.id })
                .first

    # Se não encontrou, tenta via RegistroDeNota (turmas de conceito)
    turma ||= Turma.joins(avaliacoes_configuracoes: :registros_de_notas)
                  .where(ano_letivo_id: ano_letivo.id,
                          registros_de_notas: { aluno_id: aluno.id })
                  .first

    # Fallback: turma atual do aluno
    turma ||= aluno.turma if aluno.turma&.ano_letivo_id == ano_letivo.id

    turma
  end

  # Método para calcular Frequência: Total de Aulas e Total de Faltas por Disciplina
  def calcular_frequencia_por_disciplina(turma, aluno)
    # Busca o total de aulas dadas por disciplina na turma
    aulas_dadas = Frequencia
      .where(turma_id: turma.id)
      .group(:disciplina_id)
      .count

    # Busca o total de faltas do aluno por disciplina na turma
    faltas_por_disciplina = FrequenciaAluno
      .joins(:frequencia) 
      .where(aluno_id: aluno.id, frequencias: { turma_id: turma.id }, status: 'falta')
      .group('frequencias.disciplina_id')
      .count

    frequencia_combinada = {}
    
    aulas_dadas.each do |disciplina_id, total_aulas|
      total_faltas = faltas_por_disciplina[disciplina_id] || 0
      
      frequencia_combinada[disciplina_id] = {
        total_aulas: total_aulas,
        total_faltas: total_faltas
      }
    end
    
    return frequencia_combinada
  end
  
  # MÉTODO: Lógica de Situação Final
  def determinar_situacao_final(media_anual, frequencia_percentual)
    media_minima = 6.0
    frequencia_minima = 75.0

    if media_anual.nil? || frequencia_percentual.nil?
      return { texto: 'Aguardando', class: 'text-gray-500' }
    end

    if frequencia_percentual < frequencia_minima
      return { texto: 'Reprovado por Falta', class: 'text-error' }
    end

    if media_anual >= media_minima
      return { texto: 'Aprovado', class: 'text-success' }
    elsif media_anual >= (media_minima - 1)
      return { texto: 'Recuperação', class: 'text-warning' }
    else
      return { texto: 'Reprovado', class: 'text-error' }
    end
  end
end