class CreateUsers < ActiveRecord::Migration[5.1]
  def change
    create_table :users, force: true do |t|
      t.integer :tg_id
      t.boolean :disabled
    end
  end
end
