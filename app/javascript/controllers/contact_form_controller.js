// app/javascript/controllers/contact_form_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["contactInput", "contactIcon", "submitBtn"]

  icons = {
    email: `
      <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
        <path stroke-linecap="round" stroke-linejoin="round" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"/>
      </svg>`,
    phone: `
      <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
        <path stroke-linecap="round" stroke-linejoin="round" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"/>
      </svg>`
  }

  // Chamado externamente pelo scrollToContact() para pré-selecionar o assunto
  preselectSubject(value) {
    const radio = this.element.querySelector(`input[value="${value}"]`)
    if (radio) {
      radio.checked = true
      radio.dispatchEvent(new Event("change", { bubbles: true }))
    }
  }

  // Altera o campo de contato conforme o método selecionado (email ou telefone)
  updateContactMethod(event) {
    const method = event.target.value
    const input = this.contactInputTarget
    const icon  = this.contactIconTarget

    input.type        = method === "email" ? "email" : "tel"
    input.placeholder = method === "email" ? "seu@email.com" : "(00) 00000-0000"
    icon.innerHTML    = this.icons[method]
    input.value       = ""
    input.focus()
  }

  // Atualiza a cor do botão de submit conforme o assunto selecionado
  updateSubject(event) {
    const btn     = this.submitBtnTarget
    const subject = event.target.value

    btn.classList.remove("bg-blue-500", "hover:bg-blue-600", "bg-emerald-500", "hover:bg-emerald-600")
    btn.classList.add(
      subject === "solicitar_acesso"
        ? "bg-blue-500"    : "bg-emerald-500",
      subject === "solicitar_acesso"
        ? "hover:bg-blue-600" : "hover:bg-emerald-600"
    )
  }
}