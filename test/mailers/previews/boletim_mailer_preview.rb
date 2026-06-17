# Preview all emails at http://localhost:3000/rails/mailers/boletim_mailer
class BoletimMailerPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/boletim_mailer/enviar_boletim
  def enviar_boletim
    BoletimMailer.enviar_boletim
  end

end
