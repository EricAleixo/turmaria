// Professor Assignment Management
// Handles allocation and removal of professors to/from classes
class ProfessorAssignment {
  constructor() {
    this.currentProfessorId = null;
    this.currentProfessorName = null;
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
    window.openAllocateModal = (professorId, professorName) => {
      this.currentProfessorId = professorId;
      this.currentProfessorName = professorName;
      const nameElement = document.getElementById('allocate-professor-name');
      const modal = document.getElementById('allocate-modal');
      if (nameElement && modal) {
        nameElement.textContent = professorName;
        modal.showModal();
      }
      return false;
    };

    window.closeAllocateModal = () => {
      const modal = document.getElementById('allocate-modal');
      if (modal) modal.close();
      this.currentProfessorId = null;
      this.currentProfessorName = null;
    };

    window.confirmAllocate = () => {
      if (this.currentProfessorId) {
        this.submitForm('assign_professor', { professor_id: this.currentProfessorId });
      }
      window.closeAllocateModal();
    };

    window.openRemoveModal = (professorId, professorName) => {
      this.currentProfessorId = professorId;
      this.currentProfessorName = professorName;
      const nameElement = document.getElementById('remove-professor-name');
      const modal = document.getElementById('remove-modal');
      if (nameElement && modal) {
        nameElement.textContent = professorName;
        modal.showModal();
      }
      return false;
    };

    window.closeRemoveModal = () => {
      const modal = document.getElementById('remove-modal');
      if (modal) modal.close();
      this.currentProfessorId = null;
      this.currentProfessorName = null;
    };

    window.confirmRemove = () => {
      if (this.currentProfessorId) {
        this.submitForm('remove_professor_from_turma', { professor_id: this.currentProfessorId });
      }
      window.closeRemoveModal();
    };

    window.openBulkAllocateModal = () => {
      const checkedBoxes = document.querySelectorAll('.professor-checkbox:checked');
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
      const professorIds = this.getSelectedProfessorIds('.professor-checkbox:checked');
      if (professorIds.length > 0) {
        this.submitBulkForm('assign_professor', professorIds);
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
      const professorIds = this.getSelectedProfessorIds('.allocated-checkbox:checked');
      if (professorIds.length > 0) {
        this.submitBulkForm('remove_professor_from_turma', professorIds);
      }
      window.closeBulkRemoveModal();
    };
  }

  // Checkbox Management
  bindCheckboxEvents() {
    // Available professors checkboxes (Desktop)
    const selectAllAvailable = document.getElementById('select-all-available');
    const professorCheckboxes = document.querySelectorAll('.professor-checkbox');

    selectAllAvailable?.addEventListener('change', (e) => {
      professorCheckboxes.forEach(checkbox => {
        checkbox.checked = e.target.checked;
      });
      // Sincroniza o checkbox mobile
      const selectAllAvailableMobile = document.getElementById('select-all-available-mobile');
      if (selectAllAvailableMobile) {
        selectAllAvailableMobile.checked = e.target.checked;
        selectAllAvailableMobile.indeterminate = false;
      }
      this.updateAvailableCount();
    });

    // Available professors checkboxes (Mobile)
    const selectAllAvailableMobile = document.getElementById('select-all-available-mobile');
    selectAllAvailableMobile?.addEventListener('change', (e) => {
      professorCheckboxes.forEach(checkbox => {
        checkbox.checked = e.target.checked;
      });
      // Sincroniza o checkbox desktop
      if (selectAllAvailable) {
        selectAllAvailable.checked = e.target.checked;
        selectAllAvailable.indeterminate = false;
      }
      this.updateAvailableCount();
    });

    professorCheckboxes.forEach(checkbox => {
      checkbox.addEventListener('change', () => {
        this.updateSelectAllState(selectAllAvailable, professorCheckboxes);
        this.updateSelectAllState(selectAllAvailableMobile, professorCheckboxes);
        this.updateAvailableCount();
      });
    });

    // Allocated professors checkboxes (Desktop)
    const selectAllAllocated = document.getElementById('select-all-allocated');
    const allocatedCheckboxes = document.querySelectorAll('.allocated-checkbox');

    selectAllAllocated?.addEventListener('change', (e) => {
      allocatedCheckboxes.forEach(checkbox => {
        checkbox.checked = e.target.checked;
      });
      // Sincroniza o checkbox mobile
      const selectAllAllocatedMobile = document.getElementById('select-all-allocated-mobile');
      if (selectAllAllocatedMobile) {
        selectAllAllocatedMobile.checked = e.target.checked;
        selectAllAllocatedMobile.indeterminate = false;
      }
      this.updateAllocatedCount();
    });

    // Allocated professors checkboxes (Mobile)
    const selectAllAllocatedMobile = document.getElementById('select-all-allocated-mobile');
    selectAllAllocatedMobile?.addEventListener('change', (e) => {
      allocatedCheckboxes.forEach(checkbox => {
        checkbox.checked = e.target.checked;
      });
      // Sincroniza o checkbox desktop
      if (selectAllAllocated) {
        selectAllAllocated.checked = e.target.checked;
        selectAllAllocated.indeterminate = false;
      }
      this.updateAllocatedCount();
    });

    allocatedCheckboxes.forEach(checkbox => {
      checkbox.addEventListener('change', () => {
        this.updateSelectAllState(selectAllAllocated, allocatedCheckboxes);
        this.updateSelectAllState(selectAllAllocatedMobile, allocatedCheckboxes);
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
      const professorIds = this.getSelectedProfessorIds('.professor-checkbox:checked');
      if (professorIds.length > 0) {
        window.openBulkAllocateModal();
      }
    });

    bulkRemoveBtn?.addEventListener('click', (e) => {
      e.preventDefault();
      const professorIds = this.getSelectedProfessorIds('.allocated-checkbox:checked');
      if (professorIds.length > 0) {
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
    const count = document.querySelectorAll('.professor-checkbox:checked').length;
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

  getSelectedProfessorIds(selector) {
    const checkedBoxes = document.querySelectorAll(selector);
    return Array.from(checkedBoxes).map(cb => cb.dataset.professorId);
  }

  applyFilters(type) {
    const searchInput = document.getElementById(`search-${type}`);
    const typeFilter = document.getElementById(`type-filter-${type}`);
    const orderFilter = document.getElementById(`order-filter-${type}`);

    if (!searchInput || !typeFilter || !orderFilter) return;

    const searchQuery = searchInput.value;
    const typeFilterValue = typeFilter.value;
    const orderFilterValue = orderFilter.value;

    const params = new URLSearchParams(window.location.search);
    const prefix = type === 'allocated' ? 'allocated_' : 'available_';

    this.setOrDeleteParam(params, `${prefix}search`, searchQuery);
    this.setOrDeleteParam(params, `${prefix}type_filter`, typeFilterValue);
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

  submitBulkForm(action, professorIds) {
    const form = document.createElement('form');
    form.method = 'POST';
    form.action = this.getActionUrl(action);

    this.addFormField(form, '_method', 'PATCH');
    this.addFormField(form, 'authenticity_token', this.getCsrfToken());

    professorIds.forEach(id => {
      this.addFormField(form, 'professor_ids[]', id);
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
function initializeProfessorAssignment() {
  // Previne múltiplas inicializações
  if (window.professorAssignmentInstance) {
    return;
  }

  // Verifica se estamos na página correta
  const pageContainer = document.querySelector('[data-escola-id][data-turma-id]');
  if (!pageContainer) {
    return;
  }

  window.professorAssignmentInstance = new ProfessorAssignment();
}

// Limpa a instância antes do Turbo renderizar nova página
document.addEventListener('turbo:before-render', () => {
  window.professorAssignmentInstance = null;
});

// Inicializa em todas as situações possíveis
document.addEventListener('turbo:load', initializeProfessorAssignment);
document.addEventListener('turbo:render', initializeProfessorAssignment);
document.addEventListener('DOMContentLoaded', initializeProfessorAssignment);

// Executa imediatamente se o DOM já estiver pronto
if (document.readyState !== 'loading') {
  initializeProfessorAssignment();
}