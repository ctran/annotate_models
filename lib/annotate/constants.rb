module Annotate
  module Constants
    TRUE_RE = /^(true|t|yes|y|1)$/i.freeze

    ##
    # The set of available options to customize the behavior of Annotate.
    #
    POSITION_OPTIONS = [
      :position_in_routes, :position_in_class, :position_in_test,
      :position_in_fixture, :position_in_factory, :position,
      :position_in_serializer
    ].freeze

    FLAG_OPTIONS = [
      :show_indexes, :simple_indexes, :include_version, :exclude_tests,
      :exclude_fixtures, :exclude_factories, :ignore_model_sub_dir,
      :format_bare, :format_rdoc, :format_yard, :format_markdown, :sort, :force, :frozen,
      :trace, :timestamp, :exclude_serializers, :classified_sort,
      :show_foreign_keys, :show_complete_foreign_keys,
      :exclude_scaffolds, :exclude_controllers, :exclude_helpers,
      :exclude_sti_subclasses, :ignore_unknown_models, :with_comment
    ].freeze

    OTHER_OPTIONS = [
      :additional_file_patterns, :ignore_columns, :skip_on_db_migrate, :wrapper_open, :wrapper_close,
      :wrapper, :routes, :models, :hide_limit_column_types, :hide_default_column_types,
      :ignore_routes, :active_admin
    ].freeze

    PATH_OPTIONS = [
      :require, :model_dir, :root_dir
    ].freeze

    ALL_ANNOTATE_OPTIONS = [
      POSITION_OPTIONS, FLAG_OPTIONS, OTHER_OPTIONS, PATH_OPTIONS
    ].freeze
  end
end
