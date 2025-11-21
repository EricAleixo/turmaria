# app/models/disciplina.rb
class Disciplina < ApplicationRecord
  # Associações
  has_many :turma_disciplinas
  has_many :turmas, through: :turma_disciplinas

  has_many :avaliacoes_configuracoes, 
           class_name: 'AvaliacaoConfiguracao', 
           foreign_key: 'disciplina_id'
  has_many :avaliacoes_bimestrais

  has_many :professor_disciplinas
  has_many :professores, through: :professor_disciplinas, source: :professor
  
  belongs_to :escola
  belongs_to :area_disciplina, optional: true
  has_many :conteudos, dependent: :destroy

  # Atributos virtuais para receber dados do formulário
  attr_accessor :area_nome_temp, :area_cor_temp

  # Validações
  validates :nome, presence: { message: "não pode ficar em branco" }
  validates :escola_id, presence: { message: "deve ser selecionada" }

  # Callbacks 
  before_validation :associar_ou_criar_area

  private

  def associar_ou_criar_area
    # Se não tem area_nome_temp, não faz nada
    return if area_nome_temp.blank?
    
    # Remove espaços extras
    nome_limpo = area_nome_temp.to_s.strip
    
    Rails.logger.info "🔍 Procurando área: #{nome_limpo}"
    Rails.logger.info "🎨 Com cor: #{area_cor_temp}"
    
    # Busca a área existente (case insensitive)
    area_encontrada = AreaDisciplina.where("LOWER(nome) = ?", nome_limpo.downcase).first
    
    if area_encontrada
      Rails.logger.info "✅ Área encontrada: #{area_encontrada.nome} (ID: #{area_encontrada.id})"
      
      # Se a área já existe, apenas associa
      self.area_disciplina = area_encontrada
      
      # Atualiza a cor se foi fornecida uma nova e é diferente
      if area_cor_temp.present? && area_encontrada.cor != area_cor_temp
        Rails.logger.info "🎨 Atualizando cor de #{area_encontrada.cor} para #{area_cor_temp}"
        area_encontrada.update(cor: area_cor_temp)
      end
    else
      Rails.logger.info "➕ Criando nova área: #{nome_limpo}"
      
      # Se não existe, cria uma nova área com a cor selecionada
      cor_final = area_cor_temp.presence || cor_nome.presence || "#6B7280"
      Rails.logger.info "🎨 Cor final: #{cor_final}"
      
      nova_area = AreaDisciplina.new(
        nome: nome_limpo,
        cor: cor_final
      )
      
      if nova_area.save
        Rails.logger.info "✅ Área criada com sucesso: #{nova_area.nome} (ID: #{nova_area.id})"
        self.area_disciplina = nova_area
      else
        Rails.logger.error "❌ Erro ao criar área: #{nova_area.errors.full_messages.join(', ')}"
        errors.add(:area_nome_temp, "não pôde ser criada: #{nova_area.errors.full_messages.join(', ')}")
      end
    end
    
    Rails.logger.info "📌 Disciplina.area_disciplina_id: #{area_disciplina_id}"
  end
end