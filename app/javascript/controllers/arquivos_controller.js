import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "input", "dropzone", "preview", "prevBtn", "nextBtn",
    "counter", "counterText", "carouselWrapper"
  ]
  static values = {
    deleteUrl: String,     // base URL para DELETE (ex: /uploads)
    maxFiles: Number       // opcional limite de arquivos simultâneos
  }

  // constantes (padroniza tipos e tamanho máximo)
  static VALID_TYPES = [
    "application/pdf",
    "application/msword",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    "image/jpeg",
    "image/png",
    "image/gif"
  ]
  static MAX_SIZE_MB = 10

  connect() {
    // estado
    this.files = [] // arquivos novos (File objects)
    this.scrollAmount = 0
    this._debounceTimer = null

    // UI inicial
    if (this.hasPrevBtnTarget) this.prevBtnTarget.classList.add("hidden")
    if (this.hasNextBtnTarget) this.nextBtnTarget.classList.add("hidden")
    if (this.hasCarouselWrapperTarget) this.carouselWrapperTarget.classList.add("hidden")

    // cria elemento de toast container (acessível)
    this.ensureToastContainer()
    this.updateScrollAmount()
    this.updateCounter()
  }

  /* -------------------- Eventos públicos -------------------- */

  openFileDialog(e) {
    e?.preventDefault()
    if (this.hasInputTarget) this.inputTarget.click()
  }

  handleFileSelect({ target: { files }}) {
    if (!files) return
    this.addFiles([...files])
  }

  handleDrop(e) {
    e.preventDefault()
    if (!e.dataTransfer) return
    this.addFiles([...e.dataTransfer.files])
    this.unhighlightDropzone()
  }

  highlightDropzone(e) {
    e?.preventDefault()
    if (this.hasDropzoneTarget) this.dropzoneTarget.classList.add("border-teal-400", "bg-teal-50")
  }

  unhighlightDropzone(e) {
    e?.preventDefault?.()
    if (this.hasDropzoneTarget) this.dropzoneTarget.classList.remove("border-teal-400", "bg-teal-50")
  }

  /* -------------------- Gerenciamento de arquivos (UI) -------------------- */

  addFiles(incomingFiles = []) {
    if (!incomingFiles.length) return

    // validações UX (client-side apenas para ajudar o usuário)
    const valid = incomingFiles.filter(f =>
      this.constructor.VALID_TYPES.includes(f.type) &&
      (f.size <= this.constructor.MAX_SIZE_MB * 1024 * 1024)
    )

    const invalidCount = incomingFiles.length - valid.length
    if (invalidCount > 0) {
      this.showToast(`Alguns arquivos inválidos/maiores que ${this.constructor.MAX_SIZE_MB}MB foram ignorados`, "error")
    }
    if (!valid.length) {
      return
    }

    // limite de quantidade (opcional)
    const max = this.hasMaxFilesValue ? this.maxFilesValue : Infinity
    if ((this.files.length + valid.length) > max) {
      this.showToast(`Limite de ${max} arquivos atingido`, "error")
      return
    }

    // adiciona e renderiza de forma eficiente usando DocumentFragment
    this.files.push(...valid)
    this.renderPreview()
    this.updateCounter()
    this.showToast(`${valid.length} arquivo${valid.length > 1 ? "s" : ""} adicionad${valid.length > 1 ? "os" : "o"}`, "success")
  }

  // Remove arquivo: se tiver fileId => chama DELETE; se for local => remove da lista
  async removeFile(event) {
    event.preventDefault()
    const btn = event.currentTarget
    const index = parseInt(btn.dataset.index, 10)
    const fileId = btn.dataset.fileId || null

    // visual: spinner + disabled
    this.setButtonLoading(btn, true)

    if (fileId && this.hasDeleteUrlValue) {
      try {
        await this.deleteFileRequest(fileId)
        // remove o container da DOM com animação suave
        const container = btn.closest(".relative.flex-shrink-0")
        if (container) {
          container.classList.add("opacity-0", "scale-95")
          setTimeout(() => container.remove(), 180)
        }
        // atualizar contador e botões do carrossel
        this.updateCounter()
        this.debounce(() => this.updateCarouselButtons())
        this.showToast("Arquivo removido", "success")
      } catch (err) {
        console.error("Delete error:", err)
        this.showToast("Não foi possível remover o arquivo (servidor).", "error")
        this.setButtonLoading(btn, false)
      }
    } else {
      // arquivo local (ainda não enviado)
      if (Number.isInteger(index) && index >= 0 && index < this.files.length) {
        // revoke objectURL se existir na exibição
        const file = this.files[index]
        // não há referência direta ao blob URL aqui, mas o img.src será revogado no remove do elemento
        this.files.splice(index, 1)
        this.renderPreview()
        this.updateCounter()
        this.showToast("Arquivo removido", "success")
      } else {
        this.setButtonLoading(btn, false)
        this.showToast("Arquivo não encontrado", "error")
      }
    }
  }

  /* -------------------- Renderização (melhor organizada) -------------------- */

  renderPreview() {
    if (!this.hasPreviewTarget) return

    // limpa de forma eficiente
    while (this.previewTarget.firstChild) this.previewTarget.removeChild(this.previewTarget.firstChild)

    // se só haver arquivos vindos do servidor (representados por elements com data-file-id),
    // mantemos a lógica compatível: se não houver novos arquivos e nenhum preview existente => oculta carousel
    const totalPreviewCount = this.files.length
    if (totalPreviewCount === 0) {
      if (this.hasCarouselWrapperTarget) this.carouselWrapperTarget.classList.add("hidden")
      return
    }

    if (this.hasCarouselWrapperTarget) this.carouselWrapperTarget.classList.remove("hidden")

    const frag = document.createDocumentFragment()
    this.files.forEach((file, index) => {
      const container = document.createElement("div")
      container.className = "relative flex-shrink-0 w-64 group transition-all duration-300"

      // botão remover (acessível)
      const removeBtn = this.createRemoveButton(index)
      container.appendChild(removeBtn)

      // Conteúdo: image ou documento
      if (file.type?.startsWith("image/")) {
        container.appendChild(this.createImagePreview(file))
      } else {
        container.appendChild(this.createDocumentPreview(file))
      }

      frag.appendChild(container)
    })

    this.previewTarget.appendChild(frag)
    this.updateScrollAmount()
    this.debounce(() => this.updateCarouselButtons())
  }

  // Cria botão remover (padronizado)
  createRemoveButton(index, fileId = null) {
    

    const btn = document.createElement("button")
    btn.type = "button"
    btn.className = "absolute top-3 right-3 bg-red-500 text-white rounded-full w-8 h-8 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-all duration-200 shadow-lg hover:bg-red-600 hover:scale-110 z-10"
    btn.setAttribute("aria-label", "Excluir arquivo")
    btn.dataset.index = index
    if (fileId) btn.dataset.fileId = fileId
    btn.dataset.action = "click->arquivos#removeFile"

    // ícone (X)
    const svgNS = "http://www.w3.org/2000/svg"
    const svg = document.createElementNS(svgNS, "svg")
    svg.setAttribute("class", "w-4 h-4")
    svg.setAttribute("fill", "none")
    svg.setAttribute("viewBox", "0 0 24 24")
    svg.setAttribute("stroke", "currentColor")
    svg.setAttribute("stroke-width", "2.5")
    const path = document.createElementNS(svgNS, "path")
    path.setAttribute("stroke-linecap", "round")
    path.setAttribute("stroke-linejoin", "round")
    path.setAttribute("d", "M6 18L18 6M6 6l12 12")
    svg.appendChild(path)
    btn.appendChild(svg)

    return btn
  }

  // Preview para imagens
  createImagePreview(file) {
    const wrapper = document.createElement("div")
    wrapper.className = "relative w-full h-56 bg-gray-100 overflow-hidden rounded-xl cursor-pointer group-hover:shadow-lg transition-shadow duration-300"

    const img = document.createElement("img")
    // segurança: apenas atribuímos object URL local; se houver file.url do servidor, só use se for propriedade confiável
    img.src = file.url && this.isSafeUrl(file.url) ? file.url : URL.createObjectURL(file)
    img.alt = file.name || file.filename || "Imagem"
    img.className = "w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
    img.loading = "lazy"

    // guardar referência para revogar ao remover
    img.dataset._createdByArquivos = "true"
    wrapper.appendChild(img)

    // revogar objectURL quando imagem removida
    return wrapper
  }

  // Preview para docs (PDF/DOC)
