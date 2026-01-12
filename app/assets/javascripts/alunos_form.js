// ============================================
// CORRIGIDO: Upload de Foto com Crop
// ============================================

let cropper = null;
let currentDocumentType = null;
let tempDocumentFiles = [];

// Funções para Modal de Foto
function openFotoModal() {
  document.getElementById('foto-modal').showModal();
}

function closeFotoModal() {
  if (cropper) {
    cropper.destroy();
    cropper = null;
  }
  document.getElementById('foto-upload-area').classList.remove('hidden');
  document.getElementById('foto-crop-area').classList.add('hidden');
  document.getElementById('foto-modal').close();
}

function resetFotoModal() {
  if (cropper) {
    cropper.destroy();
    cropper = null;
  }
  document.getElementById('foto-upload-area').classList.remove('hidden');
  document.getElementById('foto-crop-area').classList.add('hidden');
  document.getElementById('foto-upload').value = '';
  document.getElementById('foto-files-list').innerHTML = '';
}

// CORRIGIDO: Event listener do input de foto
document.getElementById('foto-upload').addEventListener('change', function(e) {
  const file = e.target.files[0];
  
  if (!file) return;
  
  console.log('📸 Arquivo selecionado:', file.name, file.size, 'bytes');
  
  if (!file.type.startsWith('image/')) {
    showToast('Por favor, selecione apenas arquivos de imagem', 'error');
    this.value = '';
    return;
  }
  
  if (file.size > 5 * 1024 * 1024) {
    showToast('A imagem deve ter no máximo 5MB', 'error');
    this.value = '';
    return;
  }
  
  const reader = new FileReader();
  reader.onload = function(event) {
    const img = document.getElementById('foto-preview');
    img.src = event.target.result;
    
    document.getElementById('foto-upload-area').classList.add('hidden');
    document.getElementById('foto-crop-area').classList.remove('hidden');
    
    if (cropper) {
      cropper.destroy();
    }
    
    img.onload = function() {
      cropper = new Cropper(img, {
        aspectRatio: 1,
        viewMode: 2,
        autoCropArea: 0.65,
        responsive: true,
        guides: false,
        center: true,
        highlight: true,
        cropBoxMovable: true,
        cropBoxResizable: true,
        toggleDragModeOnDblclick: false,
        dragMode: 'move',
        background: true,
        modal: true,
        minCropBoxWidth: 200,
        minCropBoxHeight: 200,
        ready: function() {
          const cropBox = document.querySelector('.cropper-crop-box');
          const face = document.querySelector('.cropper-face');
          if (cropBox && face) {
            cropBox.style.borderRadius = '50%';
            face.style.borderRadius = '50%';
          }
        },
        crop: function() {
          const face = document.querySelector('.cropper-face');
          if (face) {
            face.style.borderRadius = '50%';
          }
        }
      });
    };
  };
  reader.readAsDataURL(file);
});

// CORRIGIDO: Confirmação do crop
function confirmFotoCrop() {
  if (!cropper) {
    console.error('❌ Cropper não inicializado');
    return;
  }
  
  console.log('🔍 Iniciando crop da foto...');
  
  const canvas = cropper.getCroppedCanvas({
    width: 400,
    height: 400,
    imageSmoothingEnabled: true,
    imageSmoothingQuality: 'high',
  });
  
  if (!canvas) {
    console.error('❌ Erro ao gerar canvas');
    showToast('Erro ao processar imagem', 'error');
    return;
  }
  
  // Criar canvas circular
  const circularCanvas = document.createElement('canvas');
  const ctx = circularCanvas.getContext('2d');
  circularCanvas.width = 400;
  circularCanvas.height = 400;
  
  ctx.beginPath();
  ctx.arc(200, 200, 200, 0, Math.PI * 2);
  ctx.closePath();
  ctx.clip();
  ctx.drawImage(canvas, 0, 0, 400, 400);
  
  circularCanvas.toBlob(function(blob) {
    if (!blob) {
      console.error('❌ Erro ao criar blob');
      showToast('Erro ao processar imagem', 'error');
      return;
    }
    
    console.log('📸 Blob criado:', blob.size, 'bytes');
    
    // CORRIGIDO: Criar arquivo com nome único e timestamp
    const timestamp = Date.now();
    const file = new File([blob], `foto_aluno_${timestamp}.png`, { 
      type: 'image/png',
      lastModified: timestamp
    });
    
    console.log('📄 Arquivo criado:', file.name, file.size, 'bytes');
    
    // CORRIGIDO: Usar DataTransfer para garantir compatibilidade
    const dataTransfer = new DataTransfer();
    dataTransfer.items.add(file);
    
    const fotoInput = document.getElementById('foto-upload');
    fotoInput.files = dataTransfer.files;
    
    console.log('✅ Arquivo anexado ao input');
    console.log('📋 Files no input:', fotoInput.files.length);
    console.log('📋 Primeiro arquivo:', fotoInput.files[0]?.name);
    
    // Atualizar lista visual
    updateFileList('foto-files-list', [file]);
    
    // Fechar modal
    closeFotoModal();
    
    showToast('Foto recortada e anexada com sucesso!', 'success');
  }, 'image/png', 0.95);
}

