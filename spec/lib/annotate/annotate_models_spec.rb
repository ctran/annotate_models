# encoding: utf-8
require_relative '../../spec_helper'
require 'annotate/annotate_models'
require 'annotate/active_record_patch'
require 'active_support/core_ext/string'
require 'files'

describe AnnotateModels do # rubocop:disable Metrics/BlockLength
  def mock_index(name, params = {})
    double('IndexKeyDefinition',
           name:          name,
           columns:       params[:columns] || [],
           unique:        params[:unique] || false,
           orders:        params[:orders] || {},
           where:         params[:where],
           using:         params[:using])
  end

  def mock_foreign_key(name, from_column, to_table, to_column = 'id', constraints = {})
    double('ForeignKeyDefinition',
           name:         name,
           column:       from_column,
           to_table:     to_table,
           primary_key:  to_column,
           on_delete:    constraints[:on_delete],
           on_update:    constraints[:on_update])
  end

  def mock_connection(indexes = [], foreign_keys = [])
    double('Conn',
           indexes:      indexes,
           foreign_keys: foreign_keys,
           supports_foreign_keys?: true)
  end

  def mock_class(table_name, primary_key, columns, indexes = [], foreign_keys = [])
    options = {
      connection:       mock_connection(indexes, foreign_keys),
      table_exists?:    true,
      table_name:       table_name,
      primary_key:      primary_key,
      column_names:     columns.map { |col| col.name.to_s },
      columns:          columns,
      column_defaults:  Hash[columns.map { |col| [col.name, col.default] }],
      table_name_prefix: ''
    }

    double('An ActiveRecord class', options)
  end

  def mock_column(name, type, options = {})
    default_options = {
      limit: nil,
      null: false,
      default: nil,
      sql_type: type
    }

    stubs = default_options.dup
    stubs.merge!(options)
    stubs[:name] = name
    stubs[:type] = type

    double('Column', stubs)
  end

  it { expect(AnnotateModels.quote(nil)).to eql('NULL') }
  it { expect(AnnotateModels.quote(true)).to eql('TRUE') }
  it { expect(AnnotateModels.quote(false)).to eql('FALSE') }
  it { expect(AnnotateModels.quote(25)).to eql('25') }
  it { expect(AnnotateModels.quote(25.6)).to eql('25.6') }
  it { expect(AnnotateModels.quote(1e-20)).to eql('1.0e-20') }
  it { expect(AnnotateModels.quote(BigDecimal('1.2'))).to eql('1.2') }
  it { expect(AnnotateModels.quote([BigDecimal('1.2')])).to eql(['1.2']) }

  describe '#parse_options' do
    let(:options) do
      {
        root_dir: '/root',
        model_dir: 'app/models,app/one,  app/two   ,,app/three'
      }
    end

    it 'sets @root_dir' do
      AnnotateModels.send(:parse_options, options)
      expect(AnnotateModels.instance_variable_get(:@root_dir)).to eq('/root')
    end

    it 'sets @model_dir separated with a comma' do
      AnnotateModels.send(:parse_options, options)
      expected = [
        'app/models',
        'app/one',
        'app/two',
        'app/three'
      ]
      expect(AnnotateModels.instance_variable_get(:@model_dir)).to eq(expected)
    end
  end

  it 'should get schema info with default options' do
    klass = mock_class(:users,
                       :id,
                       [
                         mock_column(:id, :integer, limit: 8),
                         mock_column(:name, :string, limit: 50),
                         mock_column(:notes, :text, limit: 55)
                       ])

    expect(AnnotateModels.get_schema_info(klass, 'Schema Info')).to eql(<<-EOS)
# Schema Info
#
# Table name: users
#
#  id    :integer          not null, primary key
#  name  :string(50)       not null
#  notes :text(55)         not null
#
EOS
  end

  it 'should get schema info even if the primary key is not set' do
    klass = mock_class(:users,
                       nil,
                       [
                         mock_column(:id, :integer),
                         mock_column(:name, :string, limit: 50)
                       ])

    expect(AnnotateModels.get_schema_info(klass, 'Schema Info')).to eql(<<-EOS)
# Schema Info
#
# Table name: users
#
#  id   :integer          not null
#  name :string(50)       not null
#
EOS
  end

  it 'should get schema info even if the primary key is array, if using composite_primary_keys' do
    klass = mock_class(:users,
                       [:a_id, :b_id],
                       [
                         mock_column(:a_id, :integer),
                         mock_column(:b_id, :integer),
                         mock_column(:name, :string, limit: 50)
                       ])

    expect(AnnotateModels.get_schema_info(klass, 'Schema Info')).to eql(<<-EOS)
# Schema Info
#
# Table name: users
#
#  a_id :integer          not null, primary key
#  b_id :integer          not null, primary key
#  name :string(50)       not null
#
EOS
  end

  it 'should get schema info with enum type' do
    klass = mock_class(:users,
                       nil,
                       [
                         mock_column(:id, :integer),
                         mock_column(:name, :enum, limit: [:enum1, :enum2])
                       ])

    expect(AnnotateModels.get_schema_info(klass, 'Schema Info')).to eql(<<-EOS)
# Schema Info
#
# Table name: users
#
#  id   :integer          not null
#  name :enum             not null, (enum1, enum2)
#
EOS
  end

  it 'should get schema info with unsigned' do
    klass = mock_class(:users,
                       nil,
                       [
                         mock_column(:id, :integer),
                         mock_column(:integer, :integer, unsigned?: true),
                         mock_column(:bigint,  :integer, unsigned?: true, bigint?: true),
                         mock_column(:bigint,  :bigint,  unsigned?: true),
                         mock_column(:float,   :float,   unsigned?: true),
                         mock_column(:decimal, :decimal, unsigned?: true, precision: 10, scale: 2),
                       ])

    expect(AnnotateModels.get_schema_info(klass, 'Schema Info')).to eql(<<-EOS)
# Schema Info
#
# Table name: users
#
#  id      :integer          not null
#  integer :integer          unsigned, not null
#  bigint  :bigint           unsigned, not null
#  bigint  :bigint           unsigned, not null
#  float   :float            unsigned, not null
#  decimal :decimal(10, 2)   unsigned, not null
#
EOS
  end

  it 'should get schema info for integer and boolean with default' do
    klass = mock_class(:users,
                       :id,
                       [
                         mock_column(:id, :integer),
                         mock_column(:size, :integer, default: 20),
                         mock_column(:flag, :boolean, default: false)
                       ])
    expect(AnnotateModels.get_schema_info(klass, 'Schema Info')).to eql(<<-EOS)
# Schema Info
#
# Table name: users
#
#  id   :integer          not null, primary key
#  size :integer          default(20), not null
#  flag :boolean          default(FALSE), not null
#
EOS
  end

  it 'sets correct default value for integer column when ActiveRecord::Enum is used' do
    klass = mock_class(:users,
                       :id,
                       [
                         mock_column(:id, :integer),
                         mock_column(:status, :integer, default: 0)
                       ])
    # column_defaults may be overritten when ActiveRecord::Enum is used, e.g:
    # class User < ActiveRecord::Base
    #   enum status: [ :disabled, :enabled ]
    # end
    allow(klass).to receive(:column_defaults).and_return('id' => nil, 'status' => 'disabled')
    expect(AnnotateModels.get_schema_info(klass, 'Schema Info')).to eql(<<-EOS)
