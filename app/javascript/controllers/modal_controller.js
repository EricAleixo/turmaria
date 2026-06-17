import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    document.body.classList.add("overflow-hidden");
  }

  hide(event) {
    event.preventDefault(); 
    
    document.body.classList.remove("overflow-hidden");
    
    const turboFrame = this.element.closest("turbo-frame");
    if (turboFrame) {
      turboFrame.innerHTML = '';
    } else {
      this.element.remove();
    }
  }
}