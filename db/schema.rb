# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2025_09_21_220510) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "admins", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "nome"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.index ["confirmation_token"], name: "index_admins_on_confirmation_token", unique: true
    t.index ["email"], name: "index_admins_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admins_on_reset_password_token", unique: true
  end

  create_table "alunos", force: :cascade do |t|
    t.string "nome"
    t.date "data_nascimento"
    t.bigint "turma_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "escola_id", null: false
    t.integer "idade"
    t.string "cpf"
    t.string "rg"
    t.string "telefone"
    t.string "email"
    t.string "sexo"
    t.string "cor"
    t.string "tipo_sanguinio"
    t.string "necessidades_especiais_tipo"
    t.text "observacoes_pcd"
    t.string "responsavel_1"
    t.string "responsavel_2"
    t.string "telefone_responsavel_1"
    t.string "telefone_responsavel_2"
    t.string "foto_url"
    t.string "cpf_url"
    t.string "comprovante_residencia_url"
    t.string "historico_academico_url"
    t.index ["escola_id", "turma_id"], name: "index_alunos_on_escola_id_and_turma_id"
    t.index ["escola_id"], name: "index_alunos_on_escola_id"
    t.index ["turma_id"], name: "index_alunos_on_turma_id"
  end

  create_table "ano_letivos", force: :cascade do |t|
    t.integer "ano"
    t.date "data_inicio"
    t.date "data_fim"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "escola_id"
    t.integer "numero_bimestre"
    t.index ["escola_id"], name: "index_ano_letivos_on_escola_id"
  end

  create_table "cidades", force: :cascade do |t|
    t.string "nome"
    t.bigint "estado_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["estado_id"], name: "index_cidades_on_estado_id"
  end

  create_table "coordenadors", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "nome"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.index ["confirmation_token"], name: "index_coordenadors_on_confirmation_token", unique: true
    t.index ["email"], name: "index_coordenadors_on_email", unique: true
    t.index ["reset_password_token"], name: "index_coordenadors_on_reset_password_token", unique: true
  end

  create_table "email_cadastros", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "user_type", null: false
    t.uuid "user_id", null: false
    t.index ["email"], name: "index_email_cadastros_on_email", unique: true
    t.index ["user_type", "user_id"], name: "index_email_cadastros_on_user"
  end

  create_table "enderecos", force: :cascade do |t|
    t.string "logradouro"
    t.string "numero"
    t.string "bairro"
    t.string "cep"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "aluno_id"
    t.uuid "escola_id", null: false
    t.bigint "cidade_id", null: false
    t.string "complemento"
    t.index ["cidade_id"], name: "index_enderecos_on_cidade_id"
    t.index ["escola_id"], name: "index_enderecos_on_escola_id"
  end

  create_table "escolas", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "nome"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "cnpj"
    t.integer "turmas_count", default: 0
    t.integer "alunos_count", default: 0
    t.uuid "admin_id"
    t.string "telefone"
    t.string "email"
    t.string "site"
    t.string "tipo", default: "publica", null: false
    t.index ["admin_id"], name: "index_escolas_on_admin_id"
    t.index ["alunos_count"], name: "index_escolas_on_alunos_count"
    t.index ["cnpj"], name: "index_escolas_on_cnpj", unique: true
    t.index ["nome"], name: "index_escolas_on_nome", unique: true
    t.index ["tipo"], name: "index_escolas_on_tipo"
    t.index ["turmas_count"], name: "index_escolas_on_turmas_count"
  end

  create_table "estados", force: :cascade do |t|
    t.string "nome"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "nota", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "professors", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "nome"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.index ["confirmation_token"], name: "index_professors_on_confirmation_token", unique: true
    t.index ["email"], name: "index_professors_on_email", unique: true
    t.index ["reset_password_token"], name: "index_professors_on_reset_password_token", unique: true
  end

  create_table "super_admins", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "nome"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.index ["confirmation_token"], name: "index_super_admins_on_confirmation_token", unique: true
    t.index ["email"], name: "index_super_admins_on_email", unique: true
    t.index ["reset_password_token"], name: "index_super_admins_on_reset_password_token", unique: true
  end

  create_table "turmas", force: :cascade do |t|
    t.string "nome"
    t.integer "serie"
    t.integer "turno"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "escola_id", null: false
    t.bigint "ano_letivo_id", null: false
    t.index ["ano_letivo_id"], name: "index_turmas_on_ano_letivo_id"
    t.index ["escola_id"], name: "index_turmas_on_escola_id"
  end

  add_foreign_key "alunos", "escolas"
  add_foreign_key "alunos", "turmas"
  add_foreign_key "ano_letivos", "escolas"
  add_foreign_key "cidades", "estados"
  add_foreign_key "enderecos", "alunos"
  add_foreign_key "enderecos", "cidades"
  add_foreign_key "enderecos", "escolas"
  add_foreign_key "escolas", "admins"
  add_foreign_key "turmas", "ano_letivos"
  add_foreign_key "turmas", "escolas"
end