# Schema Info
#
# Table name: users
#
#  id     :integer          not null, primary key
#  status :integer          default(0), not null
#
EOS
  end

  it 'should get foreign key info' do
    klass = mock_class(:users,
                       :id,
                       [
                         mock_column(:id, :integer),
                         mock_column(:foreign_thing_id, :integer)
                       ],
                       [],
                       [
                         mock_foreign_key('fk_rails_cf2568e89e',
                                          'foreign_thing_id',
                                          'foreign_things'),
                         mock_foreign_key('custom_fk_name',
                                          'other_thing_id',
                                          'other_things'),
                         mock_foreign_key('fk_rails_a70234b26c',
                                          'third_thing_id',
                                          'third_things')
                       ])
    expect(AnnotateModels.get_schema_info(klass, 'Schema Info', show_foreign_keys: true)).to eql(<<-EOS)
# Schema Info
#
# Table name: users
#
#  id               :integer          not null, primary key
#  foreign_thing_id :integer          not null
#
# Foreign Keys
#
#  custom_fk_name  (other_thing_id => other_things.id)
#  fk_rails_...    (foreign_thing_id => foreign_things.id)
#  fk_rails_...    (third_thing_id => third_things.id)
#
EOS
  end

  it 'should get complete foreign key info' do
    klass = mock_class(:users,
                       :id,
                       [
                         mock_column(:id, :integer),
                         mock_column(:foreign_thing_id, :integer)
                       ],
                       [],
                       [
                         mock_foreign_key('fk_rails_cf2568e89e',
                                          'foreign_thing_id',
                                          'foreign_things'),
                         mock_foreign_key('custom_fk_name',
                                          'other_thing_id',
                                          'other_things'),
                         mock_foreign_key('fk_rails_a70234b26c',
                                          'third_thing_id',
                                          'third_things')
                       ])
    expect(AnnotateModels.get_schema_info(klass, 'Schema Info', show_foreign_keys: true, show_complete_foreign_keys: true)).to eql(<<-EOS)
# Schema Info
#
# Table name: users
#
#  id               :integer          not null, primary key
#  foreign_thing_id :integer          not null
#
# Foreign Keys
#
#  custom_fk_name       (other_thing_id => other_things.id)
#  fk_rails_a70234b26c  (third_thing_id => third_things.id)
#  fk_rails_cf2568e89e  (foreign_thing_id => foreign_things.id)
#
    EOS
  end

  it 'should get foreign key info if on_delete/on_update options present' do
    klass = mock_class(:users,
                       :id,
                       [
                         mock_column(:id, :integer),
                         mock_column(:foreign_thing_id, :integer)
                       ],
                       [],
                       [
                         mock_foreign_key('fk_rails_02e851e3b7',
                                          'foreign_thing_id',
                                          'foreign_things',
                                          'id',
                                          on_delete: 'on_delete_value',
                                          on_update: 'on_update_value')
                       ])
    expect(AnnotateModels.get_schema_info(klass, 'Schema Info', show_foreign_keys: true)).to eql(<<-EOS)
# Schema Info
#
# Table name: users
#
#  id               :integer          not null, primary key
#  foreign_thing_id :integer          not null
#
# Foreign Keys
#
#  fk_rails_...  (foreign_thing_id => foreign_things.id) ON DELETE => on_delete_value ON UPDATE => on_update_value
#
EOS
  end

  it 'should get indexes keys' do
    klass = mock_class(:users,
                       :id,
                       [
                         mock_column(:id, :integer),
                         mock_column(:foreign_thing_id, :integer)
                       ], [mock_index('index_rails_02e851e3b7', columns: ['id']),
                       mock_index('index_rails_02e851e3b8', columns: ['foreign_thing_id'])])
    expect(AnnotateModels.get_schema_info(klass, 'Schema Info', show_indexes: true)).to eql(<<-EOS)
# Schema Info
#
# Table name: users
#
#  id               :integer          not null, primary key
#  foreign_thing_id :integer          not null
#
# Indexes
#
#  index_rails_02e851e3b7  (id)
#  index_rails_02e851e3b8  (foreign_thing_id)
#
EOS
  end

  it 'should get ordered indexes keys' do
    klass = mock_class(:users,
                       :id,
                       [
                         mock_column("id", :integer),
                         mock_column("firstname", :string),
                         mock_column("surname", :string),
                         mock_column("value", :string)
                       ],
                       [
                         mock_index('index_rails_02e851e3b7', columns: ['id']),
                         mock_index('index_rails_02e851e3b8',
                                    columns: %w(firstname surname value),
                                    orders: { 'surname' => :asc, 'value' => :desc })
                       ])
    expect(AnnotateModels.get_schema_info(klass, 'Schema Info', show_indexes: true)).to eql(<<-EOS)
# Schema Info
#
# Table name: users
#
#  id        :integer          not null, primary key
#  firstname :string           not null
#  surname   :string           not null
#  value     :string           not null
#
# Indexes
#
#  index_rails_02e851e3b7  (id)
#  index_rails_02e851e3b8  (firstname,surname ASC,value DESC)
#
EOS
  end

  it 'should get indexes keys with where clause' do
    klass = mock_class(:users,
                       :id,
                       [
                         mock_column("id", :integer),
                         mock_column("firstname", :string),
                         mock_column("surname", :string),
                         mock_column("value", :string)
                       ],
                       [
                         mock_index('index_rails_02e851e3b7', columns: ['id']),
                         mock_index('index_rails_02e851e3b8',
                                    columns: %w(firstname surname),
                                    where: 'value IS NOT NULL')
                       ])
    expect(AnnotateModels.get_schema_info(klass, 'Schema Info', show_indexes: true)).to eql(<<-EOS)
# Schema Info
#
# Table name: users
#
#  id        :integer          not null, primary key
#  firstname :string           not null
#  surname   :string           not null
#  value     :string           not null
#
# Indexes
#
#  index_rails_02e851e3b7  (id)
#  index_rails_02e851e3b8  (firstname,surname) WHERE value IS NOT NULL
#
EOS
  end

  it 'should get indexes keys with using clause other than btree' do
    klass = mock_class(:users,
                       :id,
                       [
                         mock_column("id", :integer),
                         mock_column("firstname", :string),
                         mock_column("surname", :string),
                         mock_column("value", :string)
                       ],
                       [
                         mock_index('index_rails_02e851e3b7', columns: ['id']),
                         mock_index('index_rails_02e851e3b8',
                                    columns: %w(firstname surname),
                                    using: 'hash')
                       ])
    expect(AnnotateModels.get_schema_info(klass, 'Schema Info', show_indexes: true)).to eql(<<-EOS)
# Schema Info
#
# Table name: users
#
#  id        :integer          not null, primary key
#  firstname :string           not null
#  surname   :string           not null
#  value     :string           not null
#
# Indexes
#
#  index_rails_02e851e3b7  (id)
#  index_rails_02e851e3b8  (firstname,surname) USING hash
#
EOS
  end

  it 'should get simple indexes keys' do
    klass = mock_class(:users,
                       :id,
                       [
                         mock_column(:id, :integer),
                         mock_column(:foreign_thing_id, :integer)
                       ],
                       [
                         mock_index('index_rails_02e851e3b7', columns: ['id']),
                         mock_index('index_rails_02e851e3b8',
                                    columns: ['foreign_thing_id'],
                                    orders: { 'foreign_thing_id' => :desc })
                       ])
    expect(AnnotateModels.get_schema_info(klass, 'Schema Info', simple_indexes: true)).to eql(<<-EOS)
# Schema Info
#
# Table name: users
#
#  id               :integer          not null, primary key
#  foreign_thing_id :integer          not null
#
EOS
  end

  it 'should get simple indexes keys if one is in string form' do
    klass = mock_class(:users,
                       :id,
                       [
                         mock_column("id", :integer),
                         mock_column("name", :string)
                       ], [mock_index('index_rails_02e851e3b7', columns: ['id']),
                       mock_index('index_rails_02e851e3b8', columns: 'LOWER(name)')])
    expect(AnnotateModels.get_schema_info(klass, 'Schema Info', simple_indexes: true)).to eql(<<-EOS)
