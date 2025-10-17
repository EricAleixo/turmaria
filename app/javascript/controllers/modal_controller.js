import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // 1. Previne a rolagem do fundo da página
    document.body.classList.add("overflow-hidden");
  }

  hide(event) {
    event.preventDefault(); 
    
    // 1. Remove o 'overflow-hidden'
    document.body.classList.remove("overflow-hidden");
    
    // 2. LIMPA O CONTEÚDO DO TURBO FRAME.
    const turboFrame = this.element.closest("turbo-frame");
    if (turboFrame) {
      turboFrame.innerHTML = '';
    } else {
      this.element.remove();
    }
  }
}