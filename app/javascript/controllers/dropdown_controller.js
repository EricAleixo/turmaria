import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    const hiddenId = this.element.dataset.dropdownHiddenFieldId;
    const hidden = document.getElementById(hiddenId);
    const label = this.element.querySelector(".dropdown-label");
    const selectedValue = hidden.value;
    const selectedOption = Array.from(this.element.querySelectorAll(".dropdown-option"))
      .find(o => o.dataset.value === selectedValue);
    
    if (selectedOption && label) {
      label.textContent = selectedOption.textContent;
      selectedOption.classList.add("!bg-green-500", "text-white");
    }
    
    this.element.querySelectorAll(".dropdown-option").forEach(option => {
      option.addEventListener("click", e => {
        e.preventDefault();
        
        // Verifica se a opção está desabilitada
        if (option.dataset.disabled === 'true') {
          return; // Não faz nada se estiver desabilitada
        }
        
        hidden.value = option.dataset.value;
        label.textContent = option.textContent;
        this.element.querySelectorAll(".dropdown-option").forEach(o => o.classList.remove("!bg-green-500", "text-white"));
        option.classList.add("!bg-green-500", "text-white");
        this.element.removeAttribute("open");
      });
    });
    
    document.addEventListener("click", e => {
      document.querySelectorAll("details.dropdown[open]").forEach(dropdown => {
        if (!dropdown.contains(e.target)) dropdown.removeAttribute("open");
      });
    });
  }
}