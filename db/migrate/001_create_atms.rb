class CreateAtms < ActiveRecord::Migration[5.1]
  def change
    create_table :atms, force: true do |t|
      t.integer :uid
      t.integer :amount_usd
    end
  end
end
