// app/javascript/controllers/turma_selector_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
  "turmaInput",
  "turmaCard",
  "cardsContainer",
  "detailsSection",
  "bimestreInput",
  "bimestresContainer",
  "carouselContainer",
  "prevButton",
  "nextButton",
  "disciplinaSelect"
  ]

  connect() {
    // Se já tiver uma turma selecionada (edição), restaurar o estado
    const turmaId = this.turmaInputTarget.value
    if (turmaId) {
      const card = this.turmaCardTargets.find(c => c.dataset.turmaId === turmaId)
      if (card) {
        this.selectTurmaCard(card)
        this.showDetails(card)
      }
    }

    // Restaurar bimestre selecionado se houver
    const bimestreValue = this.bimestreInputTarget.value
    if (bimestreValue) {
      setTimeout(() => {
        const bimestreBtn = this.bimestresContainerTarget.querySelector(
          `[data-bimestre="${bimestreValue}"]`
        )
        if (bimestreBtn) {
          this.selectBimestreCard(bimestreBtn)
        }
      }, 100)
    }

    // Verificar se precisa mostrar botões de navegação do carrossel
    if (this.hasCardsContainerTarget) {
      setTimeout(() => this.updateTurmaButtons(), 100)
      
      // Adicionar listener para resize da janela
      this.resizeObserver = new ResizeObserver(() => {
        this.updateTurmaButtons()
      })
      this.resizeObserver.observe(this.cardsContainerTarget)
    }
  }

  disconnect() {
    // Limpar observer quando o controller for desconectado
    if (this.resizeObserver) {
      this.resizeObserver.disconnect()
    }
  }

  selectTurma(event) {
  const card = event.currentTarget
  const turmaId = card.dataset.turmaId
  const disciplinasIds = JSON.parse(card.dataset.disciplinas || '[]')  // ← ADICIONAR
  
  // Atualizar seleção visual
  this.selectTurmaCard(card)
  
  // Atualizar campo hidden
  this.turmaInputTarget.value = turmaId
  
  // Atualizar disciplinas disponíveis
  this.updateDisciplinas(disciplinasIds)  // ← ADICIONAR
  
  // Mostrar seção de detalhes e gerar bimestres
  this.showDetails(card)
  
  // Scroll suave até a seção de detalhes
  setTimeout(() => {
    this.detailsSectionTarget.scrollIntoView({ 
      behavior: 'smooth', 
      block: 'nearest' 
    })
  }, 150)
}

  // ← ADICIONAR ESTE MÉTODO NOVO
