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
      document.getElementById('allocate-student-name').textContent = studentName;
      document.getElementById('allocate-modal').showModal();
      return false;
    };

    window.closeAllocateModal = () => {
      document.getElementById('allocate-modal').close();
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
      document.getElementById('remove-student-name').textContent = studentName;
      document.getElementById('remove-modal').showModal();
      return false;
    };

    window.closeRemoveModal = () => {
      document.getElementById('remove-modal').close();
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
      document.getElementById('bulk-allocate-count').textContent = checkedBoxes.length;
      document.getElementById('bulk-allocate-modal').showModal();
      return false;
    };

    window.closeBulkAllocateModal = () => {
      document.getElementById('bulk-allocate-modal').close();
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
      document.getElementById('bulk-remove-count').textContent = checkedBoxes.length;
      document.getElementById('bulk-remove-modal').showModal();
      return false;
    };

    window.closeBulkRemoveModal = () => {
      document.getElementById('bulk-remove-modal').close();
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
        this.updateSelectAllState(selectAllAvailable, studentCheckboxes);
        this.updateSelectAllState(selectAllAvailableMobile, studentCheckboxes);
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
    const searchQuery = document.getElementById(`search-${type}`).value;
    const ageFilter = document.getElementById(`age-filter-${type}`).value;
    const orderFilter = document.getElementById(`order-filter-${type}`).value;
    
    const params = new URLSearchParams(window.location.search);
    const prefix = type === 'allocated' ? 'allocated_' : 'available_';
    
    this.setOrDeleteParam(params, `${prefix}search`, searchQuery);
    this.setOrDeleteParam(params, `${prefix}age_filter`, ageFilter);
    this.setOrDeleteParam(params, `${prefix}order_filter`, orderFilter);
    
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
    return document.querySelector('meta[name="csrf-token"]').content;
  }
}

// Initialize when DOM is ready
function initializeStudentAssignment() {
  new StudentAssignment();
}

document.addEventListener('DOMContentLoaded', initializeStudentAssignment);
document.addEventListener('turbo:load', initializeStudentAssignment);
