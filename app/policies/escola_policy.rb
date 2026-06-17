# frozen_string_literal: true

class EscolaPolicy < ApplicationPolicy
  # Qualquer usuário logado pode ver lista
  def index?
    true
  end

  # Qualquer usuário logado pode visualizar uma escola
  def show?
    true
  end

  def welcome?
    return false unless user

    # SuperAdmin sempre pode
    return true if user.is_a?(SuperAdmin)

    # Admin sempre pode (tenha escola ou não)
    return true if user.is_a?(Admin)

    false
  end



  # Apenas SuperAdmin cria escolas
  def create?
    return false unless user

    # SuperAdmin pode sempre
    return true if user.is_a?(SuperAdmin)

    # Admin pode criar escola (a própria)
    return true if user.is_a?(Admin)

    false
  end

  # Admin comum só atualiza escolas que ele é dono
  def update?
    return false unless user
    return true if user.is_a?(SuperAdmin)
    return user.escolas.include?(record) if user.is_a?(Admin)
    false
  end

  # Admin comum é proibido de deletar escolas
  def destroy?
    user&.is_a?(SuperAdmin)
  end

  # Apenas super admin pode ver info sensível de admins
  def view_admin_info?
    user&.is_a?(SuperAdmin)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless user

      # SuperAdmin vê tudo
      return scope.all if user.is_a?(SuperAdmin)

      # Admin comum só vê suas próprias escolas
      return user.escolas if user.is_a?(Admin)

      # Usuários desconhecidos → nada
      scope.none
    end
  end
end