updateDisciplinas(disciplinasIds) {
  if (!this.hasDisciplinaSelectTarget) return
  
  const select = this.disciplinaSelectTarget
  const options = select.querySelectorAll('option')
  
  options.forEach(option => {
    if (option.value === '') return // Manter o prompt habilitado
    
    const disciplinaId = parseInt(option.value)
    
    if (disciplinasIds.includes(disciplinaId)) {
      option.disabled = false
      option.classList.remove('text-gray-400')
    } else {
      option.disabled = true
      option.classList.add('text-gray-400')
      
      // Se estava selecionada, limpar
      if (option.selected) {
        select.value = ''
      }
    }
  })
}

  selectTurmaCard(card) {
    // Remover seleção de todos os cards
    this.turmaCardTargets.forEach(c => {
      c.classList.remove('selected', 'border-teal-500', 'bg-teal-50', 'shadow-md')
      c.classList.add('border-gray-200')
    })
    
    // Adicionar classe de selecionado
    card.classList.add('selected', 'border-teal-500', 'bg-teal-50', 'shadow-md')
    card.classList.remove('border-gray-200')
  }

  showDetails(card) {
    const bimestres = parseInt(card.dataset.bimestres)
    
    // Mostrar seção com animação
    this.detailsSectionTarget.classList.remove('hidden')
    this.detailsSectionTarget.classList.add('animate-fadeIn')
    
    // Gerar cards de bimestre
    this.generateBimestres(bimestres)
  }

  generateBimestres(quantidade) {
    this.bimestresContainerTarget.innerHTML = ''
    
    for (let i = 1; i <= quantidade; i++) {
      const btn = document.createElement('button')
      btn.type = 'button'
      btn.dataset.bimestre = i
      btn.dataset.action = 'click->turma-selector#selectBimestre'
      btn.className = `
        group relative flex items-center justify-center 
        px-6 py-3 bg-white border-2 border-gray-200 
        rounded-xl hover:border-teal-400 hover:shadow-md 
        transition-all duration-200 cursor-pointer
        min-w-[100px]
      `.trim().replace(/\s+/g, ' ')
      
      btn.innerHTML = `
        <div class="absolute top-1 right-1 w-5 h-5 bg-teal-500 rounded-full items-center justify-center hidden group-[.selected]:flex">
          <svg class="w-3 h-3 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M5 13l4 4L19 7" />
          </svg>
        </div>
        <div class="text-center">
          <div class="text-2xl font-bold text-gray-800 group-hover:text-teal-600 transition-colors group-[.selected]:text-teal-600">
            ${i}º
          </div>
          <div class="text-xs text-gray-500 mt-1">Bimestre</div>
        </div>
      `
      
      this.bimestresContainerTarget.appendChild(btn)
    }
  }

  selectBimestre(event) {
    const btn = event.currentTarget
    const bimestre = btn.dataset.bimestre
    
    // Atualizar seleção visual
    this.selectBimestreCard(btn)
    
    // Atualizar campo hidden
    this.bimestreInputTarget.value = bimestre
  }

  selectBimestreCard(btn) {
    // Remover seleção de todos os botões
    const allBtns = this.bimestresContainerTarget.querySelectorAll('button')
    allBtns.forEach(b => {
      b.classList.remove('selected', 'border-teal-500', 'bg-teal-50', 'shadow-md')
      b.classList.add('border-gray-200')
    })
    
    // Adicionar classe de selecionado
    btn.classList.add('selected', 'border-teal-500', 'bg-teal-50', 'shadow-md')
    btn.classList.remove('border-gray-200')
  }

  // ========================================
  // MÉTODOS DO CARROSSEL DE TURMAS
  // ========================================

  scrollTurmasLeft(event) {
    event.preventDefault()
    console.log("⬅️ Scroll para esquerda");
    if (!this.hasCardsContainerTarget) return
    
    const container = this.cardsContainerTarget
    const scrollAmount = 320
    container.scrollBy({ left: -scrollAmount, behavior: 'smooth' })
    
    setTimeout(() => this.updateTurmaButtons(), 300)
  }

  scrollTurmasRight(event) {
    event.preventDefault()
    console.log("➡️ Scroll para direita");
    if (!this.hasCardsContainerTarget) return
    
    const container = this.cardsContainerTarget
    const scrollAmount = 320
    container.scrollBy({ left: scrollAmount, behavior: 'smooth' })
    
    setTimeout(() => this.updateTurmaButtons(), 300)
  }

  updateTurmaButtons() {
    console.log("🔄 Atualizando botões do carrossel");
    if (!this.hasCardsContainerTarget) return
    if (!this.hasPrevButtonTarget) return
    if (!this.hasNextButtonTarget) return
    
    const container = this.cardsContainerTarget
    const prevBtn = this.prevButtonTarget
    const nextBtn = this.nextButtonTarget
    
    const needsScroll = container.scrollWidth > container.clientWidth
    
    if (!needsScroll) {
      prevBtn.classList.add('hidden')
      prevBtn.classList.remove('flex')
      nextBtn.classList.add('hidden')
      nextBtn.classList.remove('flex')
      return
    }
    
    const canScrollLeft = container.scrollLeft > 10
    const canScrollRight = container.scrollLeft < (container.scrollWidth - container.clientWidth - 10)
    
    if (canScrollLeft) {
      prevBtn.classList.remove('hidden')
      prevBtn.classList.add('flex')
    } else {
      prevBtn.classList.add('hidden')
      prevBtn.classList.remove('flex')
    }
    
    if (canScrollRight) {
      nextBtn.classList.remove('hidden')
      nextBtn.classList.add('flex')
    } else {
      nextBtn.classList.add('hidden')
      nextBtn.classList.remove('flex')
    }
  }
}