# Schema Info
#
# Table name: users
#
#  id   :integer          not null, primary key, indexed
#  name :string           not null
#
EOS
  end

  it 'should not crash getting indexes keys' do
    klass = mock_class(:users,
                       :id,
                       [
                         mock_column(:id, :integer),
                         mock_column(:foreign_thing_id, :integer)
                       ], [])
    expect(AnnotateModels.get_schema_info(klass, 'Schema Info', show_indexes: true)).to eql(<<-EOS)
# Schema Info
#
# Table name: users
#
#  id               :integer          not null, primary key
#  foreign_thing_id :integer          not null
#
EOS
  end

  it 'should get schema info as RDoc' do
    klass = mock_class(:users,
                       :id,
                       [
                         mock_column(:id, :integer),
                         mock_column(:name, :string, limit: 50)
                       ])
    expect(AnnotateModels.get_schema_info(klass, AnnotateModels::PREFIX, format_rdoc: true)).to eql(<<-EOS)
# #{AnnotateModels::PREFIX}
#
# Table name: users
#
# *id*::   <tt>integer, not null, primary key</tt>
# *name*:: <tt>string(50), not null</tt>
#--
# #{AnnotateModels::END_MARK}
#++
EOS
  end

  it 'should get schema info as Markdown' do
    klass = mock_class(:users,
                       :id,
                       [
                         mock_column(:id, :integer),
                         mock_column(:name, :string, limit: 50)
                       ])
    expect(AnnotateModels.get_schema_info(klass, AnnotateModels::PREFIX, format_markdown: true)).to eql(<<-EOS)
# #{AnnotateModels::PREFIX}
#
# Table name: `users`
#
# ### Columns
#
# Name        | Type               | Attributes
# ----------- | ------------------ | ---------------------------
# **`id`**    | `integer`          | `not null, primary key`
# **`name`**  | `string(50)`       | `not null`
#
EOS
  end

  it 'should get schema info as Markdown with foreign keys' do
    klass = mock_class(:users,
                       :id,
                       [
                         mock_column(:id, :integer),
                         mock_column(:foreign_thing_id, :integer)
                       ],
                       [],
                       [
                         mock_foreign_key('fk_rails_02e851e3b7',
                                          'foreign_thing_id',
                                          'foreign_things',
                                          'id',
                                          on_delete: 'on_delete_value',
                                          on_update: 'on_update_value')
                       ])
    expect(AnnotateModels.get_schema_info(klass, AnnotateModels::PREFIX, format_markdown: true, show_foreign_keys: true)).to eql(<<-EOS)
# #{AnnotateModels::PREFIX}
#
# Table name: `users`
#
# ### Columns
#
# Name                    | Type               | Attributes
# ----------------------- | ------------------ | ---------------------------
# **`id`**                | `integer`          | `not null, primary key`
# **`foreign_thing_id`**  | `integer`          | `not null`
#
# ### Foreign Keys
#
# * `fk_rails_...` (_ON DELETE => on_delete_value ON UPDATE => on_update_value_):
#     * **`foreign_thing_id => foreign_things.id`**
#
EOS
  end

  it 'should get schema info as Markdown with indexes' do
    klass = mock_class(:users,
                       :id,
                       [
                         mock_column(:id, :integer),
                         mock_column(:name, :string, limit: 50)
                       ],
                       [
                         mock_index('index_rails_02e851e3b7', columns: ['id']),
                         mock_index('index_rails_02e851e3b8',
                                    columns: ['foreign_thing_id'])
                       ])
    expect(AnnotateModels.get_schema_info(klass, AnnotateModels::PREFIX, format_markdown: true, show_indexes: true)).to eql(<<-EOS)
# #{AnnotateModels::PREFIX}
#
# Table name: `users`
#
# ### Columns
#
# Name        | Type               | Attributes
# ----------- | ------------------ | ---------------------------
# **`id`**    | `integer`          | `not null, primary key`
# **`name`**  | `string(50)`       | `not null`
#
# ### Indexes
#
# * `index_rails_02e851e3b7`:
#     * **`id`**
# * `index_rails_02e851e3b8`:
#     * **`foreign_thing_id`**
#
EOS
  end

  it 'should get schema info as Markdown with unique indexes' do
    klass = mock_class(:users,
                       :id,
                       [
                         mock_column(:id, :integer),
                         mock_column(:name, :string, limit: 50)
                       ],
                       [
                         mock_index('index_rails_02e851e3b7', columns: ['id']),
                         mock_index('index_rails_02e851e3b8',
                                    columns: ['foreign_thing_id'],
                                    unique: true)
                       ])
    expect(AnnotateModels.get_schema_info(klass, AnnotateModels::PREFIX, format_markdown: true, show_indexes: true)).to eql(<<-EOS)
# #{AnnotateModels::PREFIX}
#
# Table name: `users`
#
# ### Columns
#
# Name        | Type               | Attributes
# ----------- | ------------------ | ---------------------------
# **`id`**    | `integer`          | `not null, primary key`
# **`name`**  | `string(50)`       | `not null`
#
# ### Indexes
#
# * `index_rails_02e851e3b7`:
#     * **`id`**
# * `index_rails_02e851e3b8` (_unique_):
#     * **`foreign_thing_id`**
#
EOS
  end

  it 'should get schema info as Markdown with ordered indexes' do
    klass = mock_class(:users,
                       :id,
                       [
                         mock_column(:id, :integer),
                         mock_column(:name, :string, limit: 50)
                       ],
                       [
                         mock_index('index_rails_02e851e3b7', columns: ['id']),
                         mock_index('index_rails_02e851e3b8',
                                    columns: ['foreign_thing_id'],
                                    orders: { 'foreign_thing_id' => :desc })
                       ])
    expect(AnnotateModels.get_schema_info(klass, AnnotateModels::PREFIX, format_markdown: true, show_indexes: true)).to eql(<<-EOS)
# #{AnnotateModels::PREFIX}
#
# Table name: `users`
#
# ### Columns
#
# Name        | Type               | Attributes
# ----------- | ------------------ | ---------------------------
# **`id`**    | `integer`          | `not null, primary key`
# **`name`**  | `string(50)`       | `not null`
#
# ### Indexes
#
# * `index_rails_02e851e3b7`:
#     * **`id`**
# * `index_rails_02e851e3b8`:
#     * **`foreign_thing_id DESC`**
#
EOS
  end

  it 'should get schema info as Markdown with indexes with WHERE clause' do
    klass = mock_class(:users,
                       :id,
                       [
                         mock_column(:id, :integer),
                         mock_column(:name, :string, limit: 50)
                       ],
                       [
                         mock_index('index_rails_02e851e3b7', columns: ['id']),
                         mock_index('index_rails_02e851e3b8',
                                    columns: ['foreign_thing_id'],
                                    unique: true,
                                    where: 'name IS NOT NULL')
                       ])
    expect(AnnotateModels.get_schema_info(klass, AnnotateModels::PREFIX, format_markdown: true, show_indexes: true)).to eql(<<-EOS)
# #{AnnotateModels::PREFIX}
#
# Table name: `users`
#
# ### Columns
#
# Name        | Type               | Attributes
# ----------- | ------------------ | ---------------------------
# **`id`**    | `integer`          | `not null, primary key`
# **`name`**  | `string(50)`       | `not null`
#
# ### Indexes
#
# * `index_rails_02e851e3b7`:
#     * **`id`**
# * `index_rails_02e851e3b8` (_unique_ _where_ name IS NOT NULL):
#     * **`foreign_thing_id`**
#
EOS
  end

  it 'should get schema info as Markdown with indexes with using clause other than btree' do
    klass = mock_class(:users,
                       :id,
                       [
                         mock_column(:id, :integer),
                         mock_column(:name, :string, limit: 50)
                       ],
                       [
                         mock_index('index_rails_02e851e3b7', columns: ['id']),
                         mock_index('index_rails_02e851e3b8',
                                    columns: ['foreign_thing_id'],
                                    using: 'hash')
                       ])
    expect(AnnotateModels.get_schema_info(klass, AnnotateModels::PREFIX, format_markdown: true, show_indexes: true)).to eql(<<-EOS)
