require 'excavator'
module Excavator
  class TableView
    class InvalidDataForHeaders < StandardError; end

    DEFAULT_DIVIDER = " | "

    def initialize(options = {})
      @options = options
      @_title = ""
      @_headers = []
      @_records = []
      @col_widths = Hash.new { |hash, key| hash[key] = 0 }
      @divider = options[:divider] || DEFAULT_DIVIDER

      yield self if block_given?
    end

    def title(t = nil)
      if t.nil?
        @_title = t
      else
        @_title = t
      end
    end

    def header(*headers)
      headers.flatten!

      headers.each do |h|
        index = @_headers.size
        @_headers << h
        @col_widths[h] = h.to_s.size
      end
    end

    def divider(str)
      @divider = str
    end

    def record(*args)
      args.flatten!
      if args.size != @_headers.size
        raise InvalidDataForHeaders.new(<<-MSG)
          Number of columns for record (#{args.size}) does not match number
          of headers (#{@_headers.size})
        MSG
      end
      update_column_widths Hash[*@_headers.zip(args).flatten]
      @_records << args
    end

    def to_s
      out = ""
      out << @_title << "\n" if !@_title.nil? && @_title != ""

      print_headers out

      @_records.each_with_index do |record|
        record.each_with_index do |val, i|
          out << column_formats[i] % val
          out << @divider if i != (record.size - 1)
        end
        out << "\n"
      end
      out << "\n"

      out
    end

    def update_column_widths(hash)
      hash.each do |key, val|
        @col_widths[key] = val.size if val && val.size > @col_widths[key]
      end
    end

    def print_headers(out)
      @_headers.each_with_index do |h, i|
        out << column_formats[i] % h
        out << @divider if i != (@_headers.size - 1)
      end
      out << "\n"
    end

    # Internal
    def column_formats
      @col_widths.collect { |h, width| "%-#{width}s" }
    end
  end
end
