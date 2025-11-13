# config/importmap.rb

# 🚨 LIMPEZA: Remova todos os pins que não são essenciais do Turbo/Stimulus

# pin "mascaras", to: "mascaras.js"  <-- REMOVER
pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"

pin "trix"
pin "@rails/actiontext", to: "actiontext.esm.js"
