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
            @posts = Post.where(user_id: event['source']['userId'])
            # message_content = create_message_array(@posts)
            message_content = create_flex_message(@posts)
            message_content = '何も登録されていないよ！' if message_content.empty?
          else
            if REDIS.get(event['source']['userId'])
              convert_date = day_convert(event.message['text'])
              if convert_date.nil?
                message_content = create_message('いつかわからないよ。正しい日付を入力してね。')
              else
                @post = Post.new(user_id: event['source']['userId'], content: REDIS.get(event['source']['userId']), start_date: convert_date)
                # TODO: 保存に成功したらredisからdataを削除
                message_content = if @post.save
                                    create_message(convert_date.strftime('%Y/%m/%d') + 'だね。登録完了！')
                                  else
                                    create_message('もう一度日付を入力してね！')
                                  end
              end
            else
              REDIS.set(event['source']['userId'], event.message['text'], options = { ex: 60 })
              message_content = create_message(event.message['text'] + 'だね！日付はいつ？')
            end
          end
          client.reply_message(event['replyToken'], message_content)
        end
      end
    end
    head :ok
  end

  private

  def day_convert(original_message)
    case original_message
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

  def create_message(message_content)
    message = {
      type: 'text',
      text: message_content
    }
    message
  end

  def create_message_array(posts)
    message_array = []
    posts.each do |post|
      sample = {
        type: 'text',
        text: post.content
      }
      message_array.push(sample)
    end
    message_array
  end

  def create_flex_message(posts)
    messages = Jbuilder.encode do |json|
      json.type 'carousel'
      json.contents do
        json.type 'bubble'
        json.body do
          json.type 'box'
          json.layout 'horizontal'
          json.contents do
            json.array! posts do |post|
              json.type 'text'
              json.text post.content
            end
          end
        end
      end
    end
    logger.debug(messages)
    messages
  end
end
