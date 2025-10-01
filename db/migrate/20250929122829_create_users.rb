class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.references :profile, polymorphic: true, null: false

      t.timestamps
    end
  end
end
