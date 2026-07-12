window.scrollToContact = function (assunto) {
  const section = document.getElementById("contato")
  if (!section) return

  // Scroll suave até a seção
  section.scrollIntoView({ behavior: "smooth", block: "start" })

  // Aguarda o scroll terminar antes de pré-selecionar o assunto
  setTimeout(() => {
    const form = section.querySelector("[data-controller='contact-form']")
    if (!form) return

    // Acessa a instância do Stimulus pelo elemento
    const controller = window.Stimulus?.getControllerForElementAndIdentifier(form, "contact-form")
    if (controller) {
      controller.preselectSubject(assunto)
    }
  }, 600) // tempo suficiente para o scroll suave terminar
}