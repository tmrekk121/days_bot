# frozen_string_literal: true

Rails.application.routes.draw do
  post '/webhook' => 'linebot#callback'
end
