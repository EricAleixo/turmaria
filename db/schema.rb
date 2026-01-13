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

ActiveRecord::Schema[7.1].define(version: 2026_01_13_160820) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "action_text_rich_texts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.uuid "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.uuid "record_id", null: false
    t.uuid "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

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

  create_table "alunos", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
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
    t.text "necessidades_especiais_tipo", default: [], array: true
    t.text "observacoes_pcd"
    t.string "responsavel_1"
    t.string "responsavel_2"
    t.string "telefone_responsavel_1"
    t.string "telefone_responsavel_2"
    t.string "foto_url"
    t.string "cpf_url"
    t.string "comprovante_residencia_url"
    t.string "historico_academico_url"
    t.string "matricula"
    t.string "encrypted_password"
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.bigint "cidade_id"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.index ["cidade_id"], name: "index_alunos_on_cidade_id"
    t.index ["confirmation_token"], name: "index_alunos_on_confirmation_token", unique: true
    t.index ["escola_id", "turma_id"], name: "index_alunos_on_escola_id_and_turma_id"
    t.index ["escola_id"], name: "index_alunos_on_escola_id"
    t.index ["matricula"], name: "index_alunos_on_matricula", unique: true
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

  create_table "area_disciplinas", force: :cascade do |t|
    t.string "nome", null: false
    t.string "cor", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "escola_id", null: false
    t.index ["escola_id"], name: "index_area_disciplinas_on_escola_id"
  end

  create_table "avaliacao_bimestrals", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "avaliacao_configuracaos", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "avaliacoes_bimestrais", force: :cascade do |t|
    t.uuid "aluno_id", null: false
    t.bigint "turma_id", null: false
    t.bigint "disciplina_id", null: false
    t.integer "bimestre", null: false
    t.decimal "nota_bimestre_final", precision: 4, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["aluno_id", "turma_id", "disciplina_id", "bimestre"], name: "idx_unique_avaliacao_bimestral", unique: true
    t.index ["aluno_id"], name: "index_avaliacoes_bimestrais_on_aluno_id"
    t.index ["disciplina_id"], name: "index_avaliacoes_bimestrais_on_disciplina_id"
    t.index ["turma_id"], name: "index_avaliacoes_bimestrais_on_turma_id"
  end

  create_table "avaliacoes_configuracoes", force: :cascade do |t|
    t.bigint "turma_id", null: false
    t.bigint "disciplina_id", null: false
    t.integer "bimestre", null: false
    t.string "nome", null: false
    t.boolean "is_recuperacao", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "avaliacao_original_id"
    t.index ["avaliacao_original_id"], name: "index_avaliacoes_configuracoes_on_avaliacao_original_id"
    t.index ["disciplina_id"], name: "index_avaliacoes_configuracoes_on_disciplina_id"
    t.index ["turma_id", "disciplina_id", "bimestre", "nome"], name: "idx_unique_avaliacao_config", unique: true
    t.index ["turma_id"], name: "index_avaliacoes_configuracoes_on_turma_id"
  end

  create_table "cidades", force: :cascade do |t|
    t.string "nome"
    t.bigint "estado_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["estado_id"], name: "index_cidades_on_estado_id"
  end

  create_table "conteudos", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "titulo"
    t.integer "bimestre", default: 1
    t.text "descricao"
    t.uuid "professor_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "disciplina_id"
    t.uuid "escola_id"
    t.text "markdown"
    t.integer "tipo", default: 0, null: false
    t.bigint "turma_id", null: false
    t.index ["bimestre"], name: "index_conteudos_on_bimestre"
    t.index ["disciplina_id"], name: "index_conteudos_on_disciplina_id"
    t.index ["escola_id", "disciplina_id", "professor_id"], name: "index_conteudos_on_escola_disciplina_professor"
    t.index ["escola_id"], name: "index_conteudos_on_escola_id"
    t.index ["professor_id"], name: "index_conteudos_on_professor_id"
    t.index ["turma_id"], name: "index_conteudos_on_turma_id"
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

  create_table "disciplinas", force: :cascade do |t|
    t.string "nome"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "escola_id", null: false
    t.string "cor_nome"
    t.bigint "area_disciplina_id"
    t.index ["area_disciplina_id"], name: "index_disciplinas_on_area_disciplina_id"
    t.index ["escola_id"], name: "index_disciplinas_on_escola_id"
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
    t.uuid "aluno_id"
    t.uuid "escola_id"
    t.string "complemento"
    t.bigint "cidade_id"
    t.uuid "professor_id"
    t.index ["cidade_id"], name: "index_enderecos_on_cidade_id"
    t.index ["escola_id"], name: "index_enderecos_on_escola_id"
    t.index ["professor_id"], name: "index_enderecos_on_professor_id"
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
    t.index "lower((nome)::text)", name: "index_escolas_on_lower_nome"
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
    t.string "sigla"
    t.string "regiao"
  end

  create_table "frequencia_alunos", force: :cascade do |t|
    t.bigint "frequencia_id", null: false
    t.uuid "aluno_id"
    t.string "status", default: "presente", null: false
    t.text "observacoes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["aluno_id"], name: "index_frequencia_alunos_on_aluno_id"
    t.index ["frequencia_id", "aluno_id"], name: "index_frequencia_alunos_on_frequencia_id_and_aluno_id", unique: true
    t.index ["frequencia_id"], name: "index_frequencia_alunos_on_frequencia_id"
  end

  create_table "frequencias", force: :cascade do |t|
    t.bigint "turma_id", null: false
    t.uuid "professor_id"
    t.date "data_aula", null: false
    t.text "conteudo_trabalhado"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "observacoes"
    t.bigint "disciplina_id", null: false
    t.index ["disciplina_id"], name: "index_frequencias_on_disciplina_id"
    t.index ["professor_id"], name: "index_frequencias_on_professor_id"
    t.index ["turma_id", "data_aula"], name: "index_frequencias_on_turma_id_and_data_aula", unique: true
    t.index ["turma_id"], name: "index_frequencias_on_turma_id"
  end

  create_table "nota", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "professor_disciplinas", force: :cascade do |t|
    t.uuid "professor_id", null: false
    t.bigint "disciplina_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["disciplina_id"], name: "index_professor_disciplinas_on_disciplina_id"
    t.index ["professor_id"], name: "index_professor_disciplinas_on_professor_id"
  end

  create_table "professor_turmas", force: :cascade do |t|
    t.uuid "professor_id", null: false
    t.bigint "turma_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["professor_id"], name: "index_professor_turmas_on_professor_id"
    t.index ["turma_id"], name: "index_professor_turmas_on_turma_id"
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
    t.string "cpf"
    t.date "data_nascimento"
    t.string "telefone"
    t.string "foto"
    t.string "formacao"
    t.string "tipo_professor", default: "titular"
    t.uuid "escola_id"
    t.uuid "coordenador_id"
    t.index ["confirmation_token"], name: "index_professors_on_confirmation_token", unique: true
    t.index ["coordenador_id"], name: "index_professors_on_coordenador_id"
    t.index ["cpf"], name: "index_professors_on_cpf", unique: true
    t.index ["email"], name: "index_professors_on_email", unique: true
    t.index ["escola_id"], name: "index_professors_on_escola_id"
    t.index ["reset_password_token"], name: "index_professors_on_reset_password_token", unique: true
  end

  create_table "registro_de_nota", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "registros_de_notas", force: :cascade do |t|
    t.uuid "aluno_id", null: false
    t.bigint "avaliacao_configuracao_id", null: false
    t.decimal "valor", precision: 4, scale: 2, null: false
    t.date "data_registro"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["aluno_id", "avaliacao_configuracao_id"], name: "idx_unique_nota_registro_valor", unique: true
    t.index ["aluno_id"], name: "index_registros_de_notas_on_aluno_id"
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

  create_table "turma_disciplinas", force: :cascade do |t|
    t.bigint "turma_id", null: false
    t.bigint "disciplina_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["disciplina_id"], name: "index_turma_disciplinas_on_disciplina_id"
    t.index ["turma_id", "disciplina_id"], name: "index_turma_disciplinas_on_turma_id_and_disciplina_id", unique: true
    t.index ["turma_id"], name: "index_turma_disciplinas_on_turma_id"
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

  create_table "users", force: :cascade do |t|
    t.string "profile_type", null: false
    t.bigint "profile_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["profile_type", "profile_id"], name: "index_users_on_profile"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "alunos", "cidades"
  add_foreign_key "alunos", "escolas"
  add_foreign_key "alunos", "turmas"
  add_foreign_key "ano_letivos", "escolas"
  add_foreign_key "area_disciplinas", "escolas"
  add_foreign_key "avaliacoes_bimestrais", "alunos"
  add_foreign_key "avaliacoes_bimestrais", "disciplinas"
  add_foreign_key "avaliacoes_bimestrais", "turmas"
  add_foreign_key "avaliacoes_configuracoes", "avaliacoes_configuracoes", column: "avaliacao_original_id"
  add_foreign_key "avaliacoes_configuracoes", "disciplinas"
  add_foreign_key "avaliacoes_configuracoes", "turmas"
  add_foreign_key "cidades", "estados"
  add_foreign_key "conteudos", "disciplinas"
  add_foreign_key "conteudos", "escolas"
  add_foreign_key "conteudos", "professors"
  add_foreign_key "conteudos", "turmas"
  add_foreign_key "disciplinas", "area_disciplinas"
  add_foreign_key "disciplinas", "escolas"
  add_foreign_key "enderecos", "alunos"
  add_foreign_key "enderecos", "cidades"
  add_foreign_key "enderecos", "escolas"
  add_foreign_key "enderecos", "professors"
  add_foreign_key "escolas", "admins"
  add_foreign_key "frequencia_alunos", "alunos", on_delete: :nullify
  add_foreign_key "frequencia_alunos", "frequencias"
  add_foreign_key "frequencias", "disciplinas"
  add_foreign_key "frequencias", "professors"
  add_foreign_key "frequencias", "turmas"
  add_foreign_key "professor_disciplinas", "disciplinas"
  add_foreign_key "professor_disciplinas", "professors"
  add_foreign_key "professor_turmas", "professors"
  add_foreign_key "professor_turmas", "turmas"
  add_foreign_key "professors", "escolas"
  add_foreign_key "professors", "professors", column: "coordenador_id"
  add_foreign_key "registros_de_notas", "alunos"
  add_foreign_key "registros_de_notas", "avaliacoes_configuracoes", column: "avaliacao_configuracao_id"
  add_foreign_key "turma_disciplinas", "disciplinas"
  add_foreign_key "turma_disciplinas", "turmas"
  add_foreign_key "turmas", "ano_letivos"
  add_foreign_key "turmas", "escolas"
end
