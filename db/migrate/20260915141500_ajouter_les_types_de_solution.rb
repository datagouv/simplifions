class AjouterLesTypesDeSolution < ActiveRecord::Migration[8.1]
  def change
    add_column :solutions, :types_solution, :string, array: true, default: [], null: false
  end
end
