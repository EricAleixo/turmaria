import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  carregarCidades(event) {
    const estadoId = event.currentTarget.dataset.id

    fetch(`/estados/${estadoId}/cidades`)
      .then(response => response.text())
      .then(html => {
        document.getElementById("cidades").innerHTML = html
      })
  }
}