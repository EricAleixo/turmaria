class AvaliacaoBimestral < ApplicationRecord
  # Associações
  belongs_to :aluno
  belongs_to :turma
  belongs_to :disciplina

  # Validações
  validates :bimestre, presence: true, numericality: { greater_than_or_equal_to: 1 }
  validates :nota_bimestre_final, numericality: { allow_nil: true, greater_than_or_equal_to: 0.0, less_than_or_equal_to: 10.0 }
  validates :aluno_id, uniqueness: { scope: [:turma_id, :disciplina_id, :bimestre], message: "já tem uma nota final para este bimestre/disciplina." }

  # Lógica de negócio: Cálculo da média
  # Usaremos um método de instância (ou futuremente, um service object)

  # Método para calcular a nota final a partir dos registros de notas
  def calcular_media!
    # 1. Encontrar as configurações de avaliação (colunas de nota) para esta combinação
    configs = AvaliacaoConfiguracao.padrao
                                  .where(turma_id: turma_id, disciplina_id: disciplina_id, bimestre: bimestre)
                                  
    config_ids = configs.pluck(:id)

    # 2. Somar as notas do aluno APENAS para as configurações padrão (exclui recuperações)
    total_notas = RegistroDeNota.where(aluno_id: aluno_id, avaliacao_configuracao_id: config_ids)
                                .sum(:valor)
    
    # 3. Calcular a média
    if configs.any?
      media = total_notas.to_f / configs.count
      
      # 4. Atualizar o objeto
      self.nota_bimestre_final = media.round(2)
      self.save!
      media
    else
      # Se não houver configurações, a nota é nula ou zero, dependendo da regra de negócio.
      self.nota_bimestre_final = nil
      self.save!
      nil
    end
  end
end
