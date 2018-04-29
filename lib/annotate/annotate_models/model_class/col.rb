class AnnotateModels::ModelClass::Col
  BARE_TYPE_ALLOWANCE = 16

  # Don't show limit (#) on these column types
  # Example: show "integer" instead of "integer(4)"
  NO_LIMIT_COL_TYPES = %w(integer boolean).freeze

  # Don't show default value for these column types
  NO_DEFAULT_COL_TYPES = %w(json jsonb hstore).freeze

  def initialize(col, model_class)
    @col = col
    @model_class = model_class
  end

  def to_s(max_size, options)
    attrs = attrs(options)
    col_type = col_type_to_display(options)
    col_name = name_to_output(options)

    base_text = if options[:format_rdoc]
                  sprintf("# %-#{max_size}.#{max_size}s<tt>%s</tt>", "*#{col_name}*::",
                          attrs.unshift(col_type).join(', '))
                elsif options[:format_markdown]
                  name_remainder = max_size - col_name.length
                  type_remainder = (AnnotateModels::ModelClass::MD_TYPE_ALLOWANCE - 2) - col_type.length
                  sprintf("# **`%s`**%#{name_remainder}s | `%s`%#{type_remainder}s | `%s`",
                          col_name,
                          " ",
                          col_type,
                          " ",
                          attrs.join(', ').rstrip).gsub('``', '  ')
                else
                  sprintf("#  %-#{max_size}.#{max_size}s:%-#{BARE_TYPE_ALLOWANCE}.#{BARE_TYPE_ALLOWANCE}s %s",
                          col_name,
                          col_type,
                          attrs.join(', '))
                end
    "#{base_text.rstrip}\n"
  end

  private

  def name
    @col.name
  end

  def comment
    @col.comment
  end

  def limit
    @col.limit
  end

  def bigint?
    @col.respond_to?(:bigint?) && @col.bigint?
  end

  def array?
    @col.respond_to?(:array) && @col.array
  end

  def decimal?
    type == 'decimal'
  end

  def spatial?
    type == 'spatial'
  end

  def null?
    @col.null
  end

  def unsigned?
    @col.respond_to?(:unsigned?) && @col.unsigned?
  end

  def precision
    @col.precision
  end

  def scale
    @col.scale
  end

  def type
    @type ||= if bigint?
                'bigint'
              else
                (@col.type || @col.sql_type).to_s
              end
  end

  def attrs(options)
    attrs = []
    attrs << "default(#{schema_default})" if mark_as_default?(options)
    attrs << 'unsigned' if unsigned?
    attrs << 'not null' unless null?
    attrs << 'primary key' if primary_key?
    attrs << "(#{limit.join(', ')})" if !decimal? && !spatial? && limit && limit.is_a?(Array)

    # Check out if we got an array column
    attrs << 'is an Array' if array?

    # Check out if we got a geometric column
    # and print the type and SRID
    if geometry_type?
      attrs << geometry_type_info
    elsif geometric_type?
      attrs << geometric_type_info
    end

    # Check if the column has indices and print "indexed" if true
    # If the index includes another column, print it too.
    if options[:simple_indexes] && @model_class.table_exists? # Check out if this column is indexed
      indices = @model_class.indexes_from_table
      if indices
        indices.select { |ind| ind.columns.include?(name) }.sort_by(&:name).each do |ind|
          next if ind.columns.is_a?(String)
          ind = ind.columns.reject! { |i| i == name }
          attrs << (ind.empty? ? 'indexed' : "indexed => [#{ind.join(', ')}]")
        end
      end
    end

    attrs
  end

  def col_type_to_display(options)
    return "#{type}(#{precision}, #{scale})" if decimal?
    return type if spatial?
    return type unless limit
    return type if limit.is_a?(Array)
    return type if hide_limit?(options)
    "#{type}(#{limit})"
  end

  def mark_as_default?(options)
    !@col.default.nil? && !hide_default?(options)
  end

  def hide_default?(options)
    excludes =
      if options[:hide_default_column_types].blank?
        NO_DEFAULT_COL_TYPES
      else
        options[:hide_default_column_types].split(',')
      end

    excludes.include?(type)
  end

  def schema_default
    quote(@model_class.column_defaults(name))
  end

  # Simple quoting for the default column value
  def quote(value)
    case value
    when NilClass                 then 'NULL'
    when TrueClass                then 'TRUE'
    when FalseClass               then 'FALSE'
    when Float, Integer           then value.to_s
      # BigDecimals need to be output in a non-normalized form and quoted.
    when BigDecimal               then value.to_s('F')
    when Array                    then value.map { |v| quote(v) }
    else
      value.inspect
    end
  end

  def primary_key?
    return false unless @model_class.primary_key?

    if @model_class.primary_key.is_a?(Array)
      @model_class.primary_key.collect(&:to_sym).include?(name.to_sym)
    else
      name.to_sym == @model_class.primary_key.to_sym
    end
  end

  def hide_limit?(options)
    excludes =
      if options[:hide_limit_column_types].blank?
        NO_LIMIT_COL_TYPES
      else
        options[:hide_limit_column_types].split(',')
      end

    excludes.include?(type)
  end

  def geometry_type?
    @col.respond_to?(:geometry_type)
  end

  def geometric_type?
    @col.respond_to?(:geometric_type) && @col.geometric_type.present?
  end

  def kind_of_geometry?
    geometry_type? || geometric_type?
  end

  def geometry_type
    geometry_type? ? @col.geometry_type : nil
  end

  def geometric_type
    geometric_type? ? @col.geometric_type.to_s.downcase : nil
  end

  def geometry_type_info
    "#{geometry_type}, #{srid}"
  end

  def geometric_type_info
    "#{geometric_type}, #{col.srid}"
  end

  def srid
    kind_of_geometry? ? @col.srid : nil
  end

  def name_to_output(options)
    if with_comments?(options)
      "#{name}(#{comment})"
    else
      name
    end
  end

  def with_comments?(options)
    options[:with_comment] &&
      @model_class.columns.first.respond_to?(:comment) &&
      @model_class.columns.any? { |col| !col.comment.nil? } &&
      comment
  end
end
