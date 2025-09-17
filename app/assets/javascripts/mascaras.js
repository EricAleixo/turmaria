function aplicarMascaras() {
  const cpfInput = document.getElementById('aluno_cpf');
  if (cpfInput) {
    IMask(cpfInput, { mask: '000.000.000-00' });
  }

  const telefoneInputs = [
    document.getElementById('aluno_telefone'),
    document.getElementById('aluno_telefone_responsavel_1'),
    document.getElementById('aluno_telefone_responsavel_2')
  ];

  telefoneInputs.forEach(input => {
    if (input) {
      IMask(input, {
        mask: '(00) 00000-0000'
      });
    }
  });
}

document.addEventListener('turbolinks:load', aplicarMascaras);