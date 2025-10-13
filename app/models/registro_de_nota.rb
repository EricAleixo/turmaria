class RegistroDeNota < ApplicationRecord
  require Rails.root.join('app', 'services', 'notas', 'calculadora_bimestral.rb')
  # Associações (como você já havia corrigido)
  belongs_to :aluno
  belongs_to :avaliacao_configuracao, class_name: 'AvaliacaoConfiguracao' 

  self.table_name = 'registros_de_notas'
  
  # Associações adicionais para facilitar o acesso aos dados
  has_one :turma, through: :avaliacao_configuracao
  has_one :disciplina, through: :avaliacao_configuracao

  # Validações
  validates :valor, presence: true, numericality: { greater_than_or_equal_to: 0.0, less_than_or_equal_to: 10.0 }
  validates :aluno_id, uniqueness: { scope: :avaliacao_configuracao_id, message: "já possui uma nota registrada para esta avaliação." }
  
  # CALLBACKS CRUCIAIS PARA O CÁLCULO
  # Após salvar (criar ou atualizar)
  after_save :recalcular_media_bimestral
  # Após excluir
  after_destroy :recalcular_media_bimestral

  private
  
  # Chama o Objeto de Serviço para recalcular a média
  def recalcular_media_bimestral
    ::Notas::CalculadoraBimestral.new(self).call
  end
end