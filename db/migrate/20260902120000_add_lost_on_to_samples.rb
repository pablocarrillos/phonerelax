# frozen_string_literal: true

class AddLostOnToSamples < ActiveRecord::Migration[8.1]
  def change
    add_column :samples, :lost_on, :date
  end
end
