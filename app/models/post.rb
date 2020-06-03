# frozen_string_literal: true

class Post < ApplicationRecord
  validates :user_id, uniquness: { scope: %i[content start_date] }
end
