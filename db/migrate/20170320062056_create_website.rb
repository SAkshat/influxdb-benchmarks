class CreateWebsite < ActiveRecord::Migration
  def change
    create_table :websites do |t|
      t.string :name
      t.integer :no_of_clicks
      t.string :region
      t.datetime :timestamp
    end

    add_index :websites, :name
    add_index :websites, :region
    add_index :websites, :timestamp
  end
end
