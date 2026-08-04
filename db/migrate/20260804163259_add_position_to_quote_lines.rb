class AddPositionToQuoteLines < ActiveRecord::Migration[8.1]
  def up
    add_column :quote_lines, :position, :integer
    # Las líneas existentes conservan su orden de creación.
    execute <<~SQL
      UPDATE quote_lines SET position = sub.rn
      FROM (SELECT id, ROW_NUMBER() OVER (PARTITION BY quote_id ORDER BY id) AS rn FROM quote_lines) sub
      WHERE quote_lines.id = sub.id
    SQL
  end

  def down
    remove_column :quote_lines, :position
  end
end
