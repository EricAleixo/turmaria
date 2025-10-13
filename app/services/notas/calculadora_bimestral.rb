module Notas
  class CalculadoraBimestral
    
    # Recebe o RegistroDeNota recém-salvo ou atualizado
    def initialize(registro_de_nota)
      @registro = registro_de_nota
      @aluno = registro_de_nota.aluno
      @config = registro_de_nota.avaliacao_configuracao
      @turma = @config.turma
      @disciplina = @config.disciplina
      @bimestre = @config.bimestre
    end

    # Método principal para executar o cálculo e salvar
    def call
      # 1. Encontra todas as notas (registros) do aluno para o bimestre
      # Usar ::RegistroDeNota para buscar no escopo global
      notas_do_bimestre = ::RegistroDeNota 
                            .joins(:avaliacao_configuracao)
                            .where(aluno_id: @aluno.id)
                            # CORRIGIDO: O nome da tabela é PLURAL (avaliacoes_configuracoes)
                            .where(avaliacoes_configuracoes: { 
                              turma_id: @turma.id,
                              disciplina_id: @disciplina.id,
                              bimestre: @bimestre,
                              is_recuperacao: false 
                            })

      # 2. Se não houver notas, a média é 0
      return salvar_media(0.0) if notas_do_bimestre.empty?

      # 3. Calcula a média simples (ou implemente média ponderada aqui)
      soma_das_notas = notas_do_bimestre.sum(:valor)
      quantidade_de_notas = notas_do_bimestre.count
      media_calculada = soma_das_notas.to_f / quantidade_de_notas.to_f
      
      # 4. Salva o resultado
      salvar_media(media_calculada)
    end

    private

    # Encontra ou cria o registro AvaliacaoBimestral e salva a média
    def salvar_media(media)
      # CORREÇÃO: Usar ::AvaliacaoBimestral para buscar no escopo global
      avaliacao_bimestral = ::AvaliacaoBimestral.find_or_initialize_by( 
        aluno: @aluno,
        turma: @turma,
        disciplina: @disciplina,
        bimestre: @bimestre
      )
      
      avaliacao_bimestral.nota_bimestre_final = media.round(2) # Arredonda para 2 casas decimais
      
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