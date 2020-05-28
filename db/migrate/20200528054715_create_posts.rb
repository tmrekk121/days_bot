class CreatePosts < ActiveRecord::Migration[6.0]
  def change
    create_table :posts do |t|
      t.string :user_id
      t.string :content
      t.date :start_date

      t.timestamps
    end
  end
end
