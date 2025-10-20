// Student Assignment Management
// Handles allocation and removal of students to/from classes

class StudentAssignment {
  constructor() {
    this.currentStudentId = null;
    this.currentStudentName = null;
    this.init();
  }

  init() {
    this.bindModalEvents();
    this.bindCheckboxEvents();
    this.bindFilterEvents();
    this.bindBulkActions();
  }

  // Modal Management
  bindModalEvents() {
    window.openAllocateModal = (studentId, studentName) => {
      this.currentStudentId = studentId;
      this.currentStudentName = studentName;
      const nameElement = document.getElementById('allocate-student-name');
      const modal = document.getElementById('allocate-modal');
      if (nameElement && modal) {
        nameElement.textContent = studentName;
        modal.showModal();
      }
      return false;
    };

    window.closeAllocateModal = () => {
      const modal = document.getElementById('allocate-modal');
      if (modal) modal.close();
      this.currentStudentId = null;
      this.currentStudentName = null;
    };

    window.confirmAllocate = () => {
      if (this.currentStudentId) {
        this.submitForm('assign_student', { aluno_id: this.currentStudentId });
      }
      window.closeAllocateModal();
    };

    window.openRemoveModal = (studentId, studentName) => {
      this.currentStudentId = studentId;
      this.currentStudentName = studentName;
      const nameElement = document.getElementById('remove-student-name');
      const modal = document.getElementById('remove-modal');
      if (nameElement && modal) {
        nameElement.textContent = studentName;
        modal.showModal();
      }
      return false;
    };

    window.closeRemoveModal = () => {
      const modal = document.getElementById('remove-modal');
      if (modal) modal.close();
      this.currentStudentId = null;
      this.currentStudentName = null;
    };

    window.confirmRemove = () => {
      if (this.currentStudentId) {
        this.submitForm('remove_from_turma', { student_id: this.currentStudentId });
      }
      window.closeRemoveModal();
    };

    window.openBulkAllocateModal = () => {
      const checkedBoxes = document.querySelectorAll('.student-checkbox:checked');
      const countElement = document.getElementById('bulk-allocate-count');
      const modal = document.getElementById('bulk-allocate-modal');
      if (countElement && modal) {
        countElement.textContent = checkedBoxes.length;
        modal.showModal();
      }
      return false;
    };

    window.closeBulkAllocateModal = () => {
      const modal = document.getElementById('bulk-allocate-modal');
      if (modal) modal.close();
    };

    window.confirmBulkAllocate = () => {
      const studentIds = this.getSelectedStudentIds('.student-checkbox:checked');
      if (studentIds.length > 0) {
        this.submitBulkForm('assign_students', studentIds);
      }
      window.closeBulkAllocateModal();
    };

    window.openBulkRemoveModal = () => {
      const checkedBoxes = document.querySelectorAll('.allocated-checkbox:checked');
      const countElement = document.getElementById('bulk-remove-count');
      const modal = document.getElementById('bulk-remove-modal');
      if (countElement && modal) {
        countElement.textContent = checkedBoxes.length;
        modal.showModal();
      }
      return false;
    };

    window.closeBulkRemoveModal = () => {
      const modal = document.getElementById('bulk-remove-modal');
      if (modal) modal.close();
    };

    window.confirmBulkRemove = () => {
      const studentIds = this.getSelectedStudentIds('.allocated-checkbox:checked');
      if (studentIds.length > 0) {
        this.submitBulkForm('remove_from_turma', studentIds);
      }
      window.closeBulkRemoveModal();
    };
  }