createDocumentPreview(file) {
  const wrapper = document.createElement("div")
  wrapper.className = "relative flex flex-col items-center justify-center h-56 bg-gray border border-gray-200 rounded-xl p-4 cursor-pointer hover:shadow-lg transition-shadow duration-300"

  const iconContainer = document.createElement("div")
  iconContainer.className = "flex items-center justify-center w-16 h-16 mb-4 relative"

  // --- define cor do ícone de acordo com o tipo ---
  const fileName = file.name || file.filename || ""
  const fileType = file.type || ""
  let iconColor = "text-blue-500" // cor padrão = azul (DOC)
  if (fileType === "application/pdf" || fileName.toLowerCase().endsWith(".pdf")) {
    iconColor = "text-red-500"
  }

  // ícone
  const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg")
  svg.setAttribute("class", `w-16 h-16 ${iconColor}`)
  svg.setAttribute("viewBox", "0 0 20 20")
  svg.setAttribute("fill", "currentColor")
  const path = document.createElementNS("http://www.w3.org/2000/svg", "path")
  path.setAttribute("d", "M4 4a2 2 0 012-2h4.586A2 2 0 0112 2.586L15.414 6A2 2 0 0116 7.414V16a2 2 0 01-2 2H6a2 2 0 01-2-2V4z")
  svg.appendChild(path)
  iconContainer.appendChild(svg)

  // label (PDF/DOC)
  const label = document.createElement("span")
  let labelText = "DOC"
  if (fileType === "application/pdf" || fileName.toLowerCase().endsWith(".pdf")) labelText = "PDF"
  label.className = "absolute inset-0 flex items-center justify-center text-white font-bold text-xs pointer-events-none"
  label.textContent = labelText
  iconContainer.appendChild(label)

  wrapper.appendChild(iconContainer)

  const name = document.createElement("p")
  name.className = "text-sm font-semibold text-gray-800 text-center line-clamp-2 px-2"
  name.textContent = fileName
  wrapper.appendChild(name)

  const sizeEl = document.createElement("span")
  sizeEl.className = "text-xs text-gray-600 mt-1"
  sizeEl.textContent = this.formatFileSize(file.size || file.byte_size || 0)
  wrapper.appendChild(sizeEl)

  return wrapper
}


  /* -------------------- Helpers e utilitários -------------------- */

  formatFileSize(bytes) {
    if (!bytes || bytes < 1024) return `${bytes || 0} B`
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`
  }

  // Debounce simples
  debounce(fn, delay = 150) {
    clearTimeout(this._debounceTimer)
    this._debounceTimer = setTimeout(() => fn(), delay)
  }

  setButtonLoading(btn, isLoading) {
    if (!btn) return
    if (isLoading) {
      btn.disabled = true
      btn.classList.add("opacity-50", "cursor-not-allowed")
      // opcional: spinner interno (substitui conteúdo)
      btn.dataset._orig = btn.innerHTML
      btn.innerHTML = `<svg class="animate-spin w-4 h-4" viewBox="0 0 24 24"><circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="3" fill="none" /></svg>`
    } else {
      btn.disabled = false
      btn.classList.remove("opacity-50", "cursor-not-allowed")
      if (btn.dataset._orig) {
        btn.innerHTML = btn.dataset._orig
        delete btn.dataset._orig
      }
    }
  }

  // DELETE request seguro com CSRF e same-origin
  async deleteFileRequest(fileId) {
    if (!this.hasDeleteUrlValue) throw new Error("deleteUrl não configurado")
    const token = this.getCsrfToken()
    if (!token) throw new Error("CSRF token ausente")

    const resp = await fetch(`${this.deleteUrlValue}/${encodeURIComponent(fileId)}`, {
      method: "DELETE",
      headers: {
        "X-CSRF-Token": token,
        "Accept": "application/json"
      },
      credentials: "same-origin"
    })

    if (!resp.ok) {
      // tenta ler mensagem amigável do server, mas sem expor detalhes
      let errMsg = "Erro ao deletar"
      try {
        const payload = await resp.json()
        if (payload?.error) errMsg = payload.error
      } catch (_) {}
      throw new Error(errMsg)
    }

    return true
  }

  getCsrfToken() {
    const token = document.querySelector('meta[name="csrf-token"]')?.content
    if (!token) console.warn("⚠️ CSRF token ausente no <head>")
    return token || ""
  }

  // simples heurística para URLs seguras (server should provide safe URLs)
  isSafeUrl(url) {
    try {
      const u = new URL(url, window.location.origin)
      // permite apenas http(s) e mesmas-origin ou assets confiáveis
      return (u.protocol === "https:" || u.protocol === "http:") && u.origin === window.location.origin
    } catch (e) {
      return false
    }
  }

  // atualiza contador visível
  updateCounter() {
    if (!this.hasCounterTarget) return
    const serverCount = this.previewTarget?.querySelectorAll("[data-file-id]")?.length || 0
    const total = this.files.length + serverCount
    if (total > 0) {
      if (this.hasCounterTextTarget) this.counterTextTarget.textContent = `${total} arquivo${total > 1 ? "s" : ""}`
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

  scrollRight(e) {
    e?.preventDefault()
    const maxScroll = this.previewTarget.scrollWidth - this.previewTarget.clientWidth
    let next = this.previewTarget.scrollLeft + this.scrollAmount
    if (next > maxScroll) next = maxScroll
    this.previewTarget.scrollTo({ left: next, behavior: "smooth" })
    this.debounce(() => this.updateCarouselButtons())
  }

  scrollLeft(e) {
    e?.preventDefault()
    let next = this.previewTarget.scrollLeft - this.scrollAmount
    if (next < 0) next = 0
    this.previewTarget.scrollTo({ left: next, behavior: "smooth" })
    this.debounce(() => this.updateCarouselButtons())
  }

  updateCarouselButtons() {
    if (!this.hasPrevBtnTarget || !this.hasNextBtnTarget || !this.hasPreviewTarget) return
    const { scrollLeft, scrollWidth, clientWidth } = this.previewTarget
    this.prevBtnTarget.classList.toggle("hidden", scrollLeft <= 5)
    this.nextBtnTarget.classList.toggle("hidden", scrollLeft + clientWidth >= scrollWidth - 5)
  }

  /* -------------------- Toaster (A11y) -------------------- */

  ensureToastContainer() {
    if (this._toastContainer) return
    const container = document.createElement("div")
    container.setAttribute("aria-live", "polite")
    container.setAttribute("aria-atomic", "true")
    container.className = "fixed bottom-4 right-4 z-50 flex flex-col gap-2"
    document.body.appendChild(container)
    this._toastContainer = container
  }

  showToast(message, type = "info", duration = 3500) {
    this.ensureToastContainer()
    const toast = document.createElement("div")
    toast.className = `px-4 py-2 rounded-lg text-white text-sm shadow-lg max-w-xs break-words ${type === "error" ? "bg-red-500" : "bg-emerald-500"}`
    toast.textContent = message
    this._toastContainer.appendChild(toast)
    setTimeout(() => {
      toast.classList.add("opacity-0", "scale-95")
      setTimeout(() => toast.remove(), 220)
    }, duration)
  }

  /* -------------------- Cleanup -------------------- */

  disconnect() {
    // revoke blobs criadas dinamicamente (revoga todas img com data flag)
    this.previewTarget?.querySelectorAll("img").forEach(img => {
      try {
        if (img.src && img.src.startsWith("blob:")) URL.revokeObjectURL(img.src)
      } catch (e) { /* ignore */ }
    })
    this.files = []
  }
}