# #{AnnotateModels::PREFIX}
#
# Table name: `users`
#
# ### Columns
#
# Name        | Type               | Attributes
# ----------- | ------------------ | ---------------------------
# **`id`**    | `integer`          | `not null, primary key`
# **`name`**  | `string(50)`       | `not null`
#
# ### Indexes
#
# * `index_rails_02e851e3b7`:
#     * **`id`**
# * `index_rails_02e851e3b8` (_using_ hash):
#     * **`foreign_thing_id`**
#
EOS
  end

  describe '#set_defaults' do
    it 'should default show_complete_foreign_keys to false' do
      expect(Annotate.true?(ENV['show_complete_foreign_keys'])).to be(false)
    end

    it 'should be able to set show_complete_foreign_keys to true' do
      Annotate.set_defaults('show_complete_foreign_keys' => 'true')
      expect(Annotate.true?(ENV['show_complete_foreign_keys'])).to be(true)
    end

    after :each do
      ENV.delete('show_complete_foreign_keys')
    end
  end

  describe '#files_by_pattern' do
    subject { AnnotateModels.files_by_pattern(root_directory, pattern_type, options) }

    context 'when pattern_type=additional_file_patterns' do
      let(:pattern_type) { 'additional_file_patterns' }
      let(:root_directory) { nil }

      context 'with additional_file_patterns' do
        let(:additional_file_patterns) do
          [
            '%PLURALIZED_MODEL_NAME%/**/*.rb',
            '%PLURALIZED_MODEL_NAME%/*_form'
          ]
        end

        let(:options) { { additional_file_patterns: additional_file_patterns } }

        it do
          expect(subject).to eq(additional_file_patterns)
        end
      end

      context 'without additional_file_patterns' do
        let(:options) { {} }

        it do
          expect(subject).to eq([])
        end
      end
    end
  end

  describe '#get_patterns' do
    subject { AnnotateModels.get_patterns(options, pattern_type) }

    context 'when pattern_type=additional_file_patterns' do
      let(:pattern_type) { 'additional_file_patterns' }

      context 'with additional_file_patterns' do
        let(:additional_file_patterns) do
          [
            '/%PLURALIZED_MODEL_NAME%/**/*.rb',
            '/bar/%PLURALIZED_MODEL_NAME%/*_form'
          ]
        end

        let(:options) { { additional_file_patterns: additional_file_patterns } }

        it do
          expect(subject).to eq(additional_file_patterns)
        end
      end

      context 'without additional_file_patterns' do
        let(:options) { {} }

        it do
          expect(subject).to eq([])
        end
      end
    end
  end

  describe '#get_schema_info with custom options' do
    def self.when_called_with(options = {})
      expected = options.delete(:returns)
      default_columns = [
        [:id, :integer, { limit: 8 }],
        [:active, :boolean, { limit: 1 }],
        [:name, :string, { limit: 50 }],
        [:notes, :text, { limit: 55 }]
      ]

      it "should work with options = #{options}" do
        with_columns = (options.delete(:with_columns) || default_columns).map do |column|
          mock_column(column[0], column[1], column[2])
        end

        klass = mock_class(:users, :id, with_columns)

        schema_info = AnnotateModels.get_schema_info(klass, 'Schema Info', options)
        expect(schema_info).to eql(expected)
      end
    end

    describe 'hide_limit_column_types option' do
      when_called_with hide_limit_column_types: '', returns: <<-EOS.strip_heredoc
        # Schema Info
        #
        # Table name: users
        #
        #  id     :integer          not null, primary key
        #  active :boolean          not null
        #  name   :string(50)       not null
        #  notes  :text(55)         not null
        #
      EOS

      when_called_with hide_limit_column_types: 'integer,boolean', returns:
        <<-EOS.strip_heredoc
        # Schema Info
        #
        # Table name: users
        #
        #  id     :integer          not null, primary key
        #  active :boolean          not null
        #  name   :string(50)       not null
        #  notes  :text(55)         not null
        #
      EOS

      when_called_with hide_limit_column_types: 'integer,boolean,string,text',
                       returns:
        <<-EOS.strip_heredoc
        # Schema Info
        #
        # Table name: users
        #
        #  id     :integer          not null, primary key
        #  active :boolean          not null
        #  name   :string           not null
        #  notes  :text             not null
        #
      EOS
    end

    describe 'hide_default_column_types option' do
      mocked_columns_without_id = [
        [:profile, :json, default: {}],
        [:settings, :jsonb, default: {}],
        [:parameters, :hstore, default: {}]
      ]

      when_called_with hide_default_column_types: '',
                       with_columns: mocked_columns_without_id,
                       returns:
        <<-EOS.strip_heredoc
        # Schema Info
        #
        # Table name: users
        #
        #  profile    :json             not null
        #  settings   :jsonb            not null
        #  parameters :hstore           not null
        #
      EOS

      when_called_with hide_default_column_types: 'skip',
                       with_columns: mocked_columns_without_id,
                       returns:
        <<-EOS.strip_heredoc
        # Schema Info
        #
        # Table name: users
        #
        #  profile    :json             default({}), not null
        #  settings   :jsonb            default({}), not null
        #  parameters :hstore           default({}), not null
        #
      EOS

      when_called_with hide_default_column_types: 'json',
                       with_columns: mocked_columns_without_id,
                       returns:
        <<-EOS.strip_heredoc
        # Schema Info
        #
        # Table name: users
        #
        #  profile    :json             not null
        #  settings   :jsonb            default({}), not null
        #  parameters :hstore           default({}), not null
        #
      EOS
    end

    describe 'classified_sort option' do
      mocked_columns_without_id = [
        [:active, :boolean, { limit: 1 }],
        [:name, :string, { limit: 50 }],
        [:notes, :text, { limit: 55 }]
      ]

      when_called_with classified_sort: 'yes',
                       with_columns: mocked_columns_without_id, returns:
        <<-EOS.strip_heredoc
        # Schema Info
        #
        # Table name: users
        #
        #  active :boolean          not null
        #  name   :string(50)       not null
        #  notes  :text(55)         not null
        #
      EOS
    end

    describe 'with_comment option' do
      mocked_columns_with_comment = [
        [:id,         :integer, { limit: 8,  comment: 'ID' }],
        [:active,     :boolean, { limit: 1,  comment: 'Active' }],
        [:name,       :string,  { limit: 50, comment: 'Name' }],
        [:notes,      :text,    { limit: 55, comment: 'Notes' }],
        [:no_comment, :text,    { limit: 20, comment: nil }]
      ]

      when_called_with with_comment: 'yes',
                       with_columns: mocked_columns_with_comment, returns:
        <<-EOS.strip_heredoc
        # Schema Info
        #
        # Table name: users
        #
        #  id(ID)         :integer          not null, primary key
        #  active(Active) :boolean          not null
        #  name(Name)     :string(50)       not null
        #  notes(Notes)   :text(55)         not null
        #  no_comment     :text(20)         not null
        #
    EOS

      mocked_columns_with_multibyte_comment = [
        [:id,         :integer, { limit: 8,  comment: 'ＩＤ' }],
        [:active,     :boolean, { limit: 1,  comment: 'ＡＣＴＩＶＥ' }],
        [:name,       :string,  { limit: 50, comment: 'ＮＡＭＥ' }],
        [:notes,      :text,    { limit: 55, comment: 'ＮＯＴＥＳ' }],
        [:cyrillic,   :text,    { limit: 30, comment: 'Кириллица' }],
        [:japanese,   :text,    { limit: 60, comment: '熊本大学　イタリア　宝島' }],
        [:arabic,     :text,    { limit: 20, comment: 'لغة' }],
        [:no_comment, :text,    { limit: 20, comment: nil }],
        [:location,   :geometry_collection, { limit: nil, comment: nil }]
      ]

      when_called_with with_comment: 'yes',
                       with_columns: mocked_columns_with_multibyte_comment, returns:
        <<-EOS.strip_heredoc
        # Schema Info
        #
        # Table name: users
        #
        #  id(ＩＤ)                           :integer          not null, primary key
        #  active(ＡＣＴＩＶＥ)               :boolean          not null
        #  name(ＮＡＭＥ)                     :string(50)       not null
        #  notes(ＮＯＴＥＳ)                  :text(55)         not null
        #  cyrillic(Кириллица)                :text(30)         not null
        #  japanese(熊本大学　イタリア　宝島) :text(60)         not null
        #  arabic(لغة)                        :text(20)         not null
        #  no_comment                         :text(20)         not null
        #  location                           :geometry_collect not null
        #
      EOS

      mocked_columns_with_geometries = [
        [:id,       :integer,  { limit: 8 }],
        [:active,   :boolean,  { default: false, null: false }],
        [:geometry, :geometry, {
          geometric_type: 'Geometry', srid: 4326,
          limit:          { srid: 4326, type: 'geometry' }
        }],
        [:location, :geography, {
          geometric_type: 'Point', srid: 0,
          limit:          { srid: 0, type: 'geometry' }
        }]
      ]

      when_called_with with_columns: mocked_columns_with_geometries, returns:
        <<-EOS.strip_heredoc
        # Schema Info
        #
        # Table name: users
        #
        #  id       :integer          not null, primary key
        #  active   :boolean          default(FALSE), not null
        #  geometry :geometry         not null, geometry, 4326
        #  location :geography        not null, point, 0
        #
      EOS

      it 'should get schema info as RDoc' do
        klass = mock_class(:users,
                           :id,
                           [
                             mock_column(:id, :integer, comment: 'ID'),
                             mock_column(:name, :string, limit: 50, comment: 'Name')
                           ])
        expect(AnnotateModels.get_schema_info(klass, AnnotateModels::PREFIX, format_rdoc: true, with_comment: true)).to eql(<<-EOS.strip_heredoc)
        # #{AnnotateModels::PREFIX}
        #
        # Table name: users
        #
        # *id(ID)*::     <tt>integer, not null, primary key</tt>
        # *name(Name)*:: <tt>string(50), not null</tt>
        #--
        # #{AnnotateModels::END_MARK}
        #++
        EOS
      end

      it 'should get schema info as Markdown with multibyte comment' do
        klass = mock_class(:users,
                           :id,
                           [
                             mock_column(:id, :integer, comment: 'ＩＤ'),
                             mock_column(:name, :string, limit: 50, comment: 'ＮＡＭＥ')
                           ])
        expect(AnnotateModels.get_schema_info(klass, AnnotateModels::PREFIX, format_markdown: true, with_comment: true)).to eql(<<-EOS.strip_heredoc)
        # #{AnnotateModels::PREFIX}
        #
        # Table name: `users`
        #
        # ### Columns
        #
        # Name                  | Type               | Attributes
        # --------------------- | ------------------ | ---------------------------
        # **`id(ＩＤ)`**        | `integer`          | `not null, primary key`
        # **`name(ＮＡＭＥ)`**  | `string(50)`       | `not null`
        #
        EOS
      end

      it 'should get schema info as Markdown' do
        klass = mock_class(:users,
                           :id,
                           [
                             mock_column(:id, :integer, comment: 'ID'),
                             mock_column(:name, :string, limit: 50, comment: 'Name')
                           ])
        expect(AnnotateModels.get_schema_info(klass, AnnotateModels::PREFIX, format_markdown: true, with_comment: true)).to eql(<<-EOS.strip_heredoc)
        # #{AnnotateModels::PREFIX}
        #
        # Table name: `users`
        #
        # ### Columns
        #
        # Name              | Type               | Attributes
        # ----------------- | ------------------ | ---------------------------
        # **`id(ID)`**      | `integer`          | `not null, primary key`
        # **`name(Name)`**  | `string(50)`       | `not null`
        #
        EOS
      end
    end
  end

  describe '#get_model_files' do
    subject { described_class.get_model_files(options) }

    before do
      ARGV.clear

      described_class.model_dir = [model_dir]
    end

    context 'when `model_dir` is valid' do
      let(:model_dir) do
        Files do
          file 'foo.rb'
          dir 'bar' do
            file 'baz.rb'
            dir 'qux' do
              file 'quux.rb'
            end
          end
          dir 'concerns' do
            file 'corge.rb'
          end
        end
      end

      context 'when the model files are not specified' do
        context 'when no option is specified' do
          let(:options) { {} }

          it 'returns all model files under `model_dir` directory' do
            is_expected.to contain_exactly(
              [model_dir, 'foo.rb'],
              [model_dir, File.join('bar', 'baz.rb')],
              [model_dir, File.join('bar', 'qux', 'quux.rb')]
            )
          end
        end

        context 'when `ignore_model_sub_dir` option is enabled' do
          let(:options) { { ignore_model_sub_dir: true } }

          it 'returns model files just below `model_dir` directory' do
            is_expected.to contain_exactly([model_dir, 'foo.rb'])
          end
        end
      end

      context 'when the model files are specified' do
        let(:additional_model_dir) { 'additional_model' }
        let(:model_files) do
          [
            File.join(model_dir, 'foo.rb'),
            "./#{File.join(additional_model_dir, 'corge/grault.rb')}" # Specification by relative path
          ]
        end

        before { ARGV.concat(model_files) }

        context 'when no option is specified' do
          let(:options) { {} }

          context 'when all the specified files are in `model_dir` directory' do
            before do
              described_class.model_dir << additional_model_dir
            end

            it 'returns specified files' do
              is_expected.to contain_exactly(
                [model_dir, 'foo.rb'],
                [additional_model_dir, 'corge/grault.rb']
              )
            end
          end

          context 'when a model file outside `model_dir` directory is specified' do
            it 'exits with the status code' do
              begin
                subject
                raise
              rescue SystemExit => e
                expect(e.status).to eq(1)
              end
            end
          end
        end

        context 'when `is_rake` option is enabled' do
          let(:options) { { is_rake: true } }

          it 'returns all model files under `model_dir` directory' do
            is_expected.to contain_exactly(
              [model_dir, 'foo.rb'],
              [model_dir, File.join('bar', 'baz.rb')],
              [model_dir, File.join('bar', 'qux', 'quux.rb')]
            )
          end
        end
      end
    end

    context 'when `model_dir` is invalid' do
      let(:model_dir) { '/not_exist_path' }
      let(:options) { {} }

      it 'exits with the status code' do
        begin
          subject
          raise
        rescue SystemExit => e
          expect(e.status).to eq(1)
        end
      end
    end
  end

  describe '#get_model_class' do
    require 'tmpdir'

    # TODO: use 'files' gem instead
    def create(file, body = 'hi')
      file_path = File.join(AnnotateModels.model_dir[0], file)
      FileUtils.mkdir_p(File.dirname(file_path))
      File.open(file_path, 'wb') do |f|
        f.puts(body)
      end
      file_path
    end

    def check_class_name(file, class_name)
      klass = AnnotateModels.get_model_class(File.join(AnnotateModels.model_dir[0], file))

      expect(klass).not_to eq(nil)
      expect(klass.name).to eq(class_name)
    end

    before :each do
      AnnotateModels.model_dir = Dir.mktmpdir 'annotate_models'
    end

    it 'should work' do
      create 'foo.rb', <<-EOS
        class Foo < ActiveRecord::Base
        end
      EOS
      check_class_name 'foo.rb', 'Foo'
    end

    it 'should find models with non standard capitalization' do
      create 'foo_with_capitals.rb', <<-EOS
        class FooWithCAPITALS < ActiveRecord::Base
        end
      EOS
      check_class_name 'foo_with_capitals.rb', 'FooWithCAPITALS'
    end

    it 'should find models inside modules' do
      create 'bar/foo_inside_bar.rb', <<-EOS
        module Bar
          class FooInsideBar < ActiveRecord::Base
          end
        end
      EOS
      check_class_name 'bar/foo_inside_bar.rb', 'Bar::FooInsideBar'
    end

    it 'should find AR model when duplicated by a nested model' do
      create 'foo.rb', <<-EOS
        class Foo < ActiveRecord::Base
        end
      EOS

      create 'bar/foo.rb', <<-EOS
        class Bar::Foo
        end
      EOS
      check_class_name 'bar/foo.rb', 'Bar::Foo'
      check_class_name 'foo.rb', 'Foo'
    end

    it 'should find AR model nested inside a class' do
      create 'voucher.rb', <<-EOS
        class Voucher < ActiveRecord::Base
        end
      EOS

      create 'voucher/foo.rb', <<-EOS
        class Voucher
          class Foo
          end
        end
      EOS

      check_class_name 'voucher.rb', 'Voucher'
      check_class_name 'voucher/foo.rb', 'Voucher::Foo'
    end

    it 'should not care about unknown macros' do
      create 'foo_with_macro.rb', <<-EOS
        class FooWithMacro < ActiveRecord::Base
          acts_as_awesome :yah
        end
      EOS
      check_class_name 'foo_with_macro.rb', 'FooWithMacro'
    end

    it 'should not care about known macros' do
      create('foo_with_known_macro.rb', <<-EOS)
        class FooWithKnownMacro < ActiveRecord::Base
          has_many :yah
        end
      EOS
      check_class_name 'foo_with_known_macro.rb', 'FooWithKnownMacro'
    end

    it 'should work with class names with ALL CAPS segments' do
      create('foo_with_capitals.rb', <<-EOS)
        class FooWithCAPITALS < ActiveRecord::Base
          acts_as_awesome :yah
          end
        EOS
      check_class_name 'foo_with_capitals.rb', 'FooWithCAPITALS'
    end

    it 'should not complain of invalid multibyte char (USASCII)' do
      create 'foo_with_utf8.rb', <<-EOS
        #encoding: utf-8
        class FooWithUtf8 < ActiveRecord::Base
          UTF8STRINGS = %w[résumé façon âge]
        end
      EOS
      check_class_name 'foo_with_utf8.rb', 'FooWithUtf8'
    end

    it 'should find models inside modules with non standard capitalization' do
      create 'bar/foo_inside_capitals_bar.rb', <<-EOS
        module BAR
          class FooInsideCapitalsBAR < ActiveRecord::Base
          end
        end
      EOS
      check_class_name 'bar/foo_inside_capitals_bar.rb', 'BAR::FooInsideCapitalsBAR'
    end

    it 'should find non-namespaced models inside subdirectories' do
      create 'bar/non_namespaced_foo_inside_bar.rb', <<-EOS
        class NonNamespacedFooInsideBar < ActiveRecord::Base
        end
      EOS
      check_class_name 'bar/non_namespaced_foo_inside_bar.rb', 'NonNamespacedFooInsideBar'
    end

    it 'should find non-namespaced models with non standard capitalization inside subdirectories' do
      create 'bar/non_namespaced_foo_with_capitals_inside_bar.rb', <<-EOS
        class NonNamespacedFooWithCapitalsInsideBar < ActiveRecord::Base
        end
      EOS
      check_class_name 'bar/non_namespaced_foo_with_capitals_inside_bar.rb', 'NonNamespacedFooWithCapitalsInsideBar'
    end

    it 'should allow known macros' do
      create('foo_with_known_macro.rb', <<-EOS)
        class FooWithKnownMacro < ActiveRecord::Base
          has_many :yah
        end
      EOS
      expect(capturing(:stderr) do
        check_class_name 'foo_with_known_macro.rb', 'FooWithKnownMacro'
      end).to eq('')
    end

    it 'should not require model files twice' do
      create 'loaded_class.rb', <<-EOS
        class LoadedClass < ActiveRecord::Base
          CONSTANT = 1
        end
      EOS
      path = File.expand_path('loaded_class', AnnotateModels.model_dir[0])
      Kernel.load "#{path}.rb"
      expect(Kernel).not_to receive(:require)

      expect(capturing(:stderr) do
        check_class_name 'loaded_class.rb', 'LoadedClass'
      end).to be_blank
    end

    it 'should not require model files twice which is inside a subdirectory' do
      dir = Array.new(8) { (0..9).to_a.sample(random: Random.new) }.join
      $LOAD_PATH.unshift(File.join(AnnotateModels.model_dir[0], dir))

      create "#{dir}/subdir_loaded_class.rb", <<-EOS
        class SubdirLoadedClass < ActiveRecord::Base
          CONSTANT = 1
        end
      EOS
      path = File.expand_path("#{dir}/subdir_loaded_class", AnnotateModels.model_dir[0])
      Kernel.load "#{path}.rb"
      expect(Kernel).not_to receive(:require)

      expect(capturing(:stderr) do
        check_class_name "#{dir}/subdir_loaded_class.rb", 'SubdirLoadedClass'
      end).to be_blank
    end
  end

  describe '#remove_annotation_of_file' do
    require 'tmpdir'

    def create(file, body = 'hi')
      path = File.join(@dir, file)
      File.open(path, 'w') do |f|
        f.puts(body)
      end

      path
    end

    def content(path)
      File.read(path)
    end

    before :each do
      @dir = Dir.mktmpdir 'annotate_models'
    end

    it 'should remove before annotate' do
      path = create 'before.rb', <<-EOS
