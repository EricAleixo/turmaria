source "https://rubygems.org"

ruby "3.2.3"

# Para paginação (Recomendado Kaminari)
gem 'kaminari'

# Framework principal
gem "rails", "~> 7.1.3"

# Banco de dados
gem "pg", ">= 1.5"

# Servidor web
gem "puma", ">= 5.0"

# Asset pipeline e CSS
gem "sprockets-rails"
gem "cssbundling-rails"
gem "tailwindcss-rails", "~> 4.3"

# Front-end moderno com Hotwire
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"

# Autenticação e autorização
gem "devise", "~> 4.9"
gem "pundit", "~> 2.3"

# Uploads e imagens
gem "aws-sdk-s3", "~> 1.114"
gem "image_processing", "~> 1.2"

# Outros utilitários
gem "jbuilder"
gem "rails-ujs", "~> 0.1.0"
gem "dotenv-rails"
gem "rack-cors"
gem "bootsnap", require: false

group :development, :test do
  gem "debug", platforms: %i[mri windows]
end

group :development do
  gem "web-console"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
end

group :production do
  gem "rails_12factor"
end

# Necessário apenas no Windows
gem "tzinfo-data", platforms: %i[windows jruby]
