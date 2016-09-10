module PProf
  module CLI
    class ASCIITable
      def initialize(*widths)
        @widths = widths
      end

      def print_header(*headers)
        header_line = line(headers)
        print_separator
        puts header_line
        print_separator
      end

      def print_row(*columns)
        puts line(columns)
      end

      def print_separator()
        puts '+' + @widths.map { |w| '-' * (w+2) }.join('+') + '+' 
      end

      private
      def line(cols)
        '| ' + cols.zip(@widths).map do |c,w|
          (c || '<nil>').to_s.ljust(w)[0...w]
        end.join(' | ') + ' |'
      end
    end
  end
end
