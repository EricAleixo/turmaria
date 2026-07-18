class DeclaracoesPublicasController < ApplicationController
  skip_before_action :authenticate_aluno!, raise: false
  layout 'application'

  def show
    @declaracao = Declaracao.find_by(codigo_curto: params[:codigo]&.upcase)
  end
end