# == Schema Information
#
# Table name: foo
#
#  id                  :integer         not null, primary key
#  created_at          :datetime
#  updated_at          :datetime
#

class Foo < ActiveRecord::Base
end
      EOS

      AnnotateModels.remove_annotation_of_file(path)

      expect(content(path)).to eq <<-EOS
class Foo < ActiveRecord::Base
end
      EOS
    end

    it 'should remove annotate if CRLF is used for line breaks' do
      path = create 'before.rb', <<-EOS
# == Schema Information
#
# Table name: foo\r\n#
#  id                  :integer         not null, primary key
#  created_at          :datetime
#  updated_at          :datetime
#
\r\n
class Foo < ActiveRecord::Base
end
      EOS

      AnnotateModels.remove_annotation_of_file(path)

      expect(content(path)).to eq <<-EOS
class Foo < ActiveRecord::Base
end
      EOS
    end

    it 'should remove after annotate' do
      path = create 'after.rb', <<-EOS
class Foo < ActiveRecord::Base
end

# == Schema Information
#
# Table name: foo
#
#  id                  :integer         not null, primary key
#  created_at          :datetime
#  updated_at          :datetime
#

      EOS

      AnnotateModels.remove_annotation_of_file(path)

      expect(content(path)).to eq <<-EOS
