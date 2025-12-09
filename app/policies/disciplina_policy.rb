class DisciplinaPolicy < ApplicationPolicy

  # QUALQUER usuário autenticado pode ver a lista filtrada
  def index?
    user.present?
  end

  # SHOW / CREATE / UPDATE / DESTROY
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

  # Regras principais centralizadas
  def can_manage?
    return false unless user.present?

    return true if user.is_a?(SuperAdmin)

    if user.is_a?(Admin)
      return user.escolas.include?(record.escola)
    end

    false
  end

  # ESCOPO DE CONSULTA
  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.all if user.is_a?(SuperAdmin)
      return scope.where(escola_id: user.escolas.ids) if user.is_a?(Admin)
      scope.none
    end
  end
end
