module Notas
  class CalculadoraBimestral
    def initialize(registro_de_nota)
      @registro   = registro_de_nota
      @aluno      = registro_de_nota.aluno
      @config     = registro_de_nota.avaliacao_configuracao
      @turma      = @config.turma
      @disciplina = @config.disciplina
      @bimestre   = @config.bimestre
    end

    def call
      # Turmas de conceito não calculam média numérica
      return if @turma.usa_conceito?

      configs_do_bimestre = ::AvaliacaoConfiguracao
                              .do_bimestre(@bimestre)
                              .where(turma_id: @turma.id, disciplina_id: @disciplina.id)
                              .order(created_at: :asc)

      notas_finais_para_calculo = {}

      configs_do_bimestre.each do |config|
        registro_nota = ::RegistroDeNota.find_by(aluno: @aluno, avaliacao_configuracao: config)
        next unless registro_nota
        next if registro_nota.valor.nil?

        if config.recuperacao?
          original_id   = config.avaliacao_original_id
          nota_original = notas_finais_para_calculo[original_id]

          if nota_original.present? && registro_nota.valor > nota_original
            notas_finais_para_calculo[original_id] = registro_nota.valor
            Rails.logger.info "Recuperação '#{config.nome}' substituiu nota original (ID: #{original_id})."
          end
        else
          notas_finais_para_calculo[config.id] = registro_nota.valor
        end
      end

      return salvar_media(0.0) if notas_finais_para_calculo.empty?

      soma_das_notas     = notas_finais_para_calculo.values.sum
      quantidade_de_notas = notas_finais_para_calculo.size
      media_calculada    = soma_das_notas.to_f / quantidade_de_notas.to_f

      salvar_media(media_calculada)
    end

    private

    def salvar_media(media)
      avaliacao_bimestral = ::AvaliacaoBimestral.find_or_initialize_by(
        aluno:      @aluno,
        turma:      @turma,
        disciplina: @disciplina,
        bimestre:   @bimestre
      )

      avaliacao_bimestral.nota_bimestre_final = media.round(2)

      if avaliacao_bimestral.save
        Rails.logger.info "Média bimestral (#{@bimestre}º) do aluno #{@aluno.id} atualizada para #{media.round(2)}."
        true
      else
        Rails.logger.error "ERRO ao salvar AvaliacaoBimestral: #{avaliacao_bimestral.errors.full_messages.join(', ')}"
        false
      end
    end
  end
end