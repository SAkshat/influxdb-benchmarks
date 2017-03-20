class CreateRadiator < ActiveRecord::Migration
  def change
    create_table :radiators do |t|
      t.string :sensor
      t.integer :temp
      t.integer :wspd
      t.string :status
      t.datetime :timestamp
    end

    add_index :radiators, :sensor
    add_index :radiators, :timestamp
  end
end
