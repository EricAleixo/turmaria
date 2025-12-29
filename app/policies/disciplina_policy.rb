class DisciplinaPolicy < ApplicationPolicy
  
  def index?
    user.present?
  end

  def new?
    # Qualquer admin ou super_admin pode TENTAR criar
    user.present? && (user.is_a?(SuperAdmin) || user.is_a?(Admin))
  end

  def show?
    can_manage?
  end

  def create?
    can_manage?
  end

  def update?
    can_manage?
  end

  def destroy?
    can_manage?
  end

  private

  def can_manage?
    return false unless user.present?
    return true if user.is_a?(SuperAdmin)

    if user.is_a?(Admin)
      # Garante que a escola existe antes de verificar
      return false if record.escola.nil?
      
      # Usa escola_ids (mais eficiente que include?)
      return user.escola_ids.include?(record.escola_id)
    end

    false
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.all if user.is_a?(SuperAdmin)
      return scope.where(escola_id: user.escola_ids) if user.is_a?(Admin)
      scope.none
    end
  end
end