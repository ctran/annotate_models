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
require_relative './annotate_routes/header_generator'

module AnnotateRoutes
  class << self
    def do_annotations(options = {})
      if routes_file_exist?
        existing_text = File.read(routes_file)
        content, header_position = Helpers.strip_annotations(existing_text)
        new_content = annotate_routes(HeaderGenerator.generate(options), content, header_position, options)
        new_text = new_content.join("\n")

        if options[:frozen]
          if needs_rewrite_contents?(existing_text, new_text)
            abort "annotate error. #{routes_file} needs to be updated, but annotate was run with `--frozen`."
          else
            puts "#{routes_file} was not changed."
          end
        elsif rewrite_contents(existing_text, new_text)
          puts "#{routes_file} was annotated."
        else
          puts "#{routes_file} was not changed."
        end
      else
        puts "#{routes_file} could not be found."
      end
    end

    def remove_annotations(_options={})
      if routes_file_exist?
        existing_text = File.read(routes_file)
        content, header_position = Helpers.strip_annotations(existing_text)
        new_content = strip_on_removal(content, header_position)
        new_text = new_content.join("\n")
        if rewrite_contents(existing_text, new_text)
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

    def rewrite_contents(existing_text, new_text)
      if needs_rewrite_contents?(existing_text, new_text)
        File.open(routes_file, 'wb') { |f| f.puts(new_text) }
        true
      else
        false
      end
    end

    def needs_rewrite_contents?(existing_text, new_text)
      existing_text != new_text
    end

    def annotate_routes(header, content, header_position, options = {})
      magic_comments_map, content = Helpers.extract_magic_comments_from_array(content)
      if %w(before top).include?(options[:position_in_routes])
        header = header << '' if content.first != ''
        magic_comments_map << '' if magic_comments_map.any?
        new_content = magic_comments_map + header + content
      else
        # Ensure we have adequate trailing newlines at the end of the file to
        # ensure a blank line separating the content from the annotation.
        content << '' unless content.last == ''

        # We're moving something from the top of the file to the bottom, so ditch
        # the spacer we put in the first time around.
        content.shift if header_position == :before && content.first == ''

        new_content = magic_comments_map + content + header
      end

      # Make sure we end on a trailing newline.
      new_content << '' unless new_content.last == ''

      new_content
    end
  end
end
