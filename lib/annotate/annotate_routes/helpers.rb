module AnnotateRoutes
  module Helpers
    MAGIC_COMMENT_MATCHER = Regexp.new(/(^#\s*encoding:.*)|(^# coding:.*)|(^# -\*- coding:.*)|(^# -\*- encoding\s?:.*)|(^#\s*frozen_string_literal:.+)|(^# -\*- frozen_string_literal\s*:.+-\*-)/).freeze

    class << self
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

      # @param [Array<String>] content
      # @return [Array<String>] all found magic comments
      # @return [Array<String>] content without magic comments
      def extract_magic_comments_from_array(content_array)
        magic_comments = []
        new_content = []

        content_array.each do |row|
          if row =~ MAGIC_COMMENT_MATCHER
            magic_comments << row.strip
          else
            new_content << row
          end
        end

        [magic_comments, new_content]
      end

      private

      def real_content_and_header_position(real_content, header_position)
        # By default assume the annotation was found in the middle of the file

        # ... unless we have evidence it was at the beginning ...
        return real_content, :before if header_position == 1

        # ... or that it was at the end.
        return real_content, :after if header_position >= real_content.count

        # and the default
        return real_content, header_position
      end
    end
  end
end
