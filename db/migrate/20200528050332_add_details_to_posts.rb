# frozen_string_literal: true

class AddDetailsToPosts < ActiveRecord::Migration[6.0]
  def change
    add_column :posts, :user_id, :string
    add_column :posts, :content, :string
    add_column :posts, :start_date, :date
  end
end
