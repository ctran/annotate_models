# This module provides methods for annotating config/routes.rb.
module AnnotateRoutes
  # This module contains methods used in multiple classes.
  # This module is included in AnnotationProcessor and HeaderGenerator.
  module Helpers
    MAGIC_COMMENT_MATCHER = Regexp.new(/(^#\s*encoding:.*)|(^# coding:.*)|(^# -\*- coding:.*)|(^# -\*- encoding\s?:.*)|(^#\s*frozen_string_literal:.+)|(^# -\*- frozen_string_literal\s*:.+-\*-)/).freeze

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
  end
end
