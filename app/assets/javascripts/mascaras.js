// assets/javascript/mascaras.js

// 🚨 REMOÇÃO TOTAL DE IMPORTS: IMask é acessado globalmente
// Nenhuma linha de 'import' é necessária ou permitida aqui.

function aplicarMascaras() {
    // 🚨 VERIFICAÇÃO FINAL: Deve retornar true se o include_tag funcionou
    if (typeof IMask !== 'function') {
        // Se este erro ainda ocorrer, o problema é que o arquivo IMask.js NÃO FOI ENCONTRADO/CARREGADO.
        console.error("ERRO CRÍTICO: IMask não foi carregado. Copie o arquivo IMask.js para vendor/assets/javascripts.");
        return; 
    }

    // Máscara de CPF (mantida)
    const cpfInput = document.getElementById('aluno_cpf');
    if (cpfInput) {
        IMask(cpfInput, { mask: '000.000.000-00' });
    }

    // Máscaras de Telefone
    const telefoneInputs = [
        document.getElementById('aluno_telefone'),
        document.getElementById('aluno_telefone_responsavel_1'),
        document.getElementById('aluno_telefone_responsavel_2'),
        document.getElementById('professor_telefone') 
    ].filter(input => input); 
    // Removi a duplicidade de 'aluno_telefone' no array.

    telefoneInputs.forEach(input => {
        if (input && !input.dataset.imaskApplied) { 
            IMask(input, {
                mask: '(00) 00000-0000'
            });
            input.dataset.imaskApplied = true; 
        }
    });
}

// O evento turbolinks:load (ou turbo:load no Rails 7) é crucial
// Mantenha os eventos para garantir que funcione após a navegação Turbo
document.addEventListener('turbolinks:load', aplicarMascaras);
document.addEventListener('turbo:load', aplicarMascaras);