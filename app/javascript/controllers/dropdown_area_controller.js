import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    const hiddenId = this.element.dataset.dropdownAreaHiddenFieldId;
    const colorFieldId = this.element.dataset.dropdownAreaColorFieldId;
    const hidden = document.getElementById(hiddenId);
    const colorField = document.getElementById(colorFieldId);
    const label = this.element.querySelector(".dropdown-label");
    const selectedValue = hidden.value;

    // Marca a opção selecionada inicialmente
    if (selectedValue) {
      const selectedOption = Array.from(this.element.querySelectorAll(".dropdown-option"))
        .find(o => o.dataset.value === selectedValue);

      if (selectedOption && label) {
        // Remove o ícone e pega só o texto da área
        const textoArea = selectedOption.querySelector('span:last-child') 
          ? selectedOption.textContent.trim() 
          : selectedOption.dataset.area;
        label.textContent = textoArea;
        selectedOption.classList.add("!bg-green-500", "!text-white");
      }
    }

    // Adiciona evento de clique nas opções
    this.element.querySelectorAll(".dropdown-option").forEach(option => {
      option.addEventListener("click", e => {
        e.preventDefault();
        
        // Se for o botão "Criar nova área", não faz nada aqui (deixa a lógica existente funcionar)
        if (option.id === "criar-nova-area-option") {
          this.element.removeAttribute("open");
          return;
        }
        
        // Atualiza os campos hidden
        hidden.value = option.dataset.value;
        if (option.dataset.cor && colorField) {
          colorField.value = option.dataset.cor;
        }
        
        // Atualiza o texto do label (pega só o texto, sem o círculo colorido)
        const textoArea = option.dataset.area || option.textContent.trim();
        label.textContent = textoArea;
        
        // Remove destaque de todas as opções
        this.element.querySelectorAll(".dropdown-option").forEach(o => {
          o.classList.remove("!bg-green-500", "!text-white");
        });
        
        // Adiciona destaque na opção selecionada
        option.classList.add("!bg-green-500", "!text-white");
        
        // Fecha o dropdown
        this.element.removeAttribute("open");
      });
    });

    // Fecha dropdowns ao clicar fora (vinculado ao elemento para evitar duplicação)
    this.clickOutsideHandler = (e) => {
      if (this.element.hasAttribute("open") && !this.element.contains(e.target)) {
        this.element.removeAttribute("open");
      }
    };
    
    document.addEventListener("click", this.clickOutsideHandler);
  }

  disconnect() {
    // Remove o event listener quando o controller é desconectado
    if (this.clickOutsideHandler) {
      document.removeEventListener("click", this.clickOutsideHandler);
    }
  }
}