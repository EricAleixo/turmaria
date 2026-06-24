class Professor::Notas::RegistrosController < ApplicationController
  before_action :set_turma_disciplina_e_configuracao
  before_action :authenticate_professor!
  layout 'dashboard'

  def new
    @alunos = @turma.alunos.order(:nome)

    if @alunos.empty?
      flash[:alert] = "Não é possível lançar notas: A turma '#{@turma.nome}' não possui alunos matriculados."
      redirect_to professor_turma_disciplina_notas_avaliacoes_path(@turma, @disciplina) and return
    end

    @registros = build_registros(@alunos)
    @registros_form = OpenStruct.new(registros: @registros)
  end

  def create
    registros_data = registros_params[:registros]
    success = true

    ActiveRecord::Base.transaction do
      registros_data.each do |aluno_id, data|
        registro = RegistroDeNota.find_or_initialize_by(
          aluno_id: aluno_id,
          avaliacao_configuracao: @avaliacao_configuracao
        )

        valor_bruto = data[:valor].presence

        if valor_bruto
          if @turma.usa_conceito?
            registro.conceito      = valor_bruto.downcase.strip
            registro.valor         = nil
          else
            registro.valor         = normalize_decimal(valor_bruto)
            registro.conceito      = nil
          end

          registro.data_registro = Date.current

          
          Rails.logger.debug "ANTES DE SALVAR — valor: #{registro.valor.inspect}, conceito: #{registro.conceito.inspect}, valid?: #{registro.valid?}, errors: #{registro.errors.full_messages}"
          unless registro.save
            Rails.logger.error "ERRO REGISTRO: #{registro.errors.full_messages}"
            success = false
            raise ActiveRecord::Rollback
          end
        elsif registro.persisted?
          registro.destroy
        end
      end
    end

    if success
      redirect_to professor_turma_disciplina_notas_avaliacoes_path(@turma, @disciplina),
                  notice: (@turma.usa_conceito? ? 'Conceitos salvos com sucesso!' : 'Notas salvas e recalculadas com sucesso!')
    else
      flash.now[:alert] = 'Erro ao salvar. Verifique os valores informados.'
      @alunos   = @turma.alunos.order(:nome)
      @registros = build_registros(@alunos)
      @registros_form = OpenStruct.new(registros: @registros)
      render :new, status: :unprocessable_entity
    end
  end

  private

  def build_registros(alunos)
    alunos.map do |aluno|
      RegistroDeNota.find_or_initialize_by(
        aluno: aluno,
        avaliacao_configuracao: @avaliacao_configuracao
      )
    end
  end

  def normalize_decimal(value)
    return nil if value.blank?
    value.to_s.gsub(',', '.').to_f
  end

  def set_turma_disciplina_e_configuracao
    @turma                  = Turma.find(params[:turma_id])
    @disciplina             = Disciplina.find(params[:disciplina_id])
    @avaliacao_configuracao = AvaliacaoConfiguracao.find(params[:avaliaco_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: 'Recurso não encontrado.'
  end

  def registros_params
    params.require(:open_struct).permit(registros: data_para_salvar)
  end

  def data_para_salvar
    params.require(:open_struct).fetch(:registros, {}).keys.map do |aluno_id|
      { aluno_id.to_sym => [ :aluno_id, :valor ] }
    end.reduce({}, :merge)
  end
end