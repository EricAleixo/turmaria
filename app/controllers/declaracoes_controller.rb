class DeclaracoesController < ApplicationController
  layout "dashboard"
  before_action :authorize_admin_or_super_admin!
  before_action :set_escola, only: [:configuracoes, :update_configuracoes, :preview, :posicionar_assinatura, :salvar_posicao_assinatura]
  before_action :authorize_escola_access!, only: [:configuracoes, :update_configuracoes, :preview, :posicionar_assinatura, :salvar_posicao_assinatura]

  def selecionar_escola
    @escolas = if current_user.is_a?(SuperAdmin)
    Escola.all.order(:nome)
    else
    current_user.escolas.order(:nome)
    end
  end

  def configuracoes
  end

  def update_configuracoes
    if @escola.update(escola_params)
    redirect_to configuracoes_escola_declaracao_path(@escola), notice: "Configurações da declaração atualizadas com sucesso!"
    else
    render :configuracoes, status: :unprocessable_entity
    end
  end

  def preview
      @aluno = @escola.alunos.first
      @ano_letivo = @escola.ano_letivos.first || AnoLetivo.first
      @turma = @aluno&.turma

  if @aluno && @turma && @ano_letivo
        @declaracao = Declaracao.new(
    aluno: @aluno,
    turma: @turma,
    ano_letivo: @ano_letivo,
    codigo_autenticidade: "PREVIEW-AUTENTICIDADE",
    token: "preview-token",
    emitido_em: Time.current,
    codigo_curto: "PRVW"
          )

    respond_to do |format|
    format.html do
    pdf = DeclaracaoPdf.new(@aluno, @turma, @ano_letivo, @declaracao, view_context)
    send_data pdf.render,
    filename: "preview_declaracao_#{@escola.nome.parameterize}.pdf",
    type: "application/pdf",
    disposition: "inline"
    end
    end
  else
    redirect_to configuracoes_escola_declaracao_path(@escola), alert: "Para visualizar o PDF de teste, a escola precisa ter pelo menos um aluno, um ano letivo e uma turma cadastrados."
  end
  end

  def posicionar_assinatura
      if @escola.declaracao_assinatura_imagem.blank?
        redirect_to configuracoes_escola_declaracao_path(@escola),
                    alert: "Salve uma assinatura desenhada antes de ajustar a posição dela."
      end
  end

  def salvar_posicao_assinatura
      if @escola.update(posicao_assinatura_params)
        render json: { ok: true }
      else
        render json: { ok: false, errors: @escola.errors.full_messages }, status: :unprocessable_entity
      end
  end

  private

  def authorize_admin_or_super_admin!
    unless current_user.is_a?(SuperAdmin) || current_user.is_a?(Admin)
    redirect_to root_path, alert: "Acesso negado"
    end
  end

  def authorize_escola_access!
    if current_user.is_a?(Admin) && !current_user.escolas.include?(@escola)
    redirect_to selecionar_escola_declaracoes_path, alert: "Você não tem permissão para acessar esta escola."
    end
  end

  def set_escola
      @escola = Escola.find(params[:escola_id])
  end

  def escola_params
    params.require(:escola).permit(
    :declaracao_cabecalho,
    :declaracao_corpo,
    :declaracao_assinatura_cargo,
    :declaracao_assinatura_nome,
    :declaracao_assinatura_imagem
        )
  end

  def posicao_assinatura_params
    params.require(:escola).permit(
    :declaracao_assinatura_pos_x,
    :declaracao_assinatura_pos_y
        )
  end
end