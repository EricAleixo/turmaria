module HistoricosHelper
  def situacao_class(situacao)
    case situacao
    when 'aprovado'        then 'text-success'
    when 'reprovado',
         'reprovado_falta' then 'text-error'
    when 'recuperacao'     then 'text-warning'
    else 'text-gray-500'
    end
  end
end