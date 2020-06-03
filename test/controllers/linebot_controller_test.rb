# frozen_string_literal: true

require 'test_helper'

class LinebotControllerTest < ActionDispatch::IntegrationTest
  setup do
    @linebot = LinebotController.new
  end

  test 'day_convertのテスト' do
    expected = Date.current
    actual_kanji = @linebot.send(:day_convert, '今日')
    actual_hiragana = @linebot.send(:day_convert, 'きょう')
    assert_equal(expected, actual_kanji)
    assert_equal(expected, actual_hiragana)

    expected = Date.tomorrow
    actual_kanji = @linebot.send(:day_convert, '明日')
    actual_hiragana = @linebot.send(:day_convert, 'あした')
    assert_equal(expected, actual_kanji)
    assert_equal(expected, actual_hiragana)

    expected = Date.tomorrow.tomorrow
    actual = @linebot.send(:day_convert, '明後日')
    assert_equal(expected, actual)

    expected = Date.yesterday
    actual = @linebot.send(:day_convert, '昨日')
    assert_equal(expected, actual)

    expected = Date.yesterday.yesterday
    actual = @linebot.send(:day_convert, '一昨日')
    assert_equal(expected, actual)

    actual = @linebot.send(:day_convert, 'いつか')
    assert_nil(actual)
  end

  test '01月21日 1月21日 10月21日' do
    expected = Date.new(2020, 1, 21)
    actual = @linebot.send(:day_convert, '01月21日')
    assert_equal(expected, actual)

    actual = @linebot.send(:day_convert, '1月21日')
    assert_equal(expected, actual)

    expected = Date.new(2020, 10, 21)
    actual = @linebot.send(:day_convert, '10月21日')
    assert_equal(expected, actual)
  end

  test '01月01日 01月1日 01月10日 01月20日 01月30日' do
    expected = Date.new(2020, 1, 1)
    actual = @linebot.send(:day_convert, '1月01日')
    assert_equal(expected, actual)

    actual = @linebot.send(:day_convert, '1月1日')
    assert_equal(expected, actual)

    expected = Date.new(2020, 1, 10)
    actual = @linebot.send(:day_convert, '1月10日')
    assert_equal(expected, actual)

    expected = Date.new(2020, 1, 20)
    actual = @linebot.send(:day_convert, '1月20日')
    assert_equal(expected, actual)

    expected = Date.new(2020, 1, 30)
    actual = @linebot.send(:day_convert, '1月30日')
    assert_equal(expected, actual)
  end

  test '2020年1月21日 1020年01月21日 12000年01月21日' do
    expected = Date.new(2020, 1, 21)
    actual = @linebot.send(:day_convert, '2020年01月21日')
    assert_equal(expected, actual)

    actual = @linebot.send(:day_convert, '1020年01月21日')
    assert_nil(actual)

    actual = @linebot.send(:day_convert, '12000年01月21日')
    assert_nil(actual)
  end

  test '2020/01/21 01/21' do
    expected = Date.new(2020, 1, 21)
    actual = @linebot.send(:day_convert, '2020/01/21')
    assert_equal(expected, actual)

    actual = @linebot.send(:day_convert, '1020/01/21')
    assert_nil(actual)

    actual = @linebot.send(:day_convert, '12000/01/21')
    assert_nil(actual)

    actual = @linebot.send(:day_convert, '01/21')
    assert_equal(expected, actual)

    actual = @linebot.send(:day_convert, '2000/21')
    assert_nil(actual)

    actual = @linebot.send(:day_convert, '/21')
    assert_nil(actual)

    actual = @linebot.send(:day_convert, '21/')
    assert_nil(actual)
  end

  test '2020-01-21 01-21' do
    expected = Date.new(2020, 1, 21)
    actual = @linebot.send(:day_convert, '2020-01-21')
    assert_equal(expected, actual)

    actual = @linebot.send(:day_convert, '1020-01-21')
    assert_nil(actual)

    actual = @linebot.send(:day_convert, '12000-01-21')
    assert_nil(actual)

    actual = @linebot.send(:day_convert, '01-21')
    assert_equal(expected, actual)

    actual = @linebot.send(:day_convert, '2000-21')
    assert_nil(actual)

    actual = @linebot.send(:day_convert, '-21')
    assert_nil(actual)

    actual = @linebot.send(:day_convert, '21-')
    assert_nil(actual)
  end

  test '0日前 0日後' do
    today = Date.current
    expected = today.prev_day(0)
    actual = @linebot.send(:day_convert, '0日前')
    assert_equal(expected, actual)

    expected = today.prev_day(0)
    actual = @linebot.send(:day_convert, '00日前')
    assert_equal(expected, actual)

    expected = today.prev_day(0)
    actual = @linebot.send(:day_convert, '000日前')
    assert_equal(expected, actual)

    actual = @linebot.send(:day_convert, '0000日前')
    assert_nil(actual)

    expected = today.next_day(0)
    actual = @linebot.send(:day_convert, '0日後')
    assert_equal(expected, actual)

    expected = today.next_day(0)
    actual = @linebot.send(:day_convert, '00日後')
    assert_equal(expected, actual)

    expected = today.next_day(0)
    actual = @linebot.send(:day_convert, '000日後')
    assert_equal(expected, actual)

    actual = @linebot.send(:day_convert, '0000日後')
    assert_nil(actual)
  end

  test '1日前 1日後' do
    today = Date.current
    expected = today.prev_day(1)
    actual = @linebot.send(:day_convert, '1日前')
    assert_equal(expected, actual)

    actual = @linebot.send(:day_convert, '01日前')
    assert_equal(expected, actual)

    actual = @linebot.send(:day_convert, '001日前')
    assert_equal(expected, actual)

    actual = @linebot.send(:day_convert, '0001日前')
    assert_nil(actual)

    expected = today.next_day(1)
    actual = @linebot.send(:day_convert, '1日後')
    assert_equal(expected, actual)

    actual = @linebot.send(:day_convert, '01日後')
    assert_equal(expected, actual)

    actual = @linebot.send(:day_convert, '001日後')
    assert_equal(expected, actual)

    actual = @linebot.send(:day_convert, '0001日後')
    assert_nil(actual)
  end

  test '1ヶ月前 1ヶ月後' do
    today = Date.current
    expected = today.prev_month(1)
    actual = @linebot.send(:day_convert, '1ヶ月前')
    assert_equal(expected, actual)

    expected = today.next_month(1)
    actual = @linebot.send(:day_convert, '1ヶ月後')
    assert_equal(expected, actual)
  end

  test '1年前 1年後' do
    today = Date.current
    expected = today.prev_year(1)
    actual = @linebot.send(:day_convert, '1年前')
    assert_equal(expected, actual)

    expected = today.next_year(1)
    actual = @linebot.send(:day_convert, '1年後')
    assert_equal(expected, actual)
  end
end
