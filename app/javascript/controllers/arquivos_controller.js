import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "dropzone", "preview", "prevBtn", "nextBtn", "counter", "counterText", "carouselWrapper"]
  static values = {
    deleteUrl: String // URL base para deletar arquivos
  }

  connect() {
    this.files = []
    this.scrollAmount = 0
    this.updateScrollAmount()
    
    if (this.hasPrevBtnTarget) this.prevBtnTarget.classList.add("hidden")
    if (this.hasNextBtnTarget) this.nextBtnTarget.classList.add("hidden")
    if (this.hasCarouselWrapperTarget) this.carouselWrapperTarget.classList.add("hidden")
  }

  openFileDialog(event) {
    event.preventDefault()
    if (this.hasInputTarget) this.inputTarget.click()
  }

  handleFileSelect(event) {
    this.addFiles(Array.from(event.target.files))
  }

  handleDrop(event) {
    event.preventDefault()
    this.addFiles(Array.from(event.dataTransfer.files))
    this.unhighlightDropzone()
  }

  highlightDropzone(event) {
    event.preventDefault()
    if (this.hasDropzoneTarget) this.dropzoneTarget.classList.add("border-teal-400", "bg-teal-50")
  }

  unhighlightDropzone(event) {
    if (event) event.preventDefault()
    if (this.hasDropzoneTarget) this.dropzoneTarget.classList.remove("border-teal-400", "bg-teal-50")
  }

  addFiles(files) {
    const validTypes = [
      "application/pdf",
      "application/msword",
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
      "image/jpeg",
      "image/png",
      "image/gif"
    ]

    const validFiles = files.filter(f => validTypes.includes(f.type) && f.size <= 10 * 1024 * 1024)
    if (validFiles.length === 0) {
      alert("Nenhum arquivo válido. Máx 10MB. Tipos: PDF, DOC, DOCX ou imagens.")
      return
    }

    this.files.push(...validFiles)
    this.renderPreview()
    this.updateCounter()
  }

  async removeFile(event) {
    const button = event.currentTarget
    const index = parseInt(button.dataset.index)
    const fileId = button.dataset.fileId // ID do arquivo no banco
    
    // Se o arquivo tem ID (está no banco), deletar do servidor
    if (fileId) {
      button.disabled = true
      button.classList.add("opacity-50", "cursor-not-allowed")
      
      try {
        const response = await fetch(`${this.deleteUrlValue}/${fileId}`, {
          method: "DELETE",
          headers: {
            "X-CSRF-Token": this.getCsrfToken(),
            "Accept": "application/json"
          }
        })

        if (!response.ok) {
          throw new Error("Erro ao deletar arquivo")
        }

        // Remove o elemento da DOM após sucesso
        button.closest(".relative.flex-shrink-0").remove()
        this.updateCounter()
        this.updateCarouselButtons()
        
      } catch (error) {
        console.error("Erro:", error)
        alert("Não foi possível deletar o arquivo. Tente novamente.")
        button.disabled = false
        button.classList.remove("opacity-50", "cursor-not-allowed")
      }
    } 
    // Se não tem ID, é um arquivo novo (não enviado ainda)
    else {
      this.files.splice(index, 1)
      this.renderPreview()
      this.updateCounter()
    }
  }

  getCsrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content || ""
  }

  renderPreview() {
    if (!this.hasPreviewTarget) return
    this.previewTarget.innerHTML = ""

    if (this.files.length === 0) {
      if (this.hasCarouselWrapperTarget) this.carouselWrapperTarget.classList.add("hidden")
      return
    }

    if (this.hasCarouselWrapperTarget) this.carouselWrapperTarget.classList.remove("hidden")

    this.files.forEach((file, index) => {
      const container = document.createElement("div")
      container.className = "relative flex-shrink-0 w-64 group transition-all duration-300"

      // Botão remover
      const removeBtn = document.createElement("button")
      removeBtn.type = "button"
      removeBtn.className = "absolute top-3 right-3 bg-red-500 text-white rounded-full w-8 h-8 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-all duration-200 shadow-lg hover:bg-red-600 hover:scale-110 z-10"
      removeBtn.innerHTML = `<svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5"><path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" /></svg>`
      removeBtn.dataset.index = index
      
      // Se o arquivo tem ID (veio do banco), adicionar ao dataset
      if (file.id) {
        removeBtn.dataset.fileId = file.id
      }
      
      removeBtn.dataset.action = "click->arquivos#removeFile"
      container.appendChild(removeBtn)

      // Preview de imagem
      if (file.type?.startsWith("image/") || file.url?.match(/\.(jpg|jpeg|png|gif)$/i)) {
        const imgWrapper = document.createElement("div")
        imgWrapper.className = "relative w-full h-56 bg-gray-100 overflow-hidden rounded-xl cursor-pointer group-hover:shadow-lg transition-shadow duration-300"

        const img = document.createElement("img")
        // Se tem URL (do banco) usa ela, senão cria blob URL
        img.src = file.url || URL.createObjectURL(file)
        img.alt = file.name || file.filename
        img.className = "w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
        imgWrapper.appendChild(img)

        container.appendChild(imgWrapper)
      } 
      // Preview de documentos
      else {
        const docWrapper = document.createElement("div")
        docWrapper.className = "relative flex flex-col items-center justify-center h-56 bg-gray-50 border border-gray-200 rounded-xl p-4 cursor-pointer hover:shadow-lg transition-shadow duration-300"

        const iconContainer = document.createElement("div")
        iconContainer.className = "flex items-center justify-center w-16 h-16 mb-4 relative"
        
        let iconColor = "text-gray-400", label = "DOC"
        const fileName = file.name || file.filename || ""
        const fileType = file.type || file.content_type || ""
        
        if (fileType === "application/pdf" || fileName.endsWith(".pdf")) { 
          iconColor = "text-red-500"; label = "PDF" 
        }
        else if (fileType.includes("word") || fileName.endsWith(".docx") || fileName.endsWith(".doc")) { 
          iconColor = "text-blue-600"; label = "DOC" 
        }

        iconContainer.innerHTML = `
          <svg class="w-16 h-16 ${iconColor}" fill="currentColor" viewBox="0 0 20 20">
            <path d="M4 4a2 2 0 012-2h4.586A2 2 0 0112 2.586L15.414 6A2 2 0 0116 7.414V16a2 2 0 01-2 2H6a2 2 0 01-2-2V4z"/>
          </svg>
          <span class="absolute inset-0 flex items-center justify-center text-white font-bold text-xs">${label}</span>
        `
        docWrapper.appendChild(iconContainer)

        const name = document.createElement("p")
        name.className = "text-sm font-semibold text-gray-800 text-center line-clamp-2 px-2"
        name.textContent = fileName
        docWrapper.appendChild(name)

        const size = document.createElement("span")
        size.className = "text-xs text-gray-600 mt-1"
        size.textContent = this.formatFileSize(file.size || file.byte_size || 0)
        docWrapper.appendChild(size)

        container.appendChild(docWrapper)
      }

      this.previewTarget.appendChild(container)
    })

    this.updateScrollAmount()
    this.updateCarouselButtons()
  }

  formatFileSize(bytes) {
    if (bytes < 1024) return bytes + " B"
    if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + " KB"
    return (bytes / (1024 * 1024)).toFixed(1) + " MB"
  }

  updateCounter() {
    if (!this.hasCounterTarget) return
    
    // Conta tanto arquivos novos quanto existentes
    const totalFiles = this.files.length + 
      (this.previewTarget?.querySelectorAll("[data-file-id]").length || 0)
    
    if (totalFiles > 0) {
      if (this.hasCounterTextTarget) {
        this.counterTextTarget.textContent = `${totalFiles} arquivo${totalFiles > 1 ? "s" : ""}`
      }
      this.counterTarget.classList.remove("hidden")
    } else {
      this.counterTarget.classList.add("hidden")
    }
  }

  updateScrollAmount() {
    if (!this.hasPreviewTarget) return
    const card = this.previewTarget.querySelector("div")
    const gap = 16
    this.scrollAmount = card ? card.offsetWidth + gap : 280
  }

  scrollRight(event) {
    event.preventDefault()
    const maxScroll = this.previewTarget.scrollWidth - this.previewTarget.clientWidth
    let nextScroll = this.previewTarget.scrollLeft + this.scrollAmount
    if (nextScroll > maxScroll) nextScroll = maxScroll
    this.previewTarget.scrollTo({ left: nextScroll, behavior: "smooth" })
    setTimeout(() => this.updateCarouselButtons(), 350)
  }

  scrollLeft(event) {
    event.preventDefault()
    let nextScroll = this.previewTarget.scrollLeft - this.scrollAmount
    if (nextScroll < 0) nextScroll = 0
    this.previewTarget.scrollTo({ left: nextScroll, behavior: "smooth" })
    setTimeout(() => this.updateCarouselButtons(), 350)
  }

  updateCarouselButtons() {
    if (!this.hasPrevBtnTarget || !this.hasNextBtnTarget || !this.hasPreviewTarget) return
    const { scrollLeft, scrollWidth, clientWidth } = this.previewTarget
    this.prevBtnTarget.classList.toggle("hidden", scrollLeft <= 5)
    this.nextBtnTarget.classList.toggle("hidden", scrollLeft + clientWidth >= scrollWidth - 5)
  }

  disconnect() {
    this.previewTarget?.querySelectorAll("img").forEach(img => {
      if (img.src.startsWith("blob:")) URL.revokeObjectURL(img.src)
    })
    this.files = []
  }
}