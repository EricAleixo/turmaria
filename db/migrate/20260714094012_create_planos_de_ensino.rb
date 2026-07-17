class CreatePlanosDeEnsino < ActiveRecord::Migration[7.1]
  def change
    create_table :planos_de_ensino do |t|
      # Aninhamento: o plano pertence ao professor que o criou
      t.references :professor, type: :uuid, null: false, foreign_key: true

      # Turma e Disciplina já carregam ano_letivo, serie, turno e escola —
      # não duplicamos essas informações aqui, só referenciamos.
      t.references :turma, null: false, foreign_key: true
      t.references :disciplina, null: false, foreign_key: true

      # Período: número do bimestre, validado contra turma.bimestres_disponiveis
      t.integer :bimestre, null: false

      # Status do plano (Rascunho / Em Elaboração / Publicado)
      t.integer :status, null: false, default: 0

      # Não existe model Curso no sistema — mantido como texto livre e opcional
      t.string :curso

      # Informações do plano
      t.text :ementa
      t.text :objetivos_gerais
      t.text :objetivos_especificos
      t.text :competencias
      t.text :habilidades
      t.text :conteudos_programaticos
      t.text :metodologia
      t.text :recursos_didaticos
      t.text :criterios_avaliacao
      t.text :cronograma_unidades
      t.text :bibliografia_basica
      t.text :bibliografia_complementar
      t.text :observacoes

      t.timestamps
    end

    add_index :planos_de_ensino, [:professor_id, :turma_id, :disciplina_id, :bimestre],
              name: "index_planos_por_professor_turma_disciplina_bimestre"
  end
end