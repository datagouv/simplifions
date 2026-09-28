class DeviseCreateAdmins < ActiveRecord::Migration[8.1]
  def change
    create_table :admins do |t|
      t.string :email, null: false
      t.string :encrypted_password, null: false
      t.datetime :remember_created_at
      t.timestamps null: false
    end

    add_index :admins, :email, unique: true
  end
end
