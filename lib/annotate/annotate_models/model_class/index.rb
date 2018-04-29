class AnnotateModels::ModelClass::Index
  INDEX_CLAUSES = {
    unique: {
      default: 'UNIQUE',
      markdown: '_unique_'
    },
    where: {
      default: 'WHERE',
      markdown: '_where_'
    },
    using: {
      default: 'USING',
      markdown: '_using_'
    }
  }.freeze

  def initialize(index)
    @index = index
  end

  def to_s(max_size, options)
    if options[:format_markdown]
      final_index_string_in_markdown
    else
      final_index_string(max_size)
    end
  end

  private

  def name
    @index.name
  end

  def unique?
    @index.unique
  end

  def columns
    Array(@index.columns)
  end

  def final_index_string_in_markdown
    details = sprintf(
      "%s%s%s",
      index_unique_info(:markdown),
      index_where_info(:markdown),
      index_using_info(:markdown)
    ).strip

    details = " (#{details})" unless details.blank?

    sprintf(
      "# * `%s`%s:\n#     * **`%s`**\n",
      name,
      details,
      index_columns_info.join("`**\n#     * **`")
    )
  end

  def final_index_string(max_size)
    sprintf(
      "#  %-#{max_size}.#{max_size}s %s%s%s%s",
      name,
      "(#{index_columns_info.join(',')})",
      index_unique_info,
      index_where_info,
      index_using_info
    ).rstrip + "\n"
  end

  def index_unique_info(format = :default)
    return '' unless unique?
    " #{INDEX_CLAUSES[:unique][format]}"
  end

  def index_where_info(format = :default)
    value = @index.try(:where).try(:to_s)
    return '' if value.blank?
    " #{INDEX_CLAUSES[:where][format]} #{value}"
  end

  def index_using_info(format = :default)
    value = @index.try(:using).try(:to_sym)
    return '' if value.blank?
    return '' if value == :btree
    " #{INDEX_CLAUSES[:using][format]} #{value}"
  end

  def index_columns_info
    columns.map do |col|
      if @index.try(:orders) && @index.orders[col.to_s]
        "#{col} #{@index.orders[col.to_s].upcase}"
      else
        col.to_s.gsub("\r", '\r').gsub("\n", '\n')
      end
    end
  end
end