class Foo < ActiveRecord::Base
end
      EOS
    end

    it 'should remove opening wrapper' do
      path = create 'opening_wrapper.rb', <<-EOS
# wrapper
# == Schema Information
#
# Table name: foo
#
#  id                  :integer         not null, primary key
#  created_at          :datetime
#  updated_at          :datetime
#

class Foo < ActiveRecord::Base
end
      EOS

      AnnotateModels.remove_annotation_of_file(path, wrapper_open: 'wrapper')

      expect(content(path)).to eq <<-EOS
class Foo < ActiveRecord::Base
end
      EOS
    end

    it 'should remove wrapper if CRLF is used for line breaks' do
      path = create 'opening_wrapper.rb', <<-EOS
# wrapper\r\n# == Schema Information
#
# Table name: foo
#
#  id                  :integer         not null, primary key
#  created_at          :datetime
#  updated_at          :datetime
#

class Foo < ActiveRecord::Base
end
      EOS

      AnnotateModels.remove_annotation_of_file(path, wrapper_open: 'wrapper')

      expect(content(path)).to eq <<-EOS
class Foo < ActiveRecord::Base
end
      EOS
    end

    it 'should remove closing wrapper' do
      path = create 'closing_wrapper.rb', <<-EOS
class Foo < ActiveRecord::Base
end

