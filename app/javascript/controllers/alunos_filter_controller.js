import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // Define os targets que correspondem ao HTML do modal
  static targets = [ "estado", "cidade" ] 

  connect() {
    console.log("Alunos Filter Controller conectado.");
  }

  // Método chamado pelo evento 'change' no select do Estado
  fetchCidades() {
    const estadoId = this.estadoTarget.value; 
    const cidadeSelect = this.cidadeTarget;

    cidadeSelect.innerHTML = '<option value="">Carregando cidades...</option>';
    cidadeSelect.disabled = true;

    if (estadoId) {
      // URL de requisição: /alunos/cidades_por_estado?estado_id=ID_SELECIONADO
      const url = `/alunos/cidades_por_estado?estado_id=${estadoId}`;

      fetch(url, { headers: { 'Accept': 'application/json' } })
      .then(response => {
        if (!response.ok) {
          // Trata erros de rede ou servidor (404, 500)
          throw new Error(`Erro de rede ou servidor. Status: ${response.status}`);
        }
        return response.json();
      })
      .then(data => {
        let optionsHtml = '<option value="">Selecione a Cidade</option>';
        data.forEach(cidade => {
          optionsHtml += `<option value="${cidade.id}">${cidade.nome}</option>`;
        });

        cidadeSelect.innerHTML = optionsHtml;
        cidadeSelect.disabled = false;
      })
      .catch(error => {
        console.error('Erro na requisição AJAX para cidades:', error);
        cidadeSelect.innerHTML = '<option value="">Erro ao carregar cidades</option>';
        cidadeSelect.disabled = false; // Permite ao usuário tentar novamente
      });
    } else {
      cidadeSelect.innerHTML = '<option value="">Selecione primeiro o Estado</option>';
      cidadeSelect.disabled = true;
    }
  }
  
  // 🎯 NOVO MÉTODO: Fecha o modal após a submissão do filtro
  // Chamado pelo evento 'turbo:submit-end' no formulário
  closeModal() {
    // Fecha o modal desmarcando o checkbox invisível que o controla (ID do DaisyUI)
    const modalCheckbox = document.getElementById('filtro_modal');
    if (modalCheckbox) {
      modalCheckbox.checked = false;
    }
  }
}