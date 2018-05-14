class CreateOnDemandDerivatives < ActiveRecord::Migration[5.0]
  def change
    create_table :on_demand_derivatives do |t|
      t.string :work_id, null: false
      t.string :deriv_type, null: false
      t.string :status, null: false, default: "in_progress"
      t.string :checksum, null: false
      t.text :error_info

      t.integer :progress
      t.integer :progress_total

      t.integer :byte_size

      t.timestamps
    end

    add_index :on_demand_derivatives, [:work_id, :deriv_type], unique: true
  end
end
