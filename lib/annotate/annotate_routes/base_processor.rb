module AnnotateRoutes
  # BaseProcessor is the abstract class of AnnotationProcessor and RemoveProcessor
  class BaseProcessor
    # @param routes_file [String] path for routes_file
    def initialize(routes_file)
      @routes_file = routes_file
    end

    # @param options [Hash] options
    # @return [Boolean]
    def process(options)
      set_new_text(existing_text, options)

      return false if existing_text == new_text

      File.open(routes_file, 'wb') { |f| f.puts(new_text) }
      true
    end

    private

    attr_reader :routes_file, :new_text

    # @return [String]
    def existing_text
      @existing_text ||= File.read(routes_file)
    end

    # @param text [String]
    # @param options [Hash] options
    # @return [String]
    def set_new_text(text, options)
      content, header_position = strip_annotations(text)
      @new_text = format_and_join(new_text_rows(content, header_position, options))
    end

    # @param text [String]
    # @return [Array] array of real_content (Array) and header_found_at (Symbol or Integer)
    # @note
    #   where_header_found => This is an array of 'real_content' and 'header_found_at'.
    #   'header_found_at' will either be :before, :after, or
    #   a number.  If the number is > 0, the
    #   annotation was found somewhere in the
    #   middle of the file.  If the number is
    #   zero, no annotation was found.
    def strip_annotations(text)
      real_content = []
      mode = :content
      header_found_at = 0

      text.split(/\n/, -1).each_with_index do |line, line_number|
        if mode == :header && line !~ /\s*#/
          mode = :content
          real_content << line unless line.blank?
        elsif mode == :content
          if line =~ /^\s*#\s*== Route.*$/
            header_found_at = line_number + 1 # index start's at 0
            mode = :header
          else
            real_content << line
          end
        end
      end

      where_header_found(real_content, header_found_at)
    end

    # @param real_content [Array <String>]
    # @param header_found_at [Integer]
    # @return [Array] array of real_content (Array) and header_found_at (Symbol or Integer)
    def where_header_found(real_content, header_found_at)
      # By default assume the annotation was found in the middle of the file

      # ... unless we have evidence it was at the beginning ...
      return real_content, :before if header_found_at == 1

      # ... or that it was at the end.
      return real_content, :after if header_found_at >= real_content.count

      # and the default
      [real_content, header_found_at]
    end

    # @param array [Array<String>]
    # @return [String]
    def format_and_join(array)
      # Make sure we end on a trailing newline.
      array << '' unless array.last == ''
      array.join("\n")
    end

    # @param _content [Array <String>]
    # @param _header_position [Integer]
    # @param options [Hash]
    def new_text_rows(_content, _header_position, _options)
      raise NotImplementedError
    end
  end
end
