require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module SistemaAcademico
  class Application < Rails::Application
    config.load_defaults 7.1

    # UUID como padrão
    config.active_record.primary_key = :uuid

    # 🚨 ESSENCIAL PARA MIGRATIONS (ActiveStorage, Devise, etc)
    config.generators do |g|
      g.orm :active_record, primary_key_type: :uuid
    end

    # devise em portugues pt-BR
    config.i18n.default_locale = :"pt-BR"

    # Autoload
    config.autoload_lib(ignore: %w(assets tasks))
    config.autoload_paths += %W(#{config.root}/app/policies)

    config.autoload_paths << Rails.root.join('app', 'services')
    config.eager_load_paths << Rails.root.join('app', 'services')
  end
end
