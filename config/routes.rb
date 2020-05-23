# frozen_string_literal: true

Rails.application.routes.draw do
  post '/callback' => 'linebot#callback'
end
