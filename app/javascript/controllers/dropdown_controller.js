import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    const hiddenId = this.element.dataset.dropdownHiddenFieldId;
    const hidden = document.getElementById(hiddenId);
    const label = this.element.querySelector(".dropdown-label");
    const isRequired = this.element.dataset.dropdownRequired === "true";
    const isDisabled = this.element.dataset.disabled === "true";
    
    // Armazena referências para uso posterior
    this.hidden = hidden;
    this.label = label;
    this.isRequired = isRequired;
    this.isDisabled = isDisabled;
    
    // Restaura seleção inicial se houver
    const selectedValue = hidden.value;
    const selectedOption = Array.from(this.element.querySelectorAll(".dropdown-option"))
      .find(o => o.dataset.value === selectedValue);
    
    if (selectedOption && label) {
      label.textContent = selectedOption.textContent;
      label.classList.remove("text-gray-400");
      selectedOption.classList.add("!bg-green-500", "text-white");
    }
    
    // Adiciona listeners nas opções
    this.element.querySelectorAll(".dropdown-option").forEach(option => {
      option.addEventListener("click", e => {
        e.preventDefault();
        
        // Verifica se a opção está desabilitada
        if (option.dataset.disabled === 'true') {
          return;
        }
        
        // Verifica se o dropdown inteiro está desabilitado
        if (isDisabled) {
          return;
        }
        
        // Atualiza o valor
        hidden.value = option.dataset.value;
        label.textContent = option.textContent;
        
        // Remove classe de placeholder
        label.classList.remove("text-gray-400");
        
        // Atualiza estilos das opções
        this.element.querySelectorAll(".dropdown-option").forEach(o => {
          o.classList.remove("!bg-green-500", "text-white");
        });
        option.classList.add("!bg-green-500", "text-white");
        
        // Remove erro se existir
        this.removeError();
        
        // Fecha o dropdown
        this.element.removeAttribute("open");
        
        // Dispara evento change no hidden field
        const changeEvent = new Event('change', { bubbles: true });
        hidden.dispatchEvent(changeEvent);
      });
    });
    
    // Fecha dropdown ao clicar fora
    document.addEventListener("click", e => {
      document.querySelectorAll("details.dropdown[open]").forEach(dropdown => {
        if (!dropdown.contains(e.target)) {
          dropdown.removeAttribute("open");
        }
      });
    });
    
    // Validação no blur se for required
    if (isRequired) {
      this.element.addEventListener("blur", () => {
        this.validateRequired();
      }, true);
    }
  }
  
  /**
   * Valida se o campo obrigatório está preenchido
   */
  validateRequired() {
    if (!this.isRequired) return true;
    
    const value = this.hidden?.value;
    
    if (!value || value === '') {
      this.showError();
      return false;
    } else {
      this.removeError();
      return true;
    }
  }
  
  /**
   * Mostra feedback visual de erro
   */
  showError() {
    const summary = this.element.querySelector('summary');
    
    if (summary) {
      summary.classList.add('border-red-500', 'bg-red-50');
      summary.classList.remove('border-gray-300', 'bg-white');
    }
    
    if (this.label) {
      this.label.classList.add('text-gray-400');
    }
  }
  
  /**
   * Remove feedback visual de erro
   */
  removeError() {
    const summary = this.element.querySelector('summary');
    
    if (summary) {
      summary.classList.remove('border-red-500', 'bg-red-50');
      summary.classList.add('border-gray-300');
      
      // Restaura bg-white apenas se não estiver desabilitado
      if (!this.isDisabled) {
        summary.classList.add('bg-white');
      }
    }
  }
  
  /**
   * Reseta o dropdown para o estado inicial
   */
  reset() {
    if (this.hidden) {
      this.hidden.value = '';
    }
    
    if (this.label) {
      const placeholder = this.element.dataset.placeholder || 'Selecione';
      this.label.textContent = placeholder;
      this.label.classList.add('text-gray-400');
    }
    
    // Remove destaque de todas as opções
    this.element.querySelectorAll(".dropdown-option").forEach(o => {
      o.classList.remove("!bg-green-500", "text-white");
    });
    
    this.removeError();
  }
  
  /**
   * Define um valor programaticamente
   */
  setValue(value) {
    const option = Array.from(this.element.querySelectorAll(".dropdown-option"))
      .find(o => o.dataset.value === value);
    
    if (option && !option.dataset.disabled) {
      // Simula clique na opção
      option.click();
    }
  }
  
  /**
   * Obtém o valor atual
   */
  getValue() {
    return this.hidden?.value || '';
  }
  
  /**
   * Desabilita o dropdown
   */
  disable() {
    this.isDisabled = true;
    this.element.dataset.disabled = "true";
    const summary = this.element.querySelector('summary');
    if (summary) {
      summary.classList.add('bg-gray-100', 'cursor-not-allowed', 'text-gray-400');
      summary.classList.remove('bg-white', 'cursor-pointer');
    }
  }
  
  /**
   * Habilita o dropdown
   */
  enable() {
    this.isDisabled = false;
    this.element.dataset.disabled = "false";
    const summary = this.element.querySelector('summary');
    if (summary) {
      summary.classList.remove('bg-gray-100', 'cursor-not-allowed', 'text-gray-400');
      summary.classList.add('bg-white', 'cursor-pointer');
    }
  }
}