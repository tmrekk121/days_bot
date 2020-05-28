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
          if event.message['text'] == '一覧' || event.message['text'] == 'いちらん'
            @posts = Post.find_by(user_id: event['source']['userId'])
            message_content = create_message_array(@posts)
          else
            if REDIS.get(event['source']['userId'])
              convert_date = day_convert(event.message['text'])
              if convert_date.nil?
                message_content = 'いつかわからないよ。正しい日付を入力してね。'
              else
                @post = Post.new(user_id: event['source']['userId'], content: REDIS.get(event['source']['userId']), start_date: convert_date)
                message_content = if @post.save
                                    convert_date.strftime('%Y/%m/%d') + 'だね。登録完了！'
                                  else
                                    'もう一度日付を入力してね！'
                                  end
              end
            else
              REDIS.set(event['source']['userId'], event.message['text'])
              message_content = event.message['text'] + 'だね！日付はいつ？'
            end
          end
          send_message(event['replyToken'], message_content)
        end
      end
    end
    head :ok
  end

  private

  def day_convert(message)
    case message
    when '今日', 'きょう'
      Date.current
    when '明日', 'あした'
      Date.tomorrow
    when '明後日', 'あさって'
      Date.tomorrow.tomorrow
    when '昨日', 'きのう'
      Date.yesterday
    when '一昨日', 'おととい'
      Date.yesterday.yesterday
    end
  end

  def send_message(token, value)
    message = [{
      type: 'text',
      text: value
    }]
    client.reply_message(token, message)
  end

  def create_message_array(posts)
    message_array = []
    posts.each do |message|
      sample = {
        type: 'text',
        text: message
      }
      message_array.push(sample)
    end
  end
end
