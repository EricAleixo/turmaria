# app/mailers/boletim_mailer.rb
class BoletimMailer < ApplicationMailer
  default from: ENV["EMAIL_USERNAME"]
  
  def enviar_boletim(aluno, email_destino, ano_letivo, pdf_content)
    @aluno = aluno
    @ano_letivo = ano_letivo
    
    # Anexa o PDF que já vem gerado do controller
    attachments["boletim_#{@aluno.matricula}_#{@ano_letivo.ano}.pdf"] = pdf_content
    
    mail(
      to: email_destino,
      subject: "Boletim Escolar - #{@aluno.nome} - #{@ano_letivo.ano}"
    )
  end
end