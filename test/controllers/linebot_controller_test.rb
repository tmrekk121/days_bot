# frozen_string_literal: true

require 'test_helper'

class LinebotControllerTest < ActionDispatch::IntegrationTest
  test 'day_convertのテスト' do
    linebot = LinebotController.new

    expected = Date.current
    actual_kanji = linebot.send(:day_convert, '今日')
    actual_hiragana = linebot.send(:day_convert, 'きょう')
    assert_equal(expected, actual_kanji)
    assert_equal(expected, actual_hiragana)

    expected = Date.tomorrow
    actual_kanji = linebot.send(:day_convert, '明日')
    actual_hiragana = linebot.send(:day_convert, 'あした')
    assert_equal(expected, actual_kanji)
    assert_equal(expected, actual_hiragana)

    expected = Date.tomorrow.tomorrow
    actual = linebot.send(:day_convert, '明後日')
    assert_equal(expected, actual)

    expected = Date.yesterday
    actual = linebot.send(:day_convert, '昨日')
    assert_equal(expected, actual)

    expected = Date.yesterday.yesterday
    actual = linebot.send(:day_convert, '一昨日')
    assert_equal(expected, actual)
  end
end
