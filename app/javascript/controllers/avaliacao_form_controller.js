import { Controller } from "@hotwired/stimulus"

// Este controlador gerencia a lógica de alternância do campo de recuperação e o filtro dinâmico de avaliações por bimestre.
export default class extends Controller {
  static targets = [
    "isRecuperacaoCheckbox", 
    "bimestreSelect", 
    "recuperacaoField", 
    "avaliacaoOriginalSelect"
  ]
  
  // Valores recebidos do HTML para o Stimulus usar no AJAX
  static values = { 
    url: String, // Rota AJAX (filter_by_bimestre_professor_turma_disciplina_notas_avaliacoes_path)
    currentAvaliacaoId: Number // ID da avaliação original pré-selecionada (apenas no Edit)
  }

  connect() {
    // Garante que o estado inicial do campo de recuperação (visível/oculto) esteja correto.
    this.toggleRecuperacaoField()
    
    // Se a recuperação estiver marcada no carregamento, faz a busca inicial dos dados
    if (this.isRecuperacaoCheckboxTarget.checked) {
      this.fetchAvaliacoes()
    }
  }

  // Ação chamada quando o checkbox 'is_recuperacao' ou o select 'bimestre' muda
  handleFormChange() {
    this.toggleRecuperacaoField()
    
    // Se for recuperação E um bimestre válido estiver selecionado, busque as opções
    if (this.isRecuperacaoCheckboxTarget.checked && this.bimestreSelectTarget.value) {
      this.fetchAvaliacoes()
    } else {
      // Se desmarcar a recuperação ou remover o bimestre, limpa as opções
      this.clearAvaliacaoOriginalOptions()
    }
  }

  toggleRecuperacaoField() {
    const checked = this.isRecuperacaoCheckboxTarget.checked
    
    if (checked) {
      this.recuperacaoFieldTarget.classList.remove('hidden')
      // Adiciona o atributo 'required' se for recuperação
      this.avaliacaoOriginalSelectTarget.required = true 
    } else {
      this.recuperacaoFieldTarget.classList.add('hidden')
      this.avaliacaoOriginalSelectTarget.required = false
      // Limpa o valor para garantir que não seja enviado se o checkbox for desmarcado
      this.avaliacaoOriginalSelectTarget.value = '' 
    }
  }

  fetchAvaliacoes() {
    const bimestre = this.bimestreSelectTarget.value
    const preselectedId = this.currentAvaliacaoIdValue
    
    // Constrói a URL para a busca AJAX
    const url = `${this.urlValue}?bimestre=${bimestre}`
    
    // Desabilita o campo enquanto carrega
    this.avaliacaoOriginalSelectTarget.disabled = true
    
    fetch(url)
      .then(response => {
        if (!response.ok) throw new Error('Falha ao buscar avaliações');
        return response.json();
      })
      .then(data => {
        this.updateAvaliacaoOriginalOptions(data, preselectedId)
      })
      .catch(error => {
        console.error("Erro ao carregar avaliações:", error)
        // Opcional: Mostrar feedback de erro no UI
      })
      .finally(() => {
        this.avaliacaoOriginalSelectTarget.disabled = false
      })
  }

  updateAvaliacaoOriginalOptions(options, preselectedId) {
    const select = this.avaliacaoOriginalSelectTarget
    select.innerHTML = '' // Limpa as opções existentes
    
    // Adiciona a opção de placeholder
    const blankOption = document.createElement('option')
    blankOption.value = ''
    blankOption.textContent = 'Selecione a avaliação a ser substituída'
    select.appendChild(blankOption)

    // Adiciona as novas opções
    options.forEach(option => {
      const el = document.createElement('option')
      el.value = option.id
      el.textContent = option.nome
      // Pre-seleciona a opção se for o ID que já estava salvo no objeto (apenas no Edit)
      if (preselectedId && option.id == preselectedId) {
        el.selected = true
        // Reseta o valor para que não tente pre-selecionar novamente
        this.currentAvaliacaoIdValue = null 
      }
      select.appendChild(el)
    })
  }

  clearAvaliacaoOriginalOptions() {
    this.updateAvaliacaoOriginalOptions([], null)
  }
}