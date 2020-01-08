# This module provides methods for annotating config/routes.rb.
module AnnotateRoutes
  # This class is abstract class of classes adding and removing annotation to config/routes.rb.
  class BaseProcessor
    def initialize(options, routes_file)
      @options = options
      @routes_file = routes_file
    end

    # @return [Boolean]
    def update
      content, header_position = strip_annotations(existing_text)
      new_content = generate_new_content_array(content, header_position)
      new_text = new_content.join("\n")
      rewrite_contents(new_text)
    end

    def routes_file_exist?
      File.exist?(routes_file)
    end

    private

    attr_reader :options, :routes_file

    def existing_text
      @existing_text ||= File.read(routes_file)
    end

    # @param new_text [String]
    # @return [Boolean]
    def rewrite_contents(new_text)
      content_changed = content_changed?(new_text)

      abort "annotate error. #{routes_file} needs to be updated, but annotate was run with `--frozen`." if content_changed && frozen?

      if content_changed
        write(new_text)
        true
      else
        false
      end
    end

    def write(text)
      File.open(routes_file, 'wb') { |f| f.puts(text) }
    end

    def content_changed?(new_text)
      existing_text != new_text
    end

    def frozen?
      options[:frozen]
    end

    # TODO: write the method doc using ruby rdoc formats
    # This method returns an array of 'real_content' and 'header_position'.
    # 'header_position' will either be :before, :after, or
    # a number.  If the number is > 0, the
    # annotation was found somewhere in the
    # middle of the file.  If the number is
    # zero, no annotation was found.
    def strip_annotations(content)
      real_content = []
      mode = :content
      header_position = 0

      content.split(/\n/, -1).each_with_index do |line, line_number|
        if mode == :header && line !~ /\s*#/
          mode = :content
          real_content << line unless line.blank?
        elsif mode == :content
          if line =~ /^\s*#\s*== Route.*$/
            header_position = line_number + 1 # index start's at 0
            mode = :header
          else
            real_content << line
          end
        end
      end

      real_content_and_header_position(real_content, header_position)
    end

    def real_content_and_header_position(real_content, header_position)
      # By default assume the annotation was found in the middle of the file

      # ... unless we have evidence it was at the beginning ...
      return real_content, :before if header_position == 1

      # ... or that it was at the end.
      return real_content, :after if header_position >= real_content.count

      # and the default
      [real_content, header_position]
    end
  end
end