  // Checkbox Management
  bindCheckboxEvents() {
    // Available students checkboxes (Desktop)
    const selectAllAvailable = document.getElementById('select-all-available');
    const studentCheckboxes = document.querySelectorAll('.student-checkbox');

    selectAllAvailable?.addEventListener('change', (e) => {
      studentCheckboxes.forEach(checkbox => {
        checkbox.checked = e.target.checked;
      });
      this.updateAvailableCount();
    });

    // Available students checkboxes (Mobile)
    const selectAllAvailableMobile = document.getElementById('select-all-available-mobile');
    selectAllAvailableMobile?.addEventListener('change', (e) => {
      studentCheckboxes.forEach(checkbox => {
        checkbox.checked = e.target.checked;
      });
      this.updateAvailableCount();
    });

    studentCheckboxes.forEach(checkbox => {
      checkbox.addEventListener('change', () => {
        if (selectAllAvailable) {
          this.updateSelectAllState(selectAllAvailable, studentCheckboxes);
        }
        if (selectAllAvailableMobile) {
          this.updateSelectAllState(selectAllAvailableMobile, studentCheckboxes);
        }
        this.updateAvailableCount();
      });
    });

    // Allocated students checkboxes (Desktop)
    const selectAllAllocated = document.getElementById('select-all-allocated');
    const allocatedCheckboxes = document.querySelectorAll('.allocated-checkbox');

    selectAllAllocated?.addEventListener('change', (e) => {
      allocatedCheckboxes.forEach(checkbox => {
        checkbox.checked = e.target.checked;
      });
      this.updateAllocatedCount();
    });

    // Allocated students checkboxes (Mobile)
    const selectAllAllocatedMobile = document.getElementById('select-all-allocated-mobile');
    selectAllAllocatedMobile?.addEventListener('change', (e) => {
      allocatedCheckboxes.forEach(checkbox => {
        checkbox.checked = e.target.checked;
      });
      this.updateAllocatedCount();
    });

    allocatedCheckboxes.forEach(checkbox => {
      checkbox.addEventListener('change', () => {
        if (selectAllAllocated) {
          this.updateSelectAllState(selectAllAllocated, allocatedCheckboxes);
        }
        if (selectAllAllocatedMobile) {
          this.updateSelectAllState(selectAllAllocatedMobile, allocatedCheckboxes);
        }
        this.updateAllocatedCount();
      });
    });
  }

  // Filter Management
  bindFilterEvents() {
    const applyFiltersAllocated = document.getElementById('apply-filters-allocated');
    const applyFiltersAvailable = document.getElementById('apply-filters-available');

    applyFiltersAllocated?.addEventListener('click', () => this.applyFilters('allocated'));
    applyFiltersAvailable?.addEventListener('click', () => this.applyFilters('available'));
  }

  // Bulk Actions
  bindBulkActions() {
    const bulkAssignBtn = document.getElementById('bulk-assign-btn');
    const bulkRemoveBtn = document.getElementById('bulk-remove-btn');

    bulkAssignBtn?.addEventListener('click', (e) => {
      e.preventDefault();
      const studentIds = this.getSelectedStudentIds('.student-checkbox:checked');
      if (studentIds.length > 0) {
        window.openBulkAllocateModal();
      }
    });

    bulkRemoveBtn?.addEventListener('click', (e) => {
      e.preventDefault();
      const studentIds = this.getSelectedStudentIds('.allocated-checkbox:checked');
      if (studentIds.length > 0) {
        window.openBulkRemoveModal();
      }
    });
  }

  // Helper Methods
  updateSelectAllState(selectAllCheckbox, checkboxes) {
    if (!selectAllCheckbox) return;
    
    const checkedBoxes = Array.from(checkboxes).filter(cb => cb.checked);
    
    if (checkedBoxes.length === 0) {
      selectAllCheckbox.indeterminate = false;
      selectAllCheckbox.checked = false;
    } else if (checkedBoxes.length === checkboxes.length) {
      selectAllCheckbox.indeterminate = false;
      selectAllCheckbox.checked = true;
    } else {
      selectAllCheckbox.indeterminate = true;
      selectAllCheckbox.checked = false;
    }
  }

  updateAvailableCount() {
    const count = document.querySelectorAll('.student-checkbox:checked').length;
    const selectedCountSpan = document.getElementById('selected-count');
    const selectedCountSpanMobile = document.getElementById('selected-count-mobile');
    const bulkAssignSection = document.getElementById('bulk-assign-section');
    const bulkAssignSectionMobile = document.getElementById('bulk-assign-section-mobile');
    
    if (selectedCountSpan) selectedCountSpan.textContent = count;
    if (selectedCountSpanMobile) selectedCountSpanMobile.textContent = count;
    this.toggleSection(bulkAssignSection, count > 0);
    this.toggleSection(bulkAssignSectionMobile, count > 0);
  }

  updateAllocatedCount() {
    const count = document.querySelectorAll('.allocated-checkbox:checked').length;
    const allocatedCountSpan = document.getElementById('allocated-count');
    const allocatedCountSpanMobile = document.getElementById('allocated-count-mobile');
    const bulkRemoveSection = document.getElementById('bulk-remove-section');
    const bulkRemoveSectionMobile = document.getElementById('bulk-remove-section-mobile');
    const bulkRemoveBtn = document.getElementById('bulk-remove-btn');
    const bulkRemoveBtnMobile = document.getElementById('bulk-remove-btn-mobile');
    
    if (allocatedCountSpan) allocatedCountSpan.textContent = count;
    if (allocatedCountSpanMobile) allocatedCountSpanMobile.textContent = count;
    this.toggleSection(bulkRemoveSection, count > 0);
    this.toggleSection(bulkRemoveSectionMobile, count > 0);
    
    if (bulkRemoveBtn) {
      bulkRemoveBtn.style.display = count > 0 ? 'flex' : 'none';
    }
    if (bulkRemoveBtnMobile) {
      bulkRemoveBtnMobile.style.display = count > 0 ? 'flex' : 'none';
    }
  }