# == Schema Information
#
# Table name: foo
#
#  id                  :integer         not null, primary key
#  created_at          :datetime
#  updated_at          :datetime
#
# wrapper

      EOS

      AnnotateModels.remove_annotation_of_file(path, wrapper_close: 'wrapper')

      expect(content(path)).to eq <<-EOS
class Foo < ActiveRecord::Base
end
      EOS
    end

    it 'does not change file with #SkipSchemaAnnotations' do
      content = <<-EOS
# -*- SkipSchemaAnnotations
# == Schema Information
#
# Table name: foo
#
#  id                  :integer         not null, primary key
#  created_at          :datetime
#  updated_at          :datetime
#

class Foo < ActiveRecord::Base
end
      EOS

      path = create 'skip.rb', content

      AnnotateModels.remove_annotation_of_file(path)
      expect(content(path)).to eq(content)
    end
  end

  describe '#resolve_filename' do
    it 'should return the test path for a model' do
      filename_template = 'test/unit/%MODEL_NAME%_test.rb'
      model_name        = 'example_model'
      table_name        = 'example_models'

      filename = AnnotateModels.resolve_filename(filename_template, model_name, table_name)
      expect(filename). to eq 'test/unit/example_model_test.rb'
    end

    it 'should return the additional glob' do
      filename_template = '/foo/bar/%MODEL_NAME%/testing.rb'
      model_name        = 'example_model'
      table_name        = 'example_models'

      filename = AnnotateModels.resolve_filename(filename_template, model_name, table_name)
      expect(filename). to eq '/foo/bar/example_model/testing.rb'
    end

    it 'should return the additional glob' do
      filename_template = '/foo/bar/%PLURALIZED_MODEL_NAME%/testing.rb'
      model_name        = 'example_model'
      table_name        = 'example_models'

      filename = AnnotateModels.resolve_filename(filename_template, model_name, table_name)
      expect(filename). to eq '/foo/bar/example_models/testing.rb'
    end

    it 'should return the fixture path for a model' do
      filename_template = 'test/fixtures/%TABLE_NAME%.yml'
      model_name        = 'example_model'
      table_name        = 'example_models'

      filename = AnnotateModels.resolve_filename(filename_template, model_name, table_name)
      expect(filename). to eq 'test/fixtures/example_models.yml'
    end

    it 'should return the fixture path for a nested model' do
      filename_template = 'test/fixtures/%PLURALIZED_MODEL_NAME%.yml'
      model_name        = 'parent/child'
      table_name        = 'parent_children'

      filename = AnnotateModels.resolve_filename(filename_template, model_name, table_name)
      expect(filename). to eq 'test/fixtures/parent/children.yml'
    end
  end

  describe 'annotating a file' do
    before do
      @model_dir = Dir.mktmpdir('annotate_models')
      (@model_file_name, @file_content) = write_model 'user.rb', <<-EOS
class User < ActiveRecord::Base
end
      EOS

      @klass = mock_class(:users,
                          :id,
                          [
                            mock_column(:id, :integer),
                            mock_column(:name, :string, limit: 50)
                          ])
      @schema_info = AnnotateModels.get_schema_info(@klass, '== Schema Info')
      Annotate.reset_options
    end

    def write_model(file_name, file_content)
      fname = File.join(@model_dir, file_name)
      FileUtils.mkdir_p(File.dirname(fname))
      File.open(fname, 'wb') { |f| f.write file_content }

      [fname, file_content]
    end

    def annotate_one_file(options = {})
      Annotate.set_defaults(options)
      options = Annotate.setup_options(options)
      AnnotateModels.annotate_one_file(@model_file_name, @schema_info, :position_in_class, options)

      # Wipe settings so the next call will pick up new values...
      Annotate.instance_variable_set('@has_set_defaults', false)
      Annotate::POSITION_OPTIONS.each { |key| ENV[key.to_s] = '' }
      Annotate::FLAG_OPTIONS.each { |key| ENV[key.to_s] = '' }
      Annotate::PATH_OPTIONS.each { |key| ENV[key.to_s] = '' }
    end

    def magic_comments_list_each
      [
        '# encoding: UTF-8',
        '# coding: UTF-8',
        '# -*- coding: UTF-8 -*-',
        '#encoding: utf-8',
        '# encoding: utf-8',
        '# -*- encoding : utf-8 -*-',
        "# encoding: utf-8\n# frozen_string_literal: true",
        "# frozen_string_literal: true\n# encoding: utf-8",
        '# frozen_string_literal: true',
        '#frozen_string_literal: false',
        '# -*- frozen_string_literal : true -*-'
      ].each { |magic_comment| yield magic_comment }
    end

    ['before', :before, 'top', :top].each do |position|
      it "should put annotation before class if :position == #{position}" do
        annotate_one_file position: position
        expect(File.read(@model_file_name))
          .to eq("#{@schema_info}\n#{@file_content}")
      end
    end

    ['after', :after, 'bottom', :bottom].each do |position|
      it "should put annotation after class if position: #{position}" do
        annotate_one_file position: position
        expect(File.read(@model_file_name))
          .to eq("#{@file_content}\n#{@schema_info}")
      end
    end

    it 'should wrap annotation if wrapper is specified' do
      annotate_one_file wrapper_open: 'START', wrapper_close: 'END'
      expect(File.read(@model_file_name))
        .to eq("# START\n#{@schema_info}# END\n\n#{@file_content}")
    end

    describe 'with existing annotation' do
      context 'of a foreign key' do
        before do
          klass = mock_class(:users,
                             :id,
                             [
                               mock_column(:id, :integer),
                               mock_column(:foreign_thing_id, :integer)
                             ],
                             [],
                             [
                               mock_foreign_key('fk_rails_cf2568e89e',
                                                'foreign_thing_id',
                                                'foreign_things',
                                                'id',
                                                on_delete: :cascade)
                             ])
          @schema_info = AnnotateModels.get_schema_info(klass, '== Schema Info', show_foreign_keys: true)
          annotate_one_file
        end

        it 'should update foreign key constraint' do
          klass = mock_class(:users,
                             :id,
                             [
                               mock_column(:id, :integer),
                               mock_column(:foreign_thing_id, :integer)
                             ],
                             [],
                             [
                               mock_foreign_key('fk_rails_cf2568e89e',
                                                'foreign_thing_id',
                                                'foreign_things',
                                                'id',
                                                on_delete: :restrict)
                             ])
          @schema_info = AnnotateModels.get_schema_info(klass, '== Schema Info', show_foreign_keys: true)
          annotate_one_file
          expect(File.read(@model_file_name)).to eq("#{@schema_info}\n#{@file_content}")
        end
      end
    end

    describe 'with existing annotation => :before' do
      before do
        annotate_one_file position: :before
        another_schema_info = AnnotateModels.get_schema_info(mock_class(:users, :id, [mock_column(:id, :integer)]), '== Schema Info')
        @schema_info = another_schema_info
      end

      it 'should retain current position' do
        annotate_one_file
        expect(File.read(@model_file_name)).to eq("#{@schema_info}\n#{@file_content}")
      end

      it 'should retain current position even when :position is changed to :after' do
        annotate_one_file position: :after
        expect(File.read(@model_file_name)).to eq("#{@schema_info}\n#{@file_content}")
      end

      it 'should change position to :after when force: true' do
        annotate_one_file position: :after, force: true
        expect(File.read(@model_file_name)).to eq("#{@file_content}\n#{@schema_info}")
      end
    end

    describe 'with existing annotation => :after' do
      before do
        annotate_one_file position: :after
        another_schema_info = AnnotateModels.get_schema_info(mock_class(:users, :id, [mock_column(:id, :integer)]), '== Schema Info')
        @schema_info = another_schema_info
      end

      it 'should retain current position' do
        annotate_one_file
        expect(File.read(@model_file_name)).to eq("#{@file_content}\n#{@schema_info}")
      end

      it 'should retain current position even when :position is changed to :before' do
        annotate_one_file position: :before
        expect(File.read(@model_file_name)).to eq("#{@file_content}\n#{@schema_info}")
      end

      it 'should change position to :before when force: true' do
        annotate_one_file position: :before, force: true
        expect(File.read(@model_file_name)).to eq("#{@schema_info}\n#{@file_content}")
      end
    end

    it 'should skip columns with option[:ignore_columns] set' do
      output = AnnotateModels.get_schema_info(@klass, '== Schema Info',
                                              :ignore_columns => '(id|updated_at|created_at)')
      expect(output.match(/id/)).to be_nil
    end

    it 'works with namespaced models (i.e. models inside modules/subdirectories)' do
      (model_file_name, file_content) = write_model 'foo/user.rb', <<-EOS
class Foo::User < ActiveRecord::Base
end
      EOS

      klass = mock_class(:'foo_users',
                         :id,
                         [
                           mock_column(:id, :integer),
                           mock_column(:name, :string, limit: 50)
                         ])
      schema_info = AnnotateModels.get_schema_info(klass, '== Schema Info')
      AnnotateModels.annotate_one_file(model_file_name, schema_info, position: :before)
      expect(File.read(model_file_name)).to eq("#{schema_info}\n#{file_content}")
    end

    it 'should not touch magic comments' do
      magic_comments_list_each do |magic_comment|
        write_model 'user.rb', <<-EOS
#{magic_comment}
class User < ActiveRecord::Base
end
        EOS

        annotate_one_file position: :before

        lines = magic_comment.split("\n")
        File.open @model_file_name do |file|
          lines.count.times do |index|
            expect(file.readline).to eq "#{lines[index]}\n"
          end
        end
      end
    end

    it 'adds an empty line between magic comments and annotation (position :before)' do
      content = "class User < ActiveRecord::Base\nend\n"
      magic_comments_list_each do |magic_comment|
        model_file_name, = write_model 'user.rb', "#{magic_comment}\n#{content}"

        annotate_one_file position: :before
        schema_info = AnnotateModels.get_schema_info(@klass, '== Schema Info')

        expect(File.read(model_file_name)).to eq("#{magic_comment}\n\n#{schema_info}\n#{content}")
      end
    end

    it 'only keeps a single empty line around the annotation (position :before)' do
      content = "class User < ActiveRecord::Base\nend\n"
      magic_comments_list_each do |magic_comment|
        schema_info = AnnotateModels.get_schema_info(@klass, '== Schema Info')
        model_file_name, = write_model 'user.rb', "#{magic_comment}\n\n\n\n#{content}"

        annotate_one_file position: :before

        expect(File.read(model_file_name)).to eq("#{magic_comment}\n\n#{schema_info}\n#{content}")
      end
    end

    it 'does not change whitespace between magic comments and model file content (position :after)' do
      content = "class User < ActiveRecord::Base\nend\n"
      magic_comments_list_each do |magic_comment|
        model_file_name, = write_model 'user.rb', "#{magic_comment}\n#{content}"

        annotate_one_file position: :after
        schema_info = AnnotateModels.get_schema_info(@klass, '== Schema Info')

        expect(File.read(model_file_name)).to eq("#{magic_comment}\n#{content}\n#{schema_info}")
      end
    end

    describe "if a file can't be annotated" do
      before do
        allow(AnnotateModels).to receive(:get_loaded_model_by_path).with('user').and_return(nil)

        write_model('user.rb', <<-EOS)
          class User < ActiveRecord::Base
            raise "oops"
          end
        EOS
      end

      it 'displays just the error message with trace disabled (default)' do
        error_output = capturing(:stderr) do
          AnnotateModels.do_annotations model_dir: @model_dir, is_rake: true
        end

        expect(error_output).to include("Unable to annotate #{@model_dir}/user.rb: oops")
        expect(error_output).not_to include('/spec/annotate/annotate_models_spec.rb:')
      end

      it 'displays the error message and stacktrace with trace enabled' do
        error_output = capturing(:stderr) do
          AnnotateModels.do_annotations model_dir: @model_dir, is_rake: true, trace: true
        end

        expect(error_output).to include("Unable to annotate #{@model_dir}/user.rb: oops")
        expect(error_output).to include('/spec/lib/annotate/annotate_models_spec.rb:')
      end
    end

    describe "if a file can't be deannotated" do
      before do
        allow(AnnotateModels).to receive(:get_loaded_model_by_path).with('user').and_return(nil)

        write_model('user.rb', <<-EOS)
          class User < ActiveRecord::Base
            raise "oops"
          end
        EOS
      end

      it 'displays just the error message with trace disabled (default)' do
        error_output = capturing(:stderr) do
          AnnotateModels.remove_annotations model_dir: @model_dir, is_rake: true
        end

        expect(error_output).to include("Unable to deannotate #{@model_dir}/user.rb: oops")
        expect(error_output).not_to include("/user.rb:2:in `<class:User>'")
      end

      it 'displays the error message and stacktrace with trace enabled' do
        error_output = capturing(:stderr) do
          AnnotateModels.remove_annotations model_dir: @model_dir, is_rake: true, trace: true
        end

        expect(error_output).to include("Unable to deannotate #{@model_dir}/user.rb: oops")
        expect(error_output).to include("/user.rb:2:in `<class:User>'")
      end
    end

    describe 'frozen option' do
      it "should abort without existing annotation when frozen: true " do
        expect { annotate_one_file frozen: true }.to raise_error SystemExit, /user.rb needs to be updated, but annotate was run with `--frozen`./
      end

      it "should abort with different annotation when frozen: true " do
        annotate_one_file
        another_schema_info = AnnotateModels.get_schema_info(mock_class(:users, :id, [mock_column(:id, :integer)]), '== Schema Info')
        @schema_info = another_schema_info

        expect { annotate_one_file frozen: true }.to raise_error SystemExit, /user.rb needs to be updated, but annotate was run with `--frozen`./
      end

      it "should NOT abort with same annotation when frozen: true " do
        annotate_one_file
        expect { annotate_one_file frozen: true }.not_to raise_error
      end
    end
  end

  describe '.annotate_model_file' do
    before do
      class Foo < ActiveRecord::Base; end
      allow(AnnotateModels).to receive(:get_model_class).with('foo.rb') { Foo }
      allow(Foo).to receive(:table_exists?) { false }
    end

    after { Object.send :remove_const, 'Foo' }

    it 'skips attempt to annotate if no table exists for model' do
      annotate_model_file = AnnotateModels.annotate_model_file([], 'foo.rb', nil, {})

      expect(annotate_model_file).to eq nil
    end
  end
end
