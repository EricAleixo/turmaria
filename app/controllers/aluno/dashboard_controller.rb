# app/controllers/aluno/dashboard_controller.rb
class Aluno::DashboardController < ApplicationController
  layout 'dashboard'
  before_action :authenticate_aluno! # Garante que apenas o aluno logado acesse

  def index
    # Usamos 'try' para o caso de 'current_aluno' não ser um objeto que responde a 'includes'
    @aluno = current_aluno.try(:includes, turmas: [:ano_letivo]).try(:first)
    
    # Se o aluno não for encontrado, definimos padrões seguros e saímos
    if @aluno.nil?
      @frequencia_percentual = '0.0%'
      @total_faltas = 0
      @media_geral_notas = 0.0 # <-- Definido como 0.0 (Float)
      @ultimas_faltas = []
      @turma_atual = nil
      @titulo_pagina = "Dashboard | Aluno Não Encontrado"
      return
    end

    # 1. Dados de Frequência (Global - Todas as turmas)
    total_registros = FrequenciaAluno.where(aluno_id: @aluno.id).count
    faltas_registradas = FrequenciaAluno.where(aluno_id: @aluno.id).where.not(status: 'presente').count
    
    @frequencia_percentual = if total_registros.zero?
      '0.0%'
    else
      presencas = total_registros - faltas_registradas
      media = (presencas.to_f / total_registros) * 100
      "%.1f%%" % media
    end
    
    @total_faltas = faltas_registradas
    
    # 2. Dados de Notas (Média Geral Atual)
    notas_registradas = RegistroDeNota.where(aluno_id: @aluno.id)
    
    # 🛑 CORREÇÃO DEFINITIVA PARA O ERRO 'can't convert nil into Float' 🛑
    if notas_registradas.present?
      # .average pode retornar nil.
      media_simples = notas_registradas.average(:valor)
      
      # Garantimos que, se media_simples for nil, seja 0.0 para que .round(1) não falhe.
      @media_geral_notas = (media_simples || 0.0).round(1) 
    else
      # Quando não há registros, definimos explicitamente como 0.0 (Float)
      @media_geral_notas = 0.0
    end
    
    # 3. Tabela: Últimas Faltas (Detalhes de Frequência)
    @ultimas_faltas = FrequenciaAluno.where(aluno_id: @aluno.id)
                                    .where.not(status: 'presente')
                                    .includes(frequencia: [:turma, :disciplina])
                                    .order(created_at: :desc)
                                    .limit(10)
                                    
    # Garante que @turma_atual é um objeto ou nil (correção do erro 'Turma não atribuída')
    @turma_atual = @aluno.turmas.last 
    
    @titulo_pagina = "Dashboard | #{@aluno.nome}"
  end
end