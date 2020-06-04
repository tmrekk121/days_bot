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
      when Line::Bot::Event::Postback
        data = event['postback']['data'].split('content::')
        content = data[1]
        user_id = event['source']['userId']
        start_date = Date.parse(data[2])
        message_content = delete_content(user_id, content, start_date)
        client.reply_message(event['replyToken'], create_message(message_content))
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          if event.message['text'] == '一覧' || event.message['text'] == 'いちらん'
            @posts = Post.where(user_id: event['source']['userId'])
            message_array, message_array2, message_array3 = create_message_array(@posts)
            message_content = if message_array.empty?
                                create_message('何も登録されていないよ！')
                              else
                                create_flex_message(message_array, message_array2, message_array3)
                              end
          else
            if REDIS.get(event['source']['userId'])
              convert_date = day_convert(event.message['text'])
              if convert_date.nil?
                message_content = create_message('いつかわからないよ。正しい日付を入力してね。')
              else
                @post = Post.new(user_id: event['source']['userId'], content: REDIS.get(event['source']['userId']), start_date: convert_date)
                message_content = if @post.save
                                    REDIS.del(event['source']['userId'])
                                    create_message(convert_date.strftime('%Y/%m/%d') + 'だね。登録完了！')
                                  else
                                    create_message('すでにデータが登録されているか、正しい形式の日付じゃありません。もう一度日付を入力してね！')
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
    else
      day_convert2(original_message)
    end
  end

  def day_convert2(original_message)
    today = Date.current
    case original_message
    # example: 01月21日
    when /^([1-9]|0[1-9]|1[0-2])月([1-9]|0[1-9]|[12][0-9]|3[01])日$/
      day_array = original_message.match(/([1-9]|0[1-9]|1[0-2])月([1-9]|0[1-9]|[12][0-9]|3[01])日/)
      Date.new(today.year, day_array[1].to_i, day_array[2].to_i)
    # example: 2020年01月21日
    when /^20[0-9]{2}年([1-9]|0[1-9]|1[0-2])月([1-9]|0[1-9]|[12][0-9]|3[01])日$/
      day_array = original_message.match(/(20[0-9]{2})年([1-9]|0[1-9]|1[0-2])月([1-9]|0[1-9]|[12][0-9]|3[01])日/)
      Date.new(day_array[1].to_i, day_array[2].to_i, day_array[3].to_i)
    # example: 2020/01/21
    when %r{^20[0-9]{2}/([1-9]|0[1-9]|1[0-2])/([1-9]|0[1-9]|[12][0-9]|3[01])$}
      day_array = original_message.match(%r{(20[0-9]{2})/([0-9]{1,2})/([0-9]{1,2})})
      Date.new(day_array[1].to_i, day_array[2].to_i, day_array[3].to_i)
    # example: 2020-01-21
    when /^20[0-9]{2}-([1-9]|0[1-9]|1[0-2])-([1-9]|0[1-9]|[12][0-9]|3[01])$/
      day_array = original_message.match(/(20[0-9]{2})-([0-9]{1,2})-([0-9]{1,2})/)
      Date.new(day_array[1].to_i, day_array[2].to_i, day_array[3].to_i)
    # example: 01/21
    when %r{^([1-9]|0[1-9]|1[0-2])/([1-9]|0[1-9]|[12][0-9]|3[01])$}
      day_array = original_message.match(%r{([0-9]{1,2})/([0-9]{1,2})})
      Date.new(today.year, day_array[1].to_i, day_array[2].to_i)
    #  example: 01-21
    when /^([1-9]|0[1-9]|1[0-2])-([1-9]|0[1-9]|[12][0-9]|3[01])$/
      day_array = original_message.match(/([0-9]{1,2})-([0-9]{1,2})/)
      Date.new(today.year, day_array[1].to_i, day_array[2].to_i)
    else
      day_convert3(original_message)
    end
  end

  def day_convert3(original_message)
    today = Date.current
    case original_message
    when /^[0-9]{1,3}日前$/
      day_array = original_message.match(/([0-9]{1,3})日前/)
      today.prev_day(day_array[1].to_i)
    when /^[0-9]{1,3}日後$/
      day_array = original_message.match(/([0-9]{1,3})日後/)
      today.next_day(day_array[1].to_i)
    when /^[0-9]{1,3}ヶ月前$/
      day_array = original_message.match(/([0-9]{1,3})ヶ月前/)
      today.prev_month(day_array[1].to_i)
    when /^[0-9]{1,3}ヶ月後$/
      day_array = original_message.match(/([0-9]{1,3})ヶ月後/)
      today.next_month(day_array[1].to_i)
    when /^[0-9]{1,3}年前$/
      day_array = original_message.match(/([0-9]{1,3})年前/)
      today.prev_year(day_array[1].to_i)
    when /^[0-9]{1,3}年後$/
      day_array = original_message.match(/([0-9]{1,3})年後/)
      today.next_year(day_array[1].to_i)
    end
  end

  def delete_content(user_id, content, start_date)
    @post = Post.where(user_id: user_id, content: content, start_date: start_date)
    message_content = if @post[0].destroy
                        '削除しました。'
                      else
                        '削除に失敗しました。もう一度削除してください。'
                      end
    message_content
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
    message_array2 = []
    message_array3 = []
    today = Date.current
    posts.each do |post|
      days = today - post.start_date
      content = post.content
      if days.negative?
        days = -days.to_i
        util_or_since = 'あと何日'
        util_date = days.to_s
      else
        util_or_since = 'あれから何日'
        util_date = days.to_i.to_s
      end
      sample = [
        {
          type: 'text',
          text: util_or_since,
          size: 'xs',
          color: '#dcdcdc',
          align: 'start'
        },
        {
          type: 'text',
          text: content,
          size: 'lg',
          color: '#ffffff',
          align: 'center'
        },
        {
          type: 'text',
          text: util_date,
          size: 'lg',
          color: '#ffffff',
          align: 'center'
        }
      ]
      message_array3.push(post.start_date.to_s)
      message_array2.push(post.content)
      message_array.push(sample)
    end
    [message_array, message_array2, message_array3]
  end

  def create_flex_message(message_array, message_array2, message_array3)
    contents = []
    message_array.zip(message_array2, message_array3) do |ma, ma2, ma3|
      ct = {
        type: 'bubble',
        size: 'micro',
        body: {
          type: 'box',
          layout: 'vertical',
          contents: ma,
          backgroundColor: '#7f7fff'
        },
        footer: {
          type: 'box',
          layout: 'horizontal',
          contents: [
            type: 'button',
            action: {
              type: 'postback',
              label: '削除',
              data: 'content::' + ma2 + 'content::' + ma3
            }
          ],
          paddingTop: '0px',
          height: '45px'
        }
      }
      contents.push(ct)
    end
    messages = [{
      "type": 'flex',
      "altText": '*',
      "contents": {
        'type': 'carousel',
        'contents': contents
      }
    }]
    messages
  end
end
