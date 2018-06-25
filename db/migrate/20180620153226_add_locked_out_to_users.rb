class AddLockedOutToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :locked_out, :boolean,  null: false, default: false
  end
end