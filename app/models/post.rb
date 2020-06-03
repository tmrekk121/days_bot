# frozen_string_literal: true

class Post < ApplicationRecord
  validates :user_id, uniqueness: { scope: %i[content start_date] }
end
