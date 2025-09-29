# frozen_string_literal: true

class Logger
  # Default formatter for log messages.
  class Formatter
    Format = "%.1s, [%s #%d] %5s -- %s: %s\n"
    DatetimeFormat = "%Y-%m-%dT%H:%M:%S.%6N"
    NeedsQuoting = /[\\"=[^[:graph:]]]/.freeze

    attr_accessor :datetime_format

    def initialize
      @datetime_format = nil
    end

    def call(severity, time, progname, msg, context: nil)
      sprintf(Format, severity, format_datetime(time), Process.pid,
              severity, progname, format_message_with_context(msg, context))
    end

    private

    def format_message_with_context(msg, ctx)
      join_fields [msg2str(msg), format_context(ctx)]
    end

    def join_fields(fields)
      fields.reject {|f| f.nil? || f.empty? }.join(" ")
    end

    def format_context(context)
      return unless context
      context = Hash.try_convert(context) \
        or raise Error, "Expected context hash, was #{context.class}"
      join_fields context.map {|k, v| format_pair(k,v) }
    end

    def format_pair(k, v)
      "#{k}=#{format_value(v)}" unless v.nil?
    end

    def format_value(value)
      # "redundant" interpolation to avoid crash if to_s doesn't return a string
      # https://github.com/ruby/spec/blob/3affe1e54fcd11918a242ad5d4a7ba895ee30c4c/language/string_spec.rb#L130-L141
      value = "#{value}"
      value = value.dump if value.match?(NeedsQuoting)
      value
    end

    def format_datetime(time)
      time.strftime(@datetime_format || DatetimeFormat)
    end

    def msg2str(msg)
      case msg
      when ::String
        msg
      when ::Exception
        "#{ msg.message } (#{ msg.class })\n#{ msg.backtrace.join("\n") if msg.backtrace }"
      else
        msg.inspect
      end
    end
  end
end