// CORRIGIDO: Atualizar lista de arquivos visualmente
function updateFileList(listId, files) {
  const list = document.getElementById(listId);
  if (!list) {
    console.error('❌ Lista não encontrada:', listId);
    return;
  }
  
  list.innerHTML = '';
  
  if (files.length === 0) return;
  
  files.forEach((file, index) => {
    const fileItem = document.createElement('div');
    fileItem.className = 'flex items-center justify-between p-3 border-b last:border-b-0';
    
    const fileInfo = document.createElement('div');
    fileInfo.className = 'flex items-center gap-3';
    
    const icon = document.createElement('svg');
    icon.setAttribute('xmlns', 'http://www.w3.org/2000/svg');
    icon.setAttribute('fill', 'none');
    icon.setAttribute('viewBox', '0 0 24 24');
    icon.setAttribute('stroke-width', '1.5');
    icon.setAttribute('stroke', 'currentColor');
    icon.className = 'w-5 h-5 text-success';
    icon.innerHTML = '<path stroke-linecap="round" stroke-linejoin="round" d="m4.5 12.75 6 6 9-13.5" />';
    
    const fileName = document.createElement('span');
    fileName.className = 'text-sm';
    fileName.textContent = file.name;
    
    const fileSize = document.createElement('span');
    fileSize.className = 'text-xs text-gray-500 ml-2';
    fileSize.textContent = `(${formatFileSize(file.size)})`;
    
    fileInfo.appendChild(icon);
    fileInfo.appendChild(fileName);
    fileInfo.appendChild(fileSize);
    fileItem.appendChild(fileInfo);
    list.appendChild(fileItem);
  });
}

// Função auxiliar para formatar tamanho
function formatFileSize(bytes) {
  if (bytes === 0) return '0 Bytes';
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i];
}

// Função para mostrar toast
function showToast(message, type = 'info') {
  const container = document.getElementById('alert-container');
  if (!container) return;
  
  const alert = document.createElement('div');
  alert.className = `alert alert-${type} shadow-lg mb-2`;
  
  const iconMap = {
    success: '<path stroke-linecap="round" stroke-linejoin="round" d="m4.5 12.75 6 6 9-13.5" />',
    error: '<path stroke-linecap="round" stroke-linejoin="round" d="M6 18 18 6M6 6l12 12" />',
    info: '<path stroke-linecap="round" stroke-linejoin="round" d="m11.25 11.25.041-.02a.75.75 0 0 1 1.063.852l-.708 2.836a.75.75 0 0 0 1.063.853l.041-.021M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Zm-9-3.75h.008v.008H12V8.25Z" />'
  };
  
  alert.innerHTML = `
    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-6 h-6">
      ${iconMap[type] || iconMap.info}
    </svg>
    <span>${message}</span>
  `;
  
  container.appendChild(alert);
  
  setTimeout(() => {
    alert.style.transition = 'opacity 0.3s';
    alert.style.opacity = '0';
    setTimeout(() => alert.remove(), 300);
  }, 3000);
}

// CORRIGIDO: Drag and Drop para foto
const fotoUploadArea = document.getElementById('foto-upload-area');
const fotoInput = document.getElementById('foto-upload');

if (fotoUploadArea && fotoInput) {
  ['dragenter', 'dragover', 'dragleave', 'drop'].forEach(eventName => {
    fotoUploadArea.addEventListener(eventName, (e) => {
      e.preventDefault();
      e.stopPropagation();
    }, false);
  });

  ['dragenter', 'dragover'].forEach(eventName => {
    fotoUploadArea.addEventListener(eventName, () => {
      fotoUploadArea.classList.add('border-primary', 'bg-primary', 'bg-opacity-5');
    }, false);
  });

  ['dragleave', 'drop'].forEach(eventName => {
    fotoUploadArea.addEventListener(eventName, () => {
      fotoUploadArea.classList.remove('border-primary', 'bg-primary', 'bg-opacity-5');
    }, false);
  });

  fotoUploadArea.addEventListener('drop', (e) => {
    const files = e.dataTransfer.files;
    
    if (files.length > 1) {
      showToast('Selecione apenas 1 arquivo de foto', 'error');
      return;
    }
    
    if (files.length > 0) {
      if (!files[0].type.startsWith('image/')) {
        showToast('Por favor, selecione apenas arquivos de imagem', 'error');
        return;
      }
      
      fotoInput.files = files;
      fotoInput.dispatchEvent(new Event('change'));
    }
  }, false);
}

// CORRIGIDO: Debug no submit do formulário
const studentForm = document.getElementById('student-form');
if (studentForm) {
  studentForm.addEventListener('submit', function(e) {
    const fotoInput = document.getElementById('foto-upload');
    console.log('=== 🚀 DEBUG FORM SUBMIT ===');
    console.log('📸 Foto input:', fotoInput);
    console.log('📸 Foto files:', fotoInput?.files);
    console.log('📸 Quantidade:', fotoInput?.files?.length || 0);
    
    if (fotoInput?.files?.length > 0) {
      console.log('📸 Arquivo:', fotoInput.files[0]);
      console.log('📸 Nome:', fotoInput.files[0].name);
      console.log('📸 Tamanho:', fotoInput.files[0].size, 'bytes');
      console.log('📸 Tipo:', fotoInput.files[0].type);
    } else {
      console.log('⚠️ Nenhum arquivo de foto anexado');
    }
    console.log('========================');
  });
}