# frozen_string_literal: false
require 'logger'

class TestFormatter < Test::Unit::TestCase
  def test_call
    severity = 'INFO'
    time = Time.now
    progname = 'ruby'
    msg = 'This is a test'
    formatter = Logger::Formatter.new
    time_matcher = /\d{4}\-\d{2}\-\d{2}T\d{2}:\d{2}:\d{2}\.\d{6}/

    result = formatter.call(severity, time, progname, msg)
    matcher = /#{severity[0..0]}, \[#{time_matcher} #\d+\]  #{severity} -- #{progname}: #{msg}\n/

    assert_match(matcher, result)
  end

  def test_call_with_context
    time = Time.now
    msg = 'This is a test'
    formatter = Logger::Formatter.new
    time_matcher = /\d{4}\-\d{2}\-\d{2}T\d{2}:\d{2}:\d{2}\.\d{6}/

    # simple hash context
    result = formatter.call("INFO", time, "ruby", msg, context: { foo: "bar" })
    matcher = /I, \[#{time_matcher} #\d+\]  INFO -- ruby: #{msg} foo=bar\n/
    assert_match(matcher, result)

    # UTF-8 characters are allowed
    result = formatter.call("INFO", time, "ruby", msg, context: { smile: "🙂" })
    matcher = /I, \[#{time_matcher} #\d+\]  INFO -- ruby: #{msg} smile=🙂\n/
    assert_match(matcher, result)

    # control
    result = formatter.call("INFO", time, "ruby", msg, context: {null: "\0"})
    matcher = /I, \[#{time_matcher} #\d+\]  INFO -- ruby: #{msg} null="\\x00"\n/
    assert_match(matcher, result)

    result = formatter.call("INFO", time, "ruby", msg, context: {cntl: "\x7f"})
    matcher = /I, \[#{time_matcher} #\d+\]  INFO -- ruby: #{msg} cntl="\\x7F"\n/
    assert_match(matcher, result)

    result = formatter.call("INFO", time, "ruby", msg, context: {sp: " "})
    matcher = /I, \[#{time_matcher} #\d+\]  INFO -- ruby: #{msg} sp=" "\n/
    assert_match(matcher, result)

    result = formatter.call("INFO", time, "ruby", msg, context: {bsol: "\\"})
    matcher = /I, \[#{time_matcher} #\d+\]  INFO -- ruby: #{msg} bsol="\\\\"\n/
    assert_match(matcher, result)

    result = formatter.call("INFO", time, "ruby", msg, context: {eq: "="})
    matcher = /I, \[#{time_matcher} #\d+\]  INFO -- ruby: #{msg} eq="="\n/
    assert_match(matcher, result)

    result = formatter.call("INFO", time, "ruby", msg, context: {dquo: '"'})
    matcher = /I, \[#{time_matcher} #\d+\]  INFO -- ruby: #{msg} dquo="\\""\n/
    assert_match(matcher, result)

    # context as nil
    result = formatter.call("INFO", time, "ruby", msg, context: nil)
    matcher = /I, \[#{time_matcher} #\d+\]  INFO -- ruby: #{msg}\n/
    assert_match(matcher, result)

    # unsupported context
    assert_raise(Logger::Error) { formatter.call("INFO", time, "ruby", msg, context: Object.new) }
  end

  class CustomFormatter < Logger::Formatter
    def call(time)
      format_datetime(time)
    end
  end

  def test_format_datetime
    time = Time.now
    formatter = CustomFormatter.new

    result = formatter.call(time)
    matcher = /^\d{4}\-\d{2}\-\d{2}T\d{2}:\d{2}:\d{2}\.\d{6}$/

    assert_match(matcher, result)
  end
end
