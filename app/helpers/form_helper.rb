module FormHelper
  def dropdown(
    form: nil,
    method: nil,
    select_id: nil,
    collection:,
    label_field: nil,
    value_field: nil,
    placeholder: "Selecione",
    label: nil,
    hidden_field_id: nil,
    initial_value: nil,
    disabled: false,
    required: false,
    html_options: {}
  )

    hidden_id =
      hidden_field_id ||
      select_id ||
      (form ? "#{form.object_name}_#{method}" : nil)

    raise "Você precisa fornecer form+method ou select_id" if hidden_id.nil?

    selected_value =
      if form
        form.object.send(method)
      else
        initial_value
      end

    selected_label =
      if label_field && value_field
        obj = collection.find { |item| item.send(value_field).to_s == selected_value.to_s }
        obj ? obj.send(label_field) : placeholder
      else
        pair = collection.find { |label, value, *_| value.to_s == selected_value.to_s }
        pair ? pair.first : placeholder
      end

    content_tag(:div, class: "form-control w-full") do

      # ---------- LABEL ----------
      label_html =
        if label.present?
          label_class = "label label-text text-gray-600 font-semibold"
          label_text = required ? "#{label}" : label
          tag.label(label_text, class: label_class, for: hidden_id)
        elsif form
          form.label(method, class: "block text-sm font-medium text-gray-700 mb-2")
        else
          "".html_safe
        end

      # ---------- HIDDEN FIELD ----------
      # Mescla html_options com atributos padrão
      hidden_attrs = {
        id: hidden_id,
        value: selected_value,
        disabled: disabled
      }
      
      # Adiciona required ao hidden field se necessário
      hidden_attrs[:required] = true if required
      hidden_attrs[:data] ||= {}
      hidden_attrs[:data][:required] = true if required
      
      # Mescla com html_options fornecido
      hidden_attrs = hidden_attrs.merge(html_options)

      hidden_html =
        if form
          form.hidden_field(method, hidden_attrs)
        else
          tag.input({ type: "hidden" }.merge(hidden_attrs))
        end

      # ---------- DROPDOWN ----------
      dropdown_html =
        content_tag(
          :details,
          class: "dropdown w-full #{'pointer-events-none opacity-60' if disabled}",
          data: {
            controller: "dropdown",
            "dropdown-hidden-field-id": hidden_id,
            "dropdown-required": required,
            disabled: disabled
          }
        ) do

          # ---------- SUMMARY ----------
          summary_classes = [
            "w-full flex items-center justify-between rounded-md px-3 py-2 list-none",
            disabled ?
              "bg-gray-100 border border-gray-300 cursor-not-allowed text-gray-400" :
              "bg-white border border-gray-300 cursor-pointer hover:border-black focus:border-black focus:outline-none"
          ]
          
          # Adiciona classe de campo obrigatório vazio
          if required && (selected_value.nil? || selected_value.to_s.empty?)
            summary_classes << "border-red-300"
          end
          
          summary_tag =
            content_tag(
              :summary,
              class: summary_classes.join(" "),
              aria: { 
                disabled: disabled,
                required: required
              }
            ) do
              label_span_class = (required && (selected_value.nil? || selected_value.to_s.empty?)) ? 
                "dropdown-label text-gray-400" : 
                "dropdown-label"
              
              content_tag(:span, selected_label, class: label_span_class) +
              tag.svg(
                class: [
                  "dropdown-arrow ml-2 h-5 w-5 transition-transform duration-300",
                  disabled ? "text-gray-400" : "text-gray-600"
                ].join(" "),
                xmlns: "http://www.w3.org/2000/svg",
                fill: "none",
                viewBox: "0 0 24 24",
                stroke: "currentColor"
              ) do
                tag.path(
                  stroke_linecap: "round",
                  stroke_linejoin: "round",
                  stroke_width: 2,
                  d: "M19 9l-7 7-7-7"
                )
              end
            end

          # ---------- OPTIONS ----------
          ul_tag =
            content_tag(
              :ul,
              class: "menu dropdown-content p-2 bg-white border border-gray-300 rounded-md w-full mt-1 absolute z-[9999] max-h-60 overflow-auto shadow-lg"
            ) do
              collection.map do |item|

                # Detecta se é um array com options hash
                option_disabled = false
                
                if label_field && value_field
                  option_label = item.send(label_field)
                  option_value = item.send(value_field)
                else
                  option_label = item.first
                  option_value = item[1]
                  # Verifica se há um terceiro elemento (hash de opções)
                  if item.is_a?(Array) && item.length > 2 && item[2].is_a?(Hash)
                    option_disabled = item[2][:disabled] == true
                  end
                end

                content_tag(:li) do
                  tag.a(
                    option_label,
                    href: (disabled || option_disabled) ? nil : "#",
                    class: [
                      "dropdown-option px-3 py-2 rounded",
                      (disabled || option_disabled) ?
                        "text-gray-400 cursor-not-allowed opacity-50" :
                        "cursor-pointer hover:bg-green-100 active:!bg-green-500 active:!text-white"
                    ].join(" "),
                    data: (disabled || option_disabled) ? { disabled: true } : { value: option_value }
                  )
                end

              end.join.html_safe
            end

          summary_tag + ul_tag
        end

      label_html + hidden_html + dropdown_html
    end
  end
end