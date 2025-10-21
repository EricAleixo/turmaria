class AdministradoresController < ApplicationController
  layout 'dashboard'
  before_action :set_administrador, only: [:show, :edit, :update, :destroy]
  protect_from_forgery except: [:confirm_upload, :generate_presigned_url]

  # Gera URL temporária para upload direto S3
  def generate_presigned_url
    key = "admin_fotos/#{SecureRandom.uuid}.png"
    s3 = Aws::S3::Resource.new(region: ENV['AWS_REGION'])
    obj = s3.bucket(ENV['AWS_BUCKET']).object(key)
    presigned_url = obj.presigned_url(:put, acl: 'public-read', expires_in: 300) # 5 min
    render json: { url: presigned_url, key: key }
  end

  # Confirma upload, processa imagem e anexa ao ActiveStorage
  def confirm_upload
    key = params[:key]
    return render json: { error: 'Chave ausente' }, status: :unprocessable_entity unless key

    s3 = Aws::S3::Client.new(region: ENV['AWS_REGION'])
    tempfile = Tempfile.new
    s3.get_object(bucket: ENV['AWS_BUCKET'], key: key, response_target: tempfile.path)

    processed = ImageProcessing::MiniMagick
                  .source(tempfile.path)
                  .resize_to_limit(800, 800)
                  .convert('png')
                  .call

    current_administrador.foto.attach(
      io: File.open(processed.path),
      filename: "admin_foto_#{SecureRandom.hex}.png"
    )

    s3.delete_object(bucket: ENV['AWS_BUCKET'], key: key)

    render json: { url: url_for(current_administrador.foto) }
  end

  def index
    @administradores = Admin.all
  end

  def show; end

  def new
    @admin = Admin.new
  end

  def create
    @admin = Admin.new(admin_params.except(:foto))

    if @admin.save
      attach_foto(@admin, admin_params[:foto])
      redirect_to administradore_path(@admin), notice: "Administrador criado com sucesso!"
    else
      flash.now[:alert] = @admin.errors.full_messages.join(", ")
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @admin.update(admin_params_for_update.except(:foto))
      attach_foto(@admin, admin_params_for_update[:foto])
      redirect_to administradore_path(@admin), notice: "Administrador atualizado com sucesso!"
    else
      flash.now[:alert] = @admin.errors.full_messages.join(", ")
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @admin.destroy
    redirect_to administradores_path, notice: "Administrador removido com sucesso!"
  end

  private

  def set_administrador
    @admin = Admin.find(params[:id])
  end

  def admin_params
    params.require(:admin).permit(:email, :nome, :password, :password_confirmation, :foto)
  end

  def admin_params_for_update
    permitted_params = [:email, :nome]
    if params[:admin][:password].present?
      permitted_params += [:password, :password_confirmation]
    end
    params.require(:admin).permit(permitted_params, :foto)
  end

  # --- helper para attach de foto com purge da anterior ---
  def attach_foto(admin, uploaded_or_signed)
    return unless uploaded_or_signed.present?

    # remove anterior
    admin.foto.purge if admin.foto.attached?

    # Rails ActiveStorage reconhece se é signed_id ou arquivo normal
    admin.foto.attach(uploaded_or_signed)
  end
end
