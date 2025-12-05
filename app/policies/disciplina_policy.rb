class DisciplinaPolicy < ApplicationPolicy
  # INDEX - qualquer user autenticado vê as disciplinas dele
  def index?
    user.present?
  end

  # SHOW - Admin só vê se a disciplina é da escola dele
  def show?
    return true if user.is_a?(SuperAdmin)
    return user.escolas.include?(record.escola) if user.is_a?(Admin)

    false
  end

  # CREATE
  def create?
    return true if user.is_a?(SuperAdmin)
    return user.escolas.include?(record.escola) if user.is_a?(Admin)

    false
  end

  # UPDATE
  def update?
    return true if user.is_a?(SuperAdmin)
    return user.escolas.include?(record.escola) if user.is_a?(Admin)

    false
  end

  # DESTROY
  def destroy?
    return true if user.is_a?(SuperAdmin)
    return user.escolas.include?(record.escola) if user.is_a?(Admin)

    false
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.all if user.is_a?(SuperAdmin)
      return scope.where(escola_id: user.escolas.ids) if user.is_a?(Admin)
      scope.none
    end
  end
end
