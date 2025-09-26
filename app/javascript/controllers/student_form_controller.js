import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    this.initializeForm();
    console.log("Controller student-form conectado!");
  }

  initializeForm() {
    const nextStep1Btn = document.getElementById('next-step-1');
    const nextStep2Btn = document.getElementById('next-step-2');
    const prevStep2Btn = document.getElementById('prev-step-2');
    const prevStep3Btn = document.getElementById('prev-step-3');
    const studentForm = document.getElementById('student-form');
    const submitBtn = document.getElementById('submit-btn');
    const errorAlert = document.getElementById('error-alert');
    const errorList = document.getElementById('error-list');
    const step1 = document.getElementById('step-1');
    const step2 = document.getElementById('step-2');
    const step3 = document.getElementById('step-3');

    // --- Funções Auxiliares ---
    const showDaisyAlert = (message, type) => {
      const alertContainer = document.getElementById('alert-container');
      const alertDiv = document.createElement('div');
      alertDiv.classList.add('alert', `alert-${type}`);
      alertDiv.innerHTML = `
        <svg xmlns="http://www.w3.org/2000/svg" class="stroke-current shrink-0 h-6 w-6" fill="none" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
        <span>${message}</span>
      `;
      if (alertContainer) {
        alertContainer.appendChild(alertDiv);
        setTimeout(() => {
          alertDiv.remove();
        }, 5000);
      }
    };

    const showCorrectStep = (errors) => {
      if (!errors) return;
      const stepFields = {
        'step-1': ['nome', 'data_nascimento', 'cpf', 'rg', 'telefone', 'email'],
        'step-2': ['responsavel_1', 'telefone_responsavel_1'],
      };
      let stepToShow = 'step-1';
      for (const field in errors) {
        if (stepFields['step-1'].includes(field)) {
          stepToShow = 'step-1';
          break;
        }
        if (stepFields['step-2'].includes(field)) {
          stepToShow = 'step-2';
          break;
        }
      }
      if (step1) step1.classList.add('hidden');
      if (step2) step2.classList.add('hidden');
      if (step3) step3.classList.add('hidden');
      const targetStep = document.getElementById(stepToShow);
      if (targetStep) targetStep.classList.remove('hidden');
      if (errorList) {
        errorList.innerHTML = '';
        for (const field in errors) {
          errors[field].forEach(message => {
            const li = document.createElement('li');
            li.textContent = `${field.replace('_', ' ').replace(/aluno/g, 'Aluno')}: ${message}`;
            errorList.appendChild(li);
          });
        }
      }
      if (errorAlert) errorAlert.classList.remove('hidden');
    };

    const handleFiles = (files, fileInput) => {
      const filesArray = Array.from(files);
      const fileType = fileInput.id.replace('-upload', '');
      let maxFiles;
      const MAX_FILES_CPF = 2;
      const MAX_FILES_COMPROVANTE = 2;
      const MAX_FILES_HISTORICO = 1;
      const FILE_SIZE_LIMIT_BYTES = 716800; // 700 KB

      if (fileType === 'cpf') maxFiles = MAX_FILES_CPF;
      else if (fileType === 'comprovante') maxFiles = MAX_FILES_COMPROVANTE;
      else if (fileType === 'historico') maxFiles = MAX_FILES_HISTORICO;

      const uploadedFilesList = document.getElementById(fileInput.id.replace('-upload', '-files-list'));
      const currentFilesCount = uploadedFilesList.childElementCount;
      const dataTransfer = new DataTransfer();

      if (currentFilesCount + filesArray.length > maxFiles) {
        showDaisyAlert(`Limite de ${maxFiles} arquivos para este tipo de documento atingido.`, 'warning');
        return;
      }

      const existingFiles = Array.from(fileInput.files);
      existingFiles.forEach(f => dataTransfer.items.add(f));

      filesArray.forEach(file => {
        if (file.size > FILE_SIZE_LIMIT_BYTES) {
          showDaisyAlert(`O arquivo "${file.name}" excede o tamanho máximo de 700 KB.`, 'error');
          return;
        }
        dataTransfer.items.add(file);
        addFileToList(file, uploadedFilesList, fileInput);
      });

      fileInput.files = dataTransfer.files;

      if (filesArray.length > 0) {
        showDaisyAlert(`Arquivo(s) selecionado(s) com sucesso!`, 'success');
      }
    };

    const addFileToList = (file, listElement, fileInput) => {
      const listItem = document.createElement('li');
      listItem.classList.add('flex', 'items-center', 'justify-between', 'p-4', 'border-b', 'last:border-b-0');
      const fileInfo = document.createElement('div');
      fileInfo.classList.add('flex', 'items-center', 'gap-4');
      const fileIcon = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="w-6 h-6 text-gray-500"><path fill-rule="evenodd" d="M19.5 7.5a3 3 0 00-3-3h-8.25a3 3 0 00-3 3v9a3 3 0 003 3h8.25a3 3 0 003-3v-9zM15 11.25a.75.75 0 00-1.5 0v3.75a.75.75 0 001.5 0v-3.75z" clip-rule="evenodd" /></svg>`;
      fileInfo.innerHTML = `
        <div class="flex items-center gap-2">
          ${fileIcon}
          <div>
            <p class="text-sm font-semibold">${file.name}</p>
            <p class="text-xs text-gray-500">${(file.size / 1024).toFixed(2)} KB</p>
          </div>
        </div>
      `;
      const deleteButton = document.createElement('button');
      deleteButton.type = 'button';
      deleteButton.classList.add('text-red-500', 'hover:text-red-700', 'transition', 'p-2', 'rounded-full', 'hover:bg-gray-200');
      deleteButton.innerHTML = `<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6"><path stroke-linecap="round" stroke-linejoin="round" d="m14.74 9-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 0 1-2.244 2.077H8.084a2.25 2.25 0 0 1-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 0 0-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 0 1 3.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 0 0-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 0 0-7.5 0" /></svg>`;
      deleteButton.onclick = () => {
        const dataTransfer = new DataTransfer();
        const files = Array.from(fileInput.files).filter(f => f !== file);
        files.forEach(f => dataTransfer.items.add(f));
        fileInput.files = dataTransfer.files;
        listItem.remove();
        showDaisyAlert('Arquivo removido.', 'info');
      };
      listItem.appendChild(fileInfo);
      listItem.appendChild(deleteButton);
      listElement.appendChild(listItem);
    };

    // --- Lógica do Botão ---
    if (nextStep1Btn) {
      nextStep1Btn.addEventListener('click', (event) => {
        event.preventDefault();
        if (step1) step1.classList.add('hidden');
        if (step2) step2.classList.remove('hidden');
      });
    }

    if (nextStep2Btn) {
      nextStep2Btn.addEventListener('click', (event) => {
        event.preventDefault();
        if (step2) step2.classList.add('hidden');
        if (step3) step3.classList.remove('hidden');
      });
    }

    if (prevStep2Btn) {
      prevStep2Btn.addEventListener('click', (event) => {
        event.preventDefault();
        if (step2) step2.classList.add('hidden');
        if (step1) step1.classList.remove('hidden');
      });
    }

    if (prevStep3Btn) {
      prevStep3Btn.addEventListener('click', (event) => {
        event.preventDefault();
        if (step3) step3.classList.add('hidden');
        if (step2) step2.classList.remove('hidden');
      });
    }

    // --- Fim da Lógica do Botão ---

    // Lógica de submissão do formulário
    if (studentForm) {
      studentForm.addEventListener('submit', async (event) => {
        event.preventDefault();
        if (errorAlert) errorAlert.classList.add('hidden');
        if (submitBtn) {
          submitBtn.disabled = true;
          submitBtn.innerHTML = `<span class="loading loading-spinner"></span> Enviando...`;
        }

        const formData = new FormData(studentForm);
        const csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content');

        try {
          const response = await fetch(studentForm.action, {
            method: studentForm.method,
            body: formData,
            headers: {
              'X-CSRF-Token': csrfToken,
              'X-Requested-With': 'XMLHttpRequest',
              'Accept': 'application/json'
            },
          });
          if (!response.ok) {
            const result = await response.json();
            showCorrectStep(result.errors);
          } else {
            const successMessage = document.getElementById('success-message');
            const successModal = document.getElementById('success-modal');
            if (successMessage) successMessage.textContent = "Aluno salvo com sucesso!";
            if (successModal) successModal.showModal();
            studentForm.reset();
            const step3 = document.getElementById('step-3');
            const step1 = document.getElementById('step-1');
            if (step3) step3.classList.add('hidden');
            if (step1) step1.classList.remove('hidden');
          }
        } catch (error) {
          showDaisyAlert('Ocorreu um erro ao enviar o formulário. Tente novamente.', 'error');
          console.error('Erro:', error);
        } finally {
          if (submitBtn) {
            submitBtn.disabled = false;
            submitBtn.innerHTML = `Criar Aluno`;
          }
        }
      });
    }

    // Lógica para os campos de Necessidades Especiais (PCD)
    const outroCheckbox = document.getElementById('outro-checkbox');
    const outraNecessidadeField = document.getElementById('outra-necessidade-field');
    const checkboxes = document.querySelectorAll('.necessidade-checkbox');
    const nenhumaCheckbox = document.querySelector('input[value="Nenhuma"]');

    const toggleObservacoesField = () => {
      if (outroCheckbox && outraNecessidadeField) {
        outraNecessidadeField.classList.toggle('hidden', !outroCheckbox.checked);
      }
    };

    if (nenhumaCheckbox) {
      nenhumaCheckbox.addEventListener('change', () => {
        if (nenhumaCheckbox.checked) {
          checkboxes.forEach(otherCb => {
            if (otherCb.value !== 'Nenhuma') {
              otherCb.checked = false;
            }
          });
        }
        toggleObservacoesField();
      });
    }

    if (outroCheckbox) {
      outroCheckbox.addEventListener('change', () => {
        if (outroCheckbox.checked && nenhumaCheckbox) {
          nenhumaCheckbox.checked = false;
        }
        toggleObservacoesField();
      });
    }

    checkboxes.forEach(cb => {
      if (cb.value !== 'Nenhuma' && cb.value !== 'Outro(a)') {
        cb.addEventListener('change', () => {
          if (cb.checked && nenhumaCheckbox) {
            nenhumaCheckbox.checked = false;
          }
        });
      }
    });

    toggleObservacoesField();

    // Lógica de upload e notificações
    const uploadAreas = document.querySelectorAll('.upload-area');
    const uploadInputs = document.querySelectorAll('input[type="file"]');
    const FILE_SIZE_LIMIT_BYTES = 716800;
    const MAX_FILES_FOTO = 1;
    const MAX_FILES_CPF = 2;
    const MAX_FILES_COMPROVANTE = 2;
    const MAX_FILES_HISTORICO = 1;

    uploadAreas.forEach(area => {
      const inputId = area.dataset.inputId;
      const fileInput = document.getElementById(inputId);
      if (!fileInput) return;
      area.addEventListener('dragover', (event) => {
        event.preventDefault();
        area.classList.add('border-blue-500');
      });
      area.addEventListener('dragleave', () => {
        area.classList.remove('border-blue-500');
      });
      area.addEventListener('drop', (event) => {
        event.preventDefault();
        area.classList.remove('border-blue-500');
        const files = event.dataTransfer.files;
        handleFiles(files, fileInput);
      });
    });

    uploadInputs.forEach(fileInput => {
      fileInput.addEventListener('change', (event) => {
        const files = event.target.files;
        handleFiles(files, fileInput);
      });
    });
  }
}
