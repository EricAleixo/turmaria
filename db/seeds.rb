# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Professor
Professor.create!(
  email: "professor@teste.com",
  nome: "Professor Teste",
  password: "123456",
  password_confirmation: "123456",
  confirmed_at: Time.now
)

# Coordenador
Coordenador.create!(
  email: "coordenador@teste.com",
  nome: "Coordenador Teste",
  password: "123456",
  password_confirmation: "123456",
  confirmed_at: Time.now
)

# Administrador
Admin.create!(
  email: "admin@teste.com",
  nome: "Admin Teste",
  password: "123456",
  password_confirmation: "123456",
  confirmed_at: Time.now
)

# SuperAdmin
SuperAdmin.create!(
  email: "superadmin@teste.com",
  nome: "Super Admin",
  password: "123456",
  password_confirmation: "123456",
  confirmed_at: Time.now
)
