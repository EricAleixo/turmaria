# app/helpers/modal_helper.rb
module ModalHelper
  # Helper principal para criar botão de deletar com modal
  def delete_button_with_modal(path:, modal_id:, title: "Tem certeza?", message: "Esta ação não pode ser desfeita.", btn_class: "btn btn-sm btn-circle", item_name: nil)
    full_message = item_name ? "#{message} \"#{item_name}\"?" : message
    
    # Retorna apenas o botão - o modal será renderizado no final da view
    content_tag(:label, for: modal_id, class: "#{btn_class} cursor-pointer", title: "Deletar") do
      raw('<svg class="w-4 h-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" d="M14.74 9l-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 01-2.244 2.077H8.084a2.25 2.25 0 01-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 00-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 013.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 00-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 00-7.5 0" />
      </svg>')
    end.tap do
      # Armazena o modal para renderizar depois
      content_for(:modals, render_delete_modal(path: path, modal_id: modal_id, title: title, message: full_message))
    end
  end
  
  # Helper para usar dentro de dropdown (mobile)
  def delete_modal_trigger(modal_id:, text: "Excluir", icon: true)
    content_tag(:label, for: modal_id, class: "cursor-pointer flex") do
      safe_join([
        if icon
          raw('<svg class="w-4 h-4 inline-block" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" d="M14.74 9l-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 01-2.244 2.077H8.084a2.25 2.25 0 01-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 00-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 013.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 00-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 00-7.5 0" />
          </svg>')
        end,
        text
      ])
    end
  end
  
  # Helper para criar apenas o modal (sem o botão)
  def delete_modal(path:, modal_id:, title: "Tem certeza?", message: "Esta ação não pode ser desfeita.", item_name: nil)
    full_message = item_name ? "#{message} \"#{item_name}\"?" : message
    
    # Armazena o modal para renderizar depois
    content_for(:modals, render_delete_modal(path: path, modal_id: modal_id, title: title, message: full_message))
    
    # Retorna o checkbox apenas
    content_tag(:input, nil, type: "checkbox", id: modal_id, class: "modal-toggle")
  end
  
  private
  
  # Renderiza a estrutura do modal
  def render_delete_modal(path:, modal_id:, title:, message:)
    safe_join([
      # Checkbox hidden para controlar o modal
      content_tag(:input, nil, type: "checkbox", id: modal_id, class: "modal-toggle"),
      
      # Modal com backdrop - renderizado no body
      content_tag(:div, class: "modal", style: "position: fixed; top: 0; left: 0; right: 0; bottom: 0; z-index: 9999999999999999999;") do
        safe_join([
          # Backdrop
          content_tag(:label, "", 
            class: "cursor-pointer", 
            for: modal_id,
            style: "position: fixed; top: 0; left: 0; right: 0; bottom: 0; background-color: rgba(0, 0, 0, 0.5); z-index: 9999;"
          ),
          
          # Conteúdo do modal
          content_tag(:div, 
            class: "modal-box",
            style: "position: fixed; top: 50%; left: 50%; transform: translate(-50%, -50%); z-index: 10000; max-width: 32rem; width: 91.666667%;"
          ) do
            safe_join([
              # Botão fechar (X)
              content_tag(:label, "✕", for: modal_id, class: "btn btn-sm btn-circle absolute right-2 top-2 cursor-pointer"),
              
              # Ícone de alerta
              content_tag(:div, class: "flex justify-center mb-4") do
                content_tag(:div, class: "w-16 h-16 bg-red-100 rounded-full flex items-center justify-center") do
                  raw('<svg class="w-10 h-10 text-red-600" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                  </svg>')
                end
              end,
              
              # Título
              content_tag(:h3, title, class: "font-bold text-xl text-center mb-2 text-gray-800"),
              
              # Mensagem
              content_tag(:p, message, class: "text-center text-gray-600 mb-6"),
              
              # Form e botões
              form_with(url: path, method: :delete, class: "modal-action justify-center gap-3") do |f|
                safe_join([
                  # Botão Cancelar
                  content_tag(:label, "Cancelar", for: modal_id, class: "btn btn-outline border-gray-300 hover:bg-gray-100 px-6 cursor-pointer"),
                  
                  # Botão Confirmar
                  f.submit("Excluir", class: "btn bg-gradient-to-r from-red-500 to-pink-500 text-white hover:from-red-600 hover:to-pink-600 border-0 px-6")
                ])
              end
            ])
          end
        ])
      end
    ])
  end
end