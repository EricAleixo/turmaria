class Professor::TurmasController < ApplicationController
  layout 'dashboard'
  before_action :authenticate_professor!
  before_action :set_turma, only: [:historico]

  def index
    @turmas = current_user.turmas.includes(:alunos, :frequencias)
    @estatisticas = calcular_estatisticas
  end

  def historico
    # Pegar o mês e ano dos parâmetros, ou usar o atual
    @mes = params[:mes]&.to_i || Date.current.month
    @ano = params[:ano]&.to_i || Date.current.year
    
    # Criar data do primeiro dia do mês
    @data_inicio = Date.new(@ano, @mes, 1)
    @data_fim = @data_inicio.end_of_month
    
    # Buscar todas as frequências da turma no mês
    @frequencias = @turma.frequencias
                         .where(data_aula: @data_inicio..@data_fim)
                         .includes(:frequencia_alunos, :alunos)
    
    # Criar hash com as datas que têm frequência registrada
    @datas_com_frequencia = @frequencias.pluck(:data_aula).to_set
    
    # Estatísticas do mês
    @estatisticas_mes = {
      total_aulas: @frequencias.count,
      total_alunos: @turma.alunos.count,
      media_presenca: calcular_media_presenca_mes
    }
  end

  private

  def set_turma
    @turma = current_user.turmas.find(params[:turma_id])
  end

  def calcular_estatisticas
    {
      total_turmas: @turmas.count,
      total_alunos: @turmas.sum { |turma| turma.alunos.count },
      frequencias_registradas: @turmas.sum { |turma| turma.frequencias.count },
      turmas_com_frequencia_hoje: @turmas.select { |turma| 
        turma.frequencias.where(data_aula: Date.current).exists? 
      }.count
    }
  end

  def calcular_media_presenca_mes
    return 0 if @frequencias.empty?
    
    total_presencas = @frequencias.sum(&:total_presentes)
    total_possivel = @frequencias.sum(&:total_alunos)
    
    return 0 if total_possivel.zero?
    
    ((total_presencas.to_f / total_possivel) * 100).round(1)
  end
end