  toggleSection(section, show) {
    if (!section) return;
    
    if (show) {
      section.classList.remove('hidden');
      setTimeout(() => {
        section.classList.remove('opacity-0', 'scale-95');
        section.classList.add('opacity-100', 'scale-100');
      }, 10);
    } else {
      section.classList.remove('opacity-100', 'scale-100');
      section.classList.add('opacity-0', 'scale-95');
      setTimeout(() => {
        section.classList.add('hidden');
      }, 300);
    }
  }

  getSelectedStudentIds(selector) {
    const checkedBoxes = document.querySelectorAll(selector);
    return Array.from(checkedBoxes).map(cb => cb.dataset.studentId);
  }

  applyFilters(type) {
    const searchInput = document.getElementById(`search-${type}`);
    const ageFilter = document.getElementById(`age-filter-${type}`);
    const orderFilter = document.getElementById(`order-filter-${type}`);
    
    if (!searchInput || !ageFilter || !orderFilter) return;
    
    const searchQuery = searchInput.value;
    const ageFilterValue = ageFilter.value;
    const orderFilterValue = orderFilter.value;
    
    const params = new URLSearchParams(window.location.search);
    const prefix = type === 'allocated' ? 'allocated_' : 'available_';
    
    this.setOrDeleteParam(params, `${prefix}search`, searchQuery);
    this.setOrDeleteParam(params, `${prefix}age_filter`, ageFilterValue);
    this.setOrDeleteParam(params, `${prefix}order_filter`, orderFilterValue);
    
    document.body.style.cursor = 'wait';
    window.location.search = params.toString();
  }

  setOrDeleteParam(params, key, value) {
    if (value) {
      params.set(key, value);
    } else {
      params.delete(key);
    }
  }

  submitForm(action, data) {
    const form = document.createElement('form');
    form.method = 'POST';
    form.action = this.getActionUrl(action);
    
    this.addFormField(form, '_method', 'PATCH');
    this.addFormField(form, 'authenticity_token', this.getCsrfToken());
    
    Object.entries(data).forEach(([key, value]) => {
      this.addFormField(form, key, value);
    });
    
    document.body.appendChild(form);
    form.submit();
  }

  submitBulkForm(action, studentIds) {
    const form = document.createElement('form');
    form.method = 'POST';
    form.action = this.getActionUrl(action);
    
    this.addFormField(form, '_method', 'PATCH');
    this.addFormField(form, 'authenticity_token', this.getCsrfToken());
    
    studentIds.forEach(id => {
      this.addFormField(form, 'student_ids[]', id);
    });
    
    document.body.appendChild(form);
    form.submit();
  }

  addFormField(form, name, value) {
    const input = document.createElement('input');
    input.type = 'hidden';
    input.name = name;
    input.value = value;
    form.appendChild(input);
  }

  getActionUrl(action) {
    const escolaId = document.querySelector('[data-escola-id]')?.dataset.escolaId;
    const turmaId = document.querySelector('[data-turma-id]')?.dataset.turmaId;
    return `/escolas/${escolaId}/turmas/${turmaId}/${action}`;
  }

  getCsrfToken() {
    const token = document.querySelector('meta[name="csrf-token"]');
    return token ? token.content : '';
  }
}

// Initialize when DOM is ready
function initializeStudentAssignment() {
  // Previne múltiplas inicializações
  if (window.studentAssignmentInstance) {
    return;
  }
  
  // Verifica se estamos na página correta
  const pageContainer = document.querySelector('[data-escola-id][data-turma-id]');
  if (!pageContainer) {
    return;
  }
  
  window.studentAssignmentInstance = new StudentAssignment();
}

// Limpa a instância antes do Turbo renderizar nova página
document.addEventListener('turbo:before-render', () => {
  window.studentAssignmentInstance = null;
});

// Inicializa em todas as situações possíveis
document.addEventListener('turbo:load', initializeStudentAssignment);
document.addEventListener('turbo:render', initializeStudentAssignment);
document.addEventListener('DOMContentLoaded', initializeStudentAssignment);

// Executa imediatamente se o DOM já estiver pronto
if (document.readyState !== 'loading') {
  initializeStudentAssignment();
}