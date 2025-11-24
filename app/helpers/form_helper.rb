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
    initial_value: nil
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

        pair = collection.find { |label, value| value.to_s == selected_value.to_s }
        pair ? pair.first : placeholder
      end


    content_tag(:div, class: "form-control w-full") do

      label_html =
        if label.present?
          tag.label(label, class: "label label-text text-gray-600 font-semibold", for: hidden_id)
        elsif form
          form.label(method, class: "block text-sm font-medium text-gray-700 mb-2")
        else
          "".html_safe
        end


      hidden_html =
        if form
          form.hidden_field(method, id: hidden_id, value: selected_value)
        else
          tag.input(type: "hidden", id: hidden_id, value: selected_value)
        end

      dropdown_html =
        content_tag(:details, class: "dropdown w-full", data: { controller: "dropdown", "dropdown-hidden-field-id": hidden_id }) do


          summary_tag =
            content_tag(:summary, class: "w-full flex items-center justify-between bg-white border border-gray-300 rounded-md px-3 py-2 cursor-pointer hover:border-black focus:border-black focus:outline-none list-none") do
              content_tag(:span, selected_label, class: "dropdown-label") +
              tag.svg(class: "dropdown-arrow ml-2 h-5 w-5 text-gray-600 transition-transform duration-300", xmlns: "http://www.w3.org/2000/svg", fill: "none", viewBox: "0 0 24 24", stroke: "currentColor") do
                tag.path(stroke_linecap: "round", stroke_linejoin: "round", stroke_width: 2, d: "M19 9l-7 7-7-7")
              end
            end


          ul_tag =
            content_tag(:ul, class: "menu dropdown-content p-2 bg-white border border-gray-300 rounded-md w-full mt-1 absolute z-[9999] max-h-60 overflow-auto shadow-lg") do

              collection.map do |item|

                option_label =
                  if label_field && value_field
                    item.send(label_field)
                  else
                    item.first
                  end

                option_value =
                  if label_field && value_field
                    item.send(value_field)
                  else
                    item.last
                  end

                content_tag(:li) do
                  tag.a(
                    option_label,
                    href: "#",
                    class: "dropdown-option px-3 py-2 rounded cursor-pointer hover:bg-green-100 active:!bg-green-500 active:!text-white",
                    data: { value: option_value }
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
