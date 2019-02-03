# == Annotate Routes
#
# Based on:
#
#
#
# Prepends the output of "rake routes" to the top of your routes.rb file.
# Yes, it's simple but I'm thick and often need a reminder of what my routes
# mean.
#
# Running this task will replace any existing route comment generated by the
# task. Best to back up your routes file before running:
#
# Author:
#  Gavin Montague
#  gavin@leftbrained.co.uk
#
# Released under the same license as Ruby. No Support. No Warranty.
#

require_relative './annotate_routes/helpers'
require_relative './annotate_routes/annotation_processor'

module AnnotateRoutes
  class << self
    def do_annotations(options = {})
      if routes_file_exist?
        existing_text = File.read(routes_file)
        if AnnotationProcessor.update(routes_file, existing_text, options)
          puts "#{routes_file} was annotated."
        else
          puts "#{routes_file} was not changed."
        end
      else
        puts "#{routes_file} could not be found."
      end
    end

    def remove_annotations(options={})
      if routes_file_exist?
        existing_text = File.read(routes_file)
        content, header_position = Helpers.strip_annotations(existing_text)
        new_content = strip_on_removal(content, header_position)
        new_text = new_content.join("\n")
        if rewrite_contents(existing_text, new_text, options[:frozen])
          puts "Annotations were removed from #{routes_file}."
        else
          puts "#{routes_file} was not changed (Annotation did not exist)."
        end
      else
        puts "#{routes_file} could not be found."
      end
    end

    private

    def routes_file_exist?
      File.exist?(routes_file)
    end

    def routes_file
      @routes_rb ||= File.join('config', 'routes.rb')
    end

    def strip_on_removal(content, header_position)
      if header_position == :before
        content.shift while content.first == ''
      elsif header_position == :after
        content.pop while content.last == ''
      end

      # Make sure we end on a trailing newline.
      content << '' unless content.last == ''

      # TODO: If the user buried it in the middle, we should probably see about
      # TODO: preserving a single line of space between the content above and
      # TODO: below...
      content
    end

    def rewrite_contents(existing_text, new_text, frozen)
      content_changed = (existing_text != new_text)

      if content_changed
        abort "annotate error. #{routes_file} needs to be updated, but annotate was run with `--frozen`." if frozen
        File.open(routes_file, 'wb') { |f| f.puts(new_text) }
      end

      content_changed
    end
  end
end
