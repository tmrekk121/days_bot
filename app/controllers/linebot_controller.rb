# frozen_string_literal: true

class LinebotController < ApplicationController
  require 'line/bot'

  def client
    @client ||= Line::Bot::Client.new do |config|
      config.channel_id = ENV['LINE_CHANNEL_ID']
      config.channel_secret = ENV['LINE_CHANNEL_SECRET']
      config.channel_token = ENV['LINE_CHANNEL_TOKEN']
    end
  end

  def callback
    body = request.body.read

    signature = request.env['HTTP_X_LINE_SIGNATURE']
    head :bad_request unless client.validate_signature(body, signature)

    events = client.parse_events_from(body)
    events.each do |event|
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          if REDIS.get(event.source['id'])
            # TODO: clientに日付要求
          else
            REDIS.set(event.source['id'], event.message['text'])
            logger.debug('else')
          end
          message = {
            type: 'text',
            text: event.message['text'] + 'だね！日付はいつ？'
          }
          client.reply_message(event['replyToken'], message)
        end
      end
    end
    head :ok
  end
end
