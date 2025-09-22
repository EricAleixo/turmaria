# frozen_string_literal: true

class EscolaPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def create?
    user&.is_a?(SuperAdmin)
  end

  def update?
    return false unless user
    return true if user.is_a?(SuperAdmin)
    return user.escolas.include?(record) if user.is_a?(Admin)
    false
  end

  def destroy?
    user&.is_a?(SuperAdmin)
  end

  def view_admin_info?
    user&.is_a?(SuperAdmin)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.all unless user
      return scope.all if user.is_a?(SuperAdmin)
      return user.escolas if user.is_a?(Admin)
      scope.all
    end
  end
end
