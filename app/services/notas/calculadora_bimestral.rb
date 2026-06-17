module Notas
  class CalculadoraBimestral
    
    def initialize(registro_de_nota)
      @registro = registro_de_nota
      @aluno = registro_de_nota.aluno
      @config = registro_de_nota.avaliacao_configuracao
      @turma = @config.turma
      @disciplina = @config.disciplina
      @bimestre = @config.bimestre
    end

    def call
      # 1. Coleta todas as AvaliacaoConfiguracao (Padrão e Recuperação) do bimestre
      # A ordenação por created_at agora define a ordem de cálculo/exibição.
      configs_do_bimestre = ::AvaliacaoConfiguracao
                            .do_bimestre(@bimestre)
                            .where(turma_id: @turma.id, disciplina_id: @disciplina.id)
                            .order(created_at: :asc)
                            
      # 2. Inicializa o hash de notas que serão usadas no cálculo { config_id => nota_a_ser_usada }
      notas_finais_para_calculo = {}
      
      # 3. Processa cada configuração de avaliação
      configs_do_bimestre.each do |config|
        registro_nota = ::RegistroDeNota
                        .find_by(aluno: @aluno, avaliacao_configuracao: config)
        
        next unless registro_nota
        
        if config.recuperacao?
          # Se for recuperação, verifica a nota original que deve ser substituída
          original_id = config.avaliacao_original_id
          
          # 🚨 NOVO: A nota de recuperação SÓ substitui se for MAIOR que a nota original
          nota_original = notas_finais_para_calculo[original_id]
          
          if nota_original.present? && registro_nota.valor > nota_original
            # Substituição: a nota da recuperação passa a ser a nota usada para a config original
            notas_finais_para_calculo[original_id] = registro_nota.valor
            Rails.logger.info "Recuperação de #{config.nome} (ID: #{config.id}) substituiu nota original (ID: #{original_id}) no cálculo."
          end
          
        else
          # Se for avaliação PADRÃO, armazena seu valor como a nota inicial.
          # Este valor será potencialmente substituído por uma recuperação posterior.
          notas_finais_para_calculo[config.id] = registro_nota.valor
        end
      end
      
      # 4. Cálculo da Média Final
      return salvar_media(0.0) if notas_finais_para_calculo.empty?

      soma_das_notas = notas_finais_para_calculo.values.sum
      quantidade_de_notas = notas_finais_para_calculo.size
      media_calculada = soma_das_notas.to_f / quantidade_de_notas.to_f
      
      # 5. Salva o resultado
      salvar_media(media_calculada)
    end

    private
    
    # Encontra ou cria o registro AvaliacaoBimestral e salva a média (mantido)
    def salvar_media(media)
       avaliacao_bimestral = ::AvaliacaoBimestral.find_or_initialize_by( 
         aluno: @aluno,
         turma: @turma,
         disciplina: @disciplina,
         bimestre: @bimestre
       )
       
       avaliacao_bimestral.nota_bimestre_final = media.round(2)
       
       if avaliacao_bimestral.save
         Rails.logger.info "Média BIMESTRAL (Bimestre #{@bimestre}) para o aluno #{@aluno.id} atualizada para #{media.round(2)}."
         return true
       else
         Rails.logger.error "ERRO ao salvar AvaliacaoBimestral: #{avaliacao_bimestral.errors.full_messages.join(', ')}"
         return false
       end
    end
  end
end