# Be sure to restart your server when you modify this file.

# Add new inflection rules using the following format. Inflections
# are locale specific, and you may define rules for as many different
# locales as you wish. All of these examples are active by default:
# ActiveSupport::Inflector.inflections(:en) do |inflect|
#   inflect.plural /^(ox)$/i, "\\1en"
#   inflect.singular /^(ox)en/i, "\\1"
#   inflect.irregular "person", "people"
#   inflect.uncountable %w( fish sheep )
# end

# These inflection rules are supported but not enabled by default:
# ActiveSupport::Inflector.inflections(:en) do |inflect|
#   inflect.acronym "RESTful"
# end

ActiveSupport::Inflector.inflections(:en) do |inflect|
  # ... (outras regras)

  inflect.irregular 'historico_escolar', 'historico_escolares'
  inflect.irregular 'historico_disciplina', 'historico_disciplinas'
  inflect.irregular 'transferencia', 'transferencias'
  inflect.irregular "plano_de_ensino", "planos_de_ensino"
  
  # CORREÇÃO PARA "NOTA"
  inflect.irregular 'nota', 'notas'
end