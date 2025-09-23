class Alunos::SessionsController < Devise::SessionsController
   
  def new
    self.resource = resource_class.new
    clean_up_passwords(resource)
    yield resource if block_given?
    render 'alunos/devise/sessions/new'
  end
  
end