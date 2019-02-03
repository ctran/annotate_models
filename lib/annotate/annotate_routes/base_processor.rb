module AnnotateRoutes
  # Base class of processors (AnnotationProcessor and RemovalProcessor)
  class BaseProcessor
    def initialize(options, routes_file)
      @options = options
      @routes_file = routes_file
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
  end
end
