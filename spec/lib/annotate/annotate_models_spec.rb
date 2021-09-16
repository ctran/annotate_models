# encoding: utf-8
require_relative '../../spec_helper'
require 'annotate/annotate_models'
require 'annotate/active_record_patch'
require 'active_support/core_ext/string'
require 'files'
require 'tmpdir'

describe AnnotateModels do
  MAGIC_COMMENTS = [
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
    '# -*- frozen_string_literal : true -*-',
    '# typed: true',
    '#typed: false'
  ].freeze

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

  describe '.quote' do
    subject do
      AnnotateModels.quote(value)
    end

    context 'when the argument is nil' do
      let(:value) { nil }
      it 'returns string "NULL"' do
        is_expected.to eq('NULL')
      end
    end

    context 'when the argument is true' do
      let(:value) { true }
      it 'returns string "TRUE"' do
        is_expected.to eq('TRUE')
      end
    end

    context 'when the argument is false' do
      let(:value) { false }
      it 'returns string "FALSE"' do
        is_expected.to eq('FALSE')
      end
    end

    context 'when the argument is an integer' do
      let(:value) { 25 }
      it 'returns the integer as a string' do
        is_expected.to eq('25')
      end
    end

    context 'when the argument is a float number' do
      context 'when the argument is like 25.6' do
        let(:value) { 25.6 }
        it 'returns the float number as a string' do
          is_expected.to eq('25.6')
        end
      end

      context 'when the argument is like 1e-20' do
        let(:value) { 1e-20 }
        it 'returns the float number as a string' do
          is_expected.to eq('1.0e-20')
        end
      end
    end

    context 'when the argument is a BigDecimal number' do
      let(:value) { BigDecimal('1.2') }
      it 'returns the float number as a string' do
        is_expected.to eq('1.2')
      end
    end

    context 'when the argument is an array' do
      let(:value) { [BigDecimal('1.2')] }
      it 'returns an array of which elements are converted to string' do
        is_expected.to eq(['1.2'])
      end
    end
  end

  describe '.parse_options' do
    let(:options) do
      {
        root_dir: '/root',
        model_dir: 'app/models,app/one,  app/two   ,,app/three',
        skip_subdirectory_model_load: false
      }
    end

    before :each do
      AnnotateModels.send(:parse_options, options)
    end

    describe '@root_dir' do
      subject do
        AnnotateModels.instance_variable_get(:@root_dir)
      end

      it 'sets @root_dir' do
        is_expected.to eq('/root')
      end
    end

    describe '@model_dir' do
      subject do
        AnnotateModels.instance_variable_get(:@model_dir)
      end

      it 'separates option "model_dir" with commas and sets @model_dir as an array of string' do
        is_expected.to eq(['app/models', 'app/one', 'app/two', 'app/three'])
      end
    end

    describe '@skip_subdirectory_model_load' do
      subject do
        AnnotateModels.instance_variable_get(:@skip_subdirectory_model_load)
      end

      context 'option is set to true' do
        let(:options) do
          {
            root_dir: '/root',
            model_dir: 'app/models,app/one,  app/two   ,,app/three',
            skip_subdirectory_model_load: true
          }
        end

        it 'sets skip_subdirectory_model_load to true' do
          is_expected.to eq(true)
        end
      end

      context 'option is set to false' do
        let(:options) do
          {
            root_dir: '/root',
            model_dir: 'app/models,app/one,  app/two   ,,app/three',
            skip_subdirectory_model_load: false
          }
        end

        it 'sets skip_subdirectory_model_load to false' do
          is_expected.to eq(false)
        end
      end
    end
  end

  describe '.get_schema_info' do
    subject do
      AnnotateModels.get_schema_info(klass, header, **options)
    end

    let :klass do
      mock_class(:users, primary_key, columns, indexes, foreign_keys)
    end

    let :indexes do
      []
    end

    let :foreign_keys do
      []
    end

    context 'when option is not present' do
      let :options do
        {}
      end

      context 'when header is "Schema Info"' do
        let :header do
          'Schema Info'
        end

        context 'when the primary key is not specified' do
          let :primary_key do
            nil
          end

          context 'when the columns are normal' do
            let :columns do
              [
                mock_column(:id, :integer),
                mock_column(:name, :string, limit: 50)
              ]
            end

            let :expected_result do
              <<~EOS
                # Schema Info
                #
                # Table name: users
                #
                #  id   :integer          not null
                #  name :string(50)       not null
                #

              EOS
            end

            it 'returns schema info' do
              is_expected.to eq(expected_result)
            end
          end

          context 'when an enum column exists' do
            let :columns do
              [
                mock_column(:id, :integer),
                mock_column(:name, :enum, limit: [:enum1, :enum2])
              ]
            end

            let :expected_result do
              <<~EOS
                # Schema Info
                #
                # Table name: users
                #
                #  id   :integer          not null
                #  name :enum             not null, (enum1, enum2)
                #

              EOS
            end

            it 'returns schema info' do
              is_expected.to eq(expected_result)
            end
          end

          context 'when unsigned columns exist' do
            let :columns do
              [
                mock_column(:id, :integer),
                mock_column(:integer, :integer, unsigned?: true),
                mock_column(:bigint,  :integer, unsigned?: true, bigint?: true),
                mock_column(:bigint,  :bigint,  unsigned?: true),
                mock_column(:float,   :float,   unsigned?: true),
                mock_column(:decimal, :decimal, unsigned?: true, precision: 10, scale: 2),
              ]
            end

            let :expected_result do
              <<~EOS
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

            it 'returns schema info' do
              is_expected.to eq(expected_result)
            end
          end
        end

        context 'when the primary key is specified' do
          context 'when the primary_key is :id' do
            let :primary_key do
              :id
            end

            context 'when columns are normal' do
              let :columns do
                [
                  mock_column(:id, :integer, limit: 8),
                  mock_column(:name, :string, limit: 50),
                  mock_column(:notes, :text, limit: 55)
                ]
              end

              let :expected_result do
                <<~EOS
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

              it 'returns schema info' do
                is_expected.to eq(expected_result)
              end
            end

            context 'when columns have default values' do
              let :columns do
                [
                  mock_column(:id, :integer),
                  mock_column(:size, :integer, default: 20),
                  mock_column(:flag, :boolean, default: false)
                ]
              end

              let :expected_result do
                <<~EOS
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

              it 'returns schema info with default values' do
                is_expected.to eq(expected_result)
              end
            end

            context 'with Globalize gem' do
              let :translation_klass do
                double('Post::Translation',
                       to_s: 'Post::Translation',
                       columns: [
                         mock_column(:id, :integer, limit: 8),
                         mock_column(:post_id, :integer, limit: 8),
                         mock_column(:locale, :string, limit: 50),
                         mock_column(:title, :string, limit: 50),
                       ])
              end

              let :klass do
                mock_class(:posts, primary_key, columns, indexes, foreign_keys).tap do |mock_klass|
                  allow(mock_klass).to receive(:translation_class).and_return(translation_klass)
                end
              end

              let :columns do
                [
                  mock_column(:id, :integer, limit: 8),
                  mock_column(:author_name, :string, limit: 50),
                ]
              end

              let :expected_result do
                <<~EOS
                  # Schema Info
                  #
                  # Table name: posts
                  #
                  #  id          :integer          not null, primary key
                  #  author_name :string(50)       not null
                  #  title       :string(50)       not null
                  #

                EOS
              end

              it 'returns schema info' do
                is_expected.to eq expected_result
              end
            end
          end

          context 'when the primary key is an array (using composite_primary_keys)' do
            let :primary_key do
              [:a_id, :b_id]
            end

            let :columns do
              [
                mock_column(:a_id, :integer),
                mock_column(:b_id, :integer),
                mock_column(:name, :string, limit: 50)
              ]
            end

            let :expected_result do
              <<~EOS
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

            it 'returns schema info' do
              is_expected.to eq(expected_result)
            end
          end
        end
      end
    end

    context 'when option is present' do
      context 'when header is "Schema Info"' do
        let :header do
          'Schema Info'
        end

        context 'when the primary key is specified' do
          context 'when the primary_key is :id' do
            let :primary_key do
              :id
            end

            context 'when indexes exist' do
              context 'when option "show_indexes" is true' do
                let :options do
                  { show_indexes: true }
                end

                context 'when indexes are normal' do
                  let :columns do
                    [
                      mock_column(:id, :integer),
                      mock_column(:foreign_thing_id, :integer)
                    ]
                  end

                  let :indexes do
                    [
                      mock_index('index_rails_02e851e3b7', columns: ['id']),
                      mock_index('index_rails_02e851e3b8', columns: ['foreign_thing_id'])
                    ]
                  end

                  let :expected_result do
                    <<~EOS
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

                  it 'returns schema info with index information' do
                    is_expected.to eq expected_result
                  end
                end

                context 'when one of indexes includes orderd index key' do
                  let :columns do
                    [
                      mock_column("id", :integer),
                      mock_column("firstname", :string),
                      mock_column("surname", :string),
                      mock_column("value", :string)
                    ]
                  end

                  let :indexes do
                    [
                      mock_index('index_rails_02e851e3b7', columns: ['id']),
                      mock_index('index_rails_02e851e3b8',
                                 columns: %w(firstname surname value),
                                 orders: { 'surname' => :asc, 'value' => :desc })
                    ]
                  end

                  let :expected_result do
                    <<~EOS
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

                  it 'returns schema info with index information' do
                    is_expected.to eq expected_result
                  end
                end

                context 'when one of indexes includes "where" clause' do
                  let :columns do
                    [
                      mock_column("id", :integer),
                      mock_column("firstname", :string),
                      mock_column("surname", :string),
                      mock_column("value", :string)
                    ]
                  end

                  let :indexes do
                    [
                      mock_index('index_rails_02e851e3b7', columns: ['id']),
                      mock_index('index_rails_02e851e3b8',
                                 columns: %w(firstname surname),
                                 where: 'value IS NOT NULL')
                    ]
                  end

                  let :expected_result do
                    <<~EOS
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

                  it 'returns schema info with index information' do
                    is_expected.to eq expected_result
                  end
                end

                context 'when one of indexes includes "using" clause other than "btree"' do
                  let :columns do
                    [
                      mock_column("id", :integer),
                      mock_column("firstname", :string),
                      mock_column("surname", :string),
                      mock_column("value", :string)
                    ]
                  end

                  let :indexes do
                    [
                      mock_index('index_rails_02e851e3b7', columns: ['id']),
                      mock_index('index_rails_02e851e3b8',
                                 columns: %w(firstname surname),
                                 using: 'hash')
                    ]
                  end

                  let :expected_result do
                    <<~EOS
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

                  it 'returns schema info with index information' do
                    is_expected.to eq expected_result
                  end
                end

                context 'when index is not defined' do
                  let :columns do
                    [
                      mock_column(:id, :integer),
                      mock_column(:foreign_thing_id, :integer)
                    ]
                  end

                  let :indexes do
                    []
                  end

                  let :expected_result do
                    <<~EOS
                      # Schema Info
                      #
                      # Table name: users
                      #
                      #  id               :integer          not null, primary key
                      #  foreign_thing_id :integer          not null
                      #

                    EOS
                  end

                  it 'returns schema info without index information' do
                    is_expected.to eq expected_result
                  end
                end
              end

              context 'when option "simple_indexes" is true' do
                let :options do
                  { simple_indexes: true }
                end

                context 'when one of indexes includes "orders" clause' do
                  let :columns do
                    [
                      mock_column(:id, :integer),
                      mock_column(:foreign_thing_id, :integer)
                    ]
                  end

                  let :indexes do
                    [
                      mock_index('index_rails_02e851e3b7', columns: ['id']),
                      mock_index('index_rails_02e851e3b8',
                                 columns: ['foreign_thing_id'],
                                 orders: { 'foreign_thing_id' => :desc })
                    ]
                  end

                  let :expected_result do
                    <<~EOS
                      # Schema Info
                      #
                      # Table name: users
                      #
                      #  id               :integer          not null, primary key
                      #  foreign_thing_id :integer          not null
                      #

                    EOS
                  end

                  it 'returns schema info with index information' do
                    is_expected.to eq expected_result
                  end
                end

                context 'when one of indexes is in string form' do
                  let :columns do
                    [
                      mock_column("id", :integer),
                      mock_column("name", :string)
                    ]
                  end

                  let :indexes do
                    [
                      mock_index('index_rails_02e851e3b7', columns: ['id']),
                      mock_index('index_rails_02e851e3b8', columns: 'LOWER(name)')
                    ]
                  end

                  let :expected_result do
                    <<~EOS
                      # Schema Info
                      #
                      # Table name: users
                      #
                      #  id   :integer          not null, primary key, indexed
                      #  name :string           not null
                      #

                    EOS
                  end

                  it 'returns schema info with index information' do
                    is_expected.to eq expected_result
                  end
                end
              end
            end

            context 'when foreign keys exist' do
              let :columns do
                [
                  mock_column(:id, :integer),
                  mock_column(:foreign_thing_id, :integer)
                ]
              end

              let :foreign_keys do
                [
                  mock_foreign_key('fk_rails_cf2568e89e', 'foreign_thing_id', 'foreign_things'),
                  mock_foreign_key('custom_fk_name', 'other_thing_id', 'other_things'),
                  mock_foreign_key('fk_rails_a70234b26c', 'third_thing_id', 'third_things')
                ]
              end

              context 'when option "show_foreign_keys" is specified' do
                let :options do
                  { show_foreign_keys: true }
                end

                context 'when foreign_keys does not have option' do
                  let :expected_result do
                    <<~EOS
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

                  it 'returns schema info with foreign keys' do
                    is_expected.to eq(expected_result)
                  end
                end

                context 'when foreign_keys have option "on_delete" and "on_update"' do
                  let :foreign_keys do
                    [
                      mock_foreign_key('fk_rails_02e851e3b7',
                                       'foreign_thing_id',
                                       'foreign_things',
                                       'id',
                                       on_delete: 'on_delete_value',
                                       on_update: 'on_update_value')
                    ]
                  end

                  let :expected_result do
                    <<~EOS
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

                  it 'returns schema info with foreign keys' do
                    is_expected.to eq(expected_result)
                  end
                end
              end

              context 'when option "show_foreign_keys" and "show_complete_foreign_keys" are specified' do
                let :options do
                  { show_foreign_keys: true, show_complete_foreign_keys: true }
                end

                let :expected_result do
                  <<~EOS
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

                it 'returns schema info with foreign keys' do
                  is_expected.to eq(expected_result)
                end
              end
            end

            context 'when "hide_limit_column_types" is specified in options' do
              let :columns do
                [
                  mock_column(:id, :integer, limit: 8),
                  mock_column(:active, :boolean, limit: 1),
                  mock_column(:name, :string, limit: 50),
                  mock_column(:notes, :text, limit: 55)
                ]
              end

              context 'when "hide_limit_column_types" is blank string' do
                let :options do
                  { hide_limit_column_types: '' }
                end

                let :expected_result do
                  <<~EOS
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
                end

                it 'works with option "hide_limit_column_types"' do
                  is_expected.to eq expected_result
                end
              end

              context 'when "hide_limit_column_types" is "integer,boolean"' do
                let :options do
                  { hide_limit_column_types: 'integer,boolean' }
                end

                let :expected_result do
                  <<~EOS
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
                end

                it 'works with option "hide_limit_column_types"' do
                  is_expected.to eq expected_result
                end
              end

              context 'when "hide_limit_column_types" is "integer,boolean,string,text"' do
                let :options do
                  { hide_limit_column_types: 'integer,boolean,string,text' }
                end

                let :expected_result do
                  <<~EOS
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

                it 'works with option "hide_limit_column_types"' do
                  is_expected.to eq expected_result
                end
              end
            end

            context 'when "hide_default_column_types" is specified in options' do
              let :columns do
                [
                  mock_column(:profile, :json, default: {}),
                  mock_column(:settings, :jsonb, default: {}),
                  mock_column(:parameters, :hstore, default: {})
                ]
              end

              context 'when "hide_default_column_types" is blank string' do
                let :options do
                  { hide_default_column_types: '' }
                end

                let :expected_result do
                  <<~EOS
                    # Schema Info
                    #
                    # Table name: users
                    #
                    #  profile    :json             not null
                    #  settings   :jsonb            not null
                    #  parameters :hstore           not null
                    #

                  EOS
                end

                it 'works with option "hide_default_column_types"' do
                  is_expected.to eq expected_result
                end
              end

              context 'when "hide_default_column_types" is "skip"' do
                let :options do
                  { hide_default_column_types: 'skip' }
                end

                let :expected_result do
                  <<~EOS
                    # Schema Info
                    #
                    # Table name: users
                    #
                    #  profile    :json             default({}), not null
                    #  settings   :jsonb            default({}), not null
                    #  parameters :hstore           default({}), not null
                    #

                  EOS
                end

                it 'works with option "hide_default_column_types"' do
                  is_expected.to eq expected_result
                end
              end

              context 'when "hide_default_column_types" is "json"' do
                let :options do
                  { hide_default_column_types: 'json' }
                end

                let :expected_result do
                  <<~EOS
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

                it 'works with option "hide_limit_column_types"' do
                  is_expected.to eq expected_result
                end
              end
            end

            context 'when "classified_sort" is specified in options' do
              let :columns do
                [
                  mock_column(:active, :boolean, limit: 1),
                  mock_column(:name, :string, limit: 50),
                  mock_column(:notes, :text, limit: 55)
                ]
              end

              context 'when "classified_sort" is "yes"' do
                let :options do
                  { classified_sort: 'yes' }
                end

                let :expected_result do
                  <<~EOS
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

                it 'works with option "classified_sort"' do
                  is_expected.to eq expected_result
                end
              end
            end

            context 'when "with_comment" is specified in options' do
              context 'when "with_comment" is "yes"' do
                let :options do
                  { with_comment: 'yes' }
                end

                context 'when columns have comments' do
                  let :columns do
                    [
                      mock_column(:id,         :integer, limit: 8,  comment: 'ID'),
                      mock_column(:active,     :boolean, limit: 1,  comment: 'Active'),
                      mock_column(:name,       :string,  limit: 50, comment: 'Name'),
                      mock_column(:notes,      :text,    limit: 55, comment: 'Notes'),
                      mock_column(:no_comment, :text,    limit: 20, comment: nil)
                    ]
                  end

                  let :expected_result do
                    <<~EOS
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
                  end

                  it 'works with option "with_comment"' do
                    is_expected.to eq expected_result
                  end
                end

                context 'when columns have multibyte comments' do
                  let :columns do
                    [
                      mock_column(:id,         :integer, limit: 8,  comment: 'ＩＤ'),
                      mock_column(:active,     :boolean, limit: 1,  comment: 'ＡＣＴＩＶＥ'),
                      mock_column(:name,       :string,  limit: 50, comment: 'ＮＡＭＥ'),
                      mock_column(:notes,      :text,    limit: 55, comment: 'ＮＯＴＥＳ'),
                      mock_column(:cyrillic,   :text,    limit: 30, comment: 'Кириллица'),
                      mock_column(:japanese,   :text,    limit: 60, comment: '熊本大学　イタリア　宝島'),
                      mock_column(:arabic,     :text,    limit: 20, comment: 'لغة'),
                      mock_column(:no_comment, :text,    limit: 20, comment: nil),
                      mock_column(:location,   :geometry_collection, limit: nil, comment: nil)
                    ]
                  end

                  let :expected_result do
                    <<~EOS
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
                  end

                  it 'works with option "with_comment"' do
                    is_expected.to eq expected_result
                  end
                end

                context 'when columns have multiline comments' do
                  let :columns do
                    [
                      mock_column(:id,         :integer, limit: 8,  comment: 'ID'),
                      mock_column(:notes,      :text,    limit: 55, comment: "Notes.\nMay include things like notes."),
                      mock_column(:no_comment, :text,    limit: 20, comment: nil)
                    ]
                  end

                  let :expected_result do
                    <<~EOS
                      # Schema Info
                      #
                      # Table name: users
                      #
                      #  id(ID)                                       :integer          not null, primary key
                      #  notes(Notes.\\nMay include things like notes.):text(55)         not null
                      #  no_comment                                   :text(20)         not null
                      #

                    EOS
                  end

                  it 'works with option "with_comment"' do
                    is_expected.to eq expected_result
                  end
                end

                context 'when geometry columns are included' do
                  let :columns do
                    [
                      mock_column(:id,       :integer,  limit: 8),
                      mock_column(:active,   :boolean,  default: false, null: false),
                      mock_column(:geometry, :geometry,
                                  geometric_type: 'Geometry', srid: 4326,
                                  limit: { srid: 4326, type: 'geometry' }),
                      mock_column(:location, :geography,
                                  geometric_type: 'Point', srid: 0,
                                  limit: { srid: 0, type: 'geometry' })
                    ]
                  end

                  let :expected_result do
                    <<~EOS
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
                  end

                  it 'works with option "with_comment"' do
                    is_expected.to eq expected_result
                  end
                end
              end
            end
          end
        end
      end

      context 'when header is "== Schema Information"' do
        let :header do
          AnnotateModels::PREFIX
        end

        context 'when the primary key is specified' do
          context 'when the primary_key is :id' do
            let :primary_key do
              :id
            end

            let :columns do
              [
                mock_column(:id, :integer),
                mock_column(:name, :string, limit: 50)
              ]
            end

            context 'when option "format_rdoc" is true' do
              let :options do
                { format_rdoc: true }
              end

              let :expected_result do
                <<~EOS
                  # == Schema Information
                  #
                  # Table name: users
                  #
                  # *id*::   <tt>integer, not null, primary key</tt>
                  # *name*:: <tt>string(50), not null</tt>
                  #--
                  # == Schema Information End
                  #++

                EOS
              end

              it 'returns schema info in RDoc format' do
                is_expected.to eq(expected_result)
              end
            end

            context 'when option "format_yard" is true' do
              let :options do
                { format_yard: true }
              end

              let :expected_result do
                <<~EOS
                  # == Schema Information
                  #
                  # Table name: users
                  #
                  # @!attribute id
                  #   @return [Integer]
                  # @!attribute name
                  #   @return [String]
                  #

                EOS
              end

              it 'returns schema info in YARD format' do
                is_expected.to eq(expected_result)
              end
            end

            context 'when option "format_markdown" is true' do
              context 'when other option is not specified' do
                let :options do
                  { format_markdown: true }
                end

                let :expected_result do
                  <<~EOS
                    # == Schema Information
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

                it 'returns schema info in Markdown format' do
                  is_expected.to eq(expected_result)
                end
              end

              context 'when option "show_indexes" is true' do
                let :options do
                  { format_markdown: true, show_indexes: true }
                end

                context 'when indexes are normal' do
                  let :indexes do
                    [
                      mock_index('index_rails_02e851e3b7', columns: ['id']),
                      mock_index('index_rails_02e851e3b8', columns: ['foreign_thing_id'])
                    ]
                  end

                  let :expected_result do
                    <<~EOS
                      # == Schema Information
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

                  it 'returns schema info with index information in Markdown format' do
                    is_expected.to eq expected_result
                  end
                end

                context 'when one of indexes includes "unique" clause' do
                  let :indexes do
                    [
                      mock_index('index_rails_02e851e3b7', columns: ['id']),
                      mock_index('index_rails_02e851e3b8',
                                 columns: ['foreign_thing_id'],
                                 unique: true)
                    ]
                  end

                  let :expected_result do
                    <<~EOS
                      # == Schema Information
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

                  it 'returns schema info with index information in Markdown format' do
                    is_expected.to eq expected_result
                  end
                end

                context 'when one of indexes includes orderd index key' do
                  let :indexes do
                    [
                      mock_index('index_rails_02e851e3b7', columns: ['id']),
                      mock_index('index_rails_02e851e3b8',
                                 columns: ['foreign_thing_id'],
                                 orders: { 'foreign_thing_id' => :desc })
                    ]
                  end

                  let :expected_result do
                    <<~EOS
                      # == Schema Information
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

                  it 'returns schema info with index information in Markdown format' do
                    is_expected.to eq expected_result
                  end
                end

                context 'when one of indexes includes "where" clause and "unique" clause' do
                  let :indexes do
                    [
                      mock_index('index_rails_02e851e3b7', columns: ['id']),
                      mock_index('index_rails_02e851e3b8',
                                 columns: ['foreign_thing_id'],
                                 unique: true,
                                 where: 'name IS NOT NULL')
                    ]
                  end

                  let :expected_result do
                    <<~EOS
                      # == Schema Information
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

                  it 'returns schema info with index information in Markdown format' do
                    is_expected.to eq expected_result
                  end
                end

                context 'when one of indexes includes "using" clause other than "btree"' do
                  let :indexes do
                    [
                      mock_index('index_rails_02e851e3b7', columns: ['id']),
                      mock_index('index_rails_02e851e3b8',
                                 columns: ['foreign_thing_id'],
                                 using: 'hash')
                    ]
                  end

                  let :expected_result do
                    <<~EOS
                      # == Schema Information
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

                  it 'returns schema info with index information in Markdown format' do
                    is_expected.to eq expected_result
                  end
                end
              end

              context 'when option "show_foreign_keys" is true' do
                let :options do
                  { format_markdown: true, show_foreign_keys: true }
                end

                let :columns do
                  [
                    mock_column(:id, :integer),
                    mock_column(:foreign_thing_id, :integer)
                  ]
                end

                context 'when foreign_keys have option "on_delete" and "on_update"' do
                  let :foreign_keys do
                    [
                      mock_foreign_key('fk_rails_02e851e3b7',
                                       'foreign_thing_id',
                                       'foreign_things',
                                       'id',
                                       on_delete: 'on_delete_value',
                                       on_update: 'on_update_value')
                    ]
                  end

                  let :expected_result do
                    <<~EOS
                      # == Schema Information
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

                  it 'returns schema info with foreign_keys in Markdown format' do
                    is_expected.to eq(expected_result)
                  end
                end
              end
            end

            context 'when "format_doc" and "with_comment" are specified in options' do
              let :options do
                { format_rdoc: true, with_comment: true }
              end

              context 'when columns are normal' do
                let :columns do
                  [
                    mock_column(:id, :integer, comment: 'ID'),
                    mock_column(:name, :string, limit: 50, comment: 'Name')
                  ]
                end

                let :expected_result do
                  <<~EOS
                    # == Schema Information
                    #
                    # Table name: users
                    #
                    # *id(ID)*::     <tt>integer, not null, primary key</tt>
                    # *name(Name)*:: <tt>string(50), not null</tt>
                    #--
                    # == Schema Information End
                    #++

                  EOS
                end

                it 'returns schema info in RDoc format' do
                  is_expected.to eq expected_result
                end
              end
            end

            context 'when "format_markdown" and "with_comment" are specified in options' do
              let :options do
                { format_markdown: true, with_comment: true }
              end

              context 'when columns have comments' do
                let :columns do
                  [
                    mock_column(:id, :integer, comment: 'ID'),
                    mock_column(:name, :string, limit: 50, comment: 'Name')
                  ]
                end

                let :expected_result do
                  <<~EOS
                    # == Schema Information
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

                it 'returns schema info in Markdown format' do
                  is_expected.to eq expected_result
                end
              end

              context 'when columns have multibyte comments' do
                let :columns do
                  [
                    mock_column(:id, :integer, comment: 'ＩＤ'),
                    mock_column(:name, :string, limit: 50, comment: 'ＮＡＭＥ')
                  ]
                end

                let :expected_result do
                  <<~EOS
                    # == Schema Information
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

                it 'returns schema info in Markdown format' do
                  is_expected.to eq expected_result
                end
              end
            end
          end
        end
      end
    end
  end

  describe '.set_defaults' do
    subject do
      Annotate::Helpers.true?(ENV['show_complete_foreign_keys'])
    end

    context 'when default value of "show_complete_foreign_keys" is not set' do
      it 'returns false' do
        is_expected.to be(false)
      end
    end

    context 'when default value of "show_complete_foreign_keys" is set' do
      before do
        Annotate.set_defaults('show_complete_foreign_keys' => 'true')
      end

      it 'returns true' do
        is_expected.to be(true)
      end
    end

    after :each do
      ENV.delete('show_complete_foreign_keys')
    end
  end

  describe '.get_patterns' do
    subject { AnnotateModels.get_patterns(options, pattern_type) }

    context 'when pattern_type is "additional_file_patterns"' do
      let(:pattern_type) { 'additional_file_patterns' }

      context 'when additional_file_patterns is specified in the options' do
        let(:additional_file_patterns) do
          [
            '/%PLURALIZED_MODEL_NAME%/**/*.rb',
            '/bar/%PLURALIZED_MODEL_NAME%/*_form'
          ]
        end

        let(:options) { { additional_file_patterns: additional_file_patterns } }

        it 'returns additional_file_patterns in the argument "options"' do
          is_expected.to eq(additional_file_patterns)
        end
      end

      context 'when additional_file_patterns is not specified in the options' do
        let(:options) { {} }

        it 'returns an empty array' do
          is_expected.to eq([])
        end
      end
    end
  end

  describe '.get_model_files' do
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

  describe '.get_model_class' do
    before :all do
      AnnotateModels.model_dir = Dir.mktmpdir('annotate_models')
    end

    # TODO: use 'files' gem instead
    def create(filename, file_content)
      File.join(AnnotateModels.model_dir[0], filename).tap do |path|
        FileUtils.mkdir_p(File.dirname(path))
        File.open(path, 'wb') do |f|
          f.puts(file_content)
        end
      end
    end

    before :each do
      create(filename, file_content)
    end

    let :klass do
      AnnotateModels.get_model_class(File.join(AnnotateModels.model_dir[0], filename))
    end

    context 'when class Foo is defined in "foo.rb"' do
      let :filename do
        'foo.rb'
      end

      let :file_content do
        <<~EOS
          class Foo < ActiveRecord::Base
          end
        EOS
      end

      it 'works' do
        expect(klass.name).to eq('Foo')
      end
    end

    context 'when class name is not capitalized normally' do
      context 'when class FooWithCAPITALS is defined in "foo_with_capitals.rb"' do
        let :filename do
          'foo_with_capitals.rb'
        end

        let :file_content do
          <<~EOS
            class FooWithCAPITALS < ActiveRecord::Base
            end
          EOS
        end

        it 'works' do
          expect(klass.name).to eq('FooWithCAPITALS')
        end
      end
    end

    context 'when class is defined inside module' do
      context 'when class Bar::FooInsideBar is defined in "bar/foo_inside_bar.rb"' do
        let :filename do
          'bar/foo_inside_bar.rb'
        end

        let :file_content do
          <<~EOS
            module Bar
              class FooInsideBar < ActiveRecord::Base
              end
            end
          EOS
        end

        it 'works' do
          expect(klass.name).to eq('Bar::FooInsideBar')
        end
      end
    end

    context 'when class is defined inside module and class name is not capitalized normally' do
      context 'when class Bar::FooInsideCapitalsBAR is defined in "bar/foo_inside_capitals_bar.rb"' do
        let :filename do
          'bar/foo_inside_capitals_bar.rb'
        end

        let :file_content do
          <<~EOS
            module BAR
              class FooInsideCapitalsBAR < ActiveRecord::Base
              end
            end
          EOS
        end

        it 'works' do
          expect(klass.name).to eq('BAR::FooInsideCapitalsBAR')
        end
      end
    end

    context 'when unknown macros exist in class' do
      context 'when class FooWithMacro is defined in "foo_with_macro.rb"' do
        let :filename do
          'foo_with_macro.rb'
        end

        let :file_content do
          <<~EOS
            class FooWithMacro < ActiveRecord::Base
              acts_as_awesome :yah
            end
          EOS
        end

        it 'works and does not care about known macros' do
          expect(klass.name).to eq('FooWithMacro')
        end
      end

      context 'when class name is with ALL CAPS segments' do
        context 'when class is "FooWithCAPITALS" is defined in "foo_with_capitals.rb"' do
          let :filename do
            'foo_with_capitals.rb'
          end

          let :file_content do
            <<~EOS
              class FooWithCAPITALS < ActiveRecord::Base
                acts_as_awesome :yah
              end
            EOS
          end

          it 'works' do
            expect(klass.name).to eq('FooWithCAPITALS')
          end
        end
      end
    end

    context 'when known macros exist in class' do
      context 'when class FooWithKnownMacro is defined in "foo_with_known_macro.rb"' do
        let :filename do
          'foo_with_known_macro.rb'
        end

        let :file_content do
          <<~EOS
            class FooWithKnownMacro < ActiveRecord::Base
              has_many :yah
            end
          EOS
        end

        it 'works and does not care about known macros' do
          expect(klass.name).to eq('FooWithKnownMacro')
        end
      end
    end

    context 'when the file includes invalid multibyte chars (USASCII)' do
      context 'when class FooWithUtf8 is defined in "foo_with_utf8.rb"' do
        let :filename do
          'foo_with_utf8.rb'
        end

        let :file_content do
          <<~EOS
            # encoding: utf-8
            class FooWithUtf8 < ActiveRecord::Base
              UTF8STRINGS = %w[résumé façon âge]
            end
          EOS
        end

        it 'works without complaining of invalid multibyte chars' do
          expect(klass.name).to eq('FooWithUtf8')
        end
      end
    end

    context 'when non-namespaced model is inside subdirectory' do
      context 'when class NonNamespacedFooInsideBar is defined in "bar/non_namespaced_foo_inside_bar.rb"' do
        let :filename do
          'bar/non_namespaced_foo_inside_bar.rb'
        end

        let :file_content do
          <<~EOS
            class NonNamespacedFooInsideBar < ActiveRecord::Base
            end
          EOS
        end

        it 'works' do
          expect(klass.name).to eq('NonNamespacedFooInsideBar')
        end
      end

      context 'when class name is not capitalized normally' do
        context 'when class NonNamespacedFooWithCapitalsInsideBar is defined in "bar/non_namespaced_foo_with_capitals_inside_bar.rb"' do
          let :filename do
            'bar/non_namespaced_foo_with_capitals_inside_bar.rb'
          end

          let :file_content do
            <<~EOS
              class NonNamespacedFooWithCapitalsInsideBar < ActiveRecord::Base
              end
            EOS
          end

          it 'works' do
            expect(klass.name).to eq('NonNamespacedFooWithCapitalsInsideBar')
          end
        end
      end
    end

    context 'when class file is loaded twice' do
      context 'when class LoadedClass is defined in "loaded_class.rb"' do
        let :filename do
          'loaded_class.rb'
        end

        let :file_content do
          <<~EOS
            class LoadedClass < ActiveRecord::Base
              CONSTANT = 1
            end
          EOS
        end

        before :each do
          path = File.expand_path(filename, AnnotateModels.model_dir[0])
          Kernel.load(path)
          expect(Kernel).not_to receive(:require)
        end

        it 'does not require model file twice' do
          expect(klass.name).to eq('LoadedClass')
        end
      end

      context 'when class is defined in a subdirectory' do
        dir = Array.new(8) { (0..9).to_a.sample(random: Random.new) }.join

        context "when class SubdirLoadedClass is defined in \"#{dir}/subdir_loaded_class.rb\"" do
          before :each do
            $LOAD_PATH.unshift(File.join(AnnotateModels.model_dir[0], dir))

            path = File.expand_path(filename, AnnotateModels.model_dir[0])
            Kernel.load(path)
            expect(Kernel).not_to receive(:require)
          end

          let :filename do
            "#{dir}/subdir_loaded_class.rb"
          end

          let :file_content do
            <<~EOS
              class SubdirLoadedClass < ActiveRecord::Base
                CONSTANT = 1
              end
            EOS
          end

          it 'does not require model file twice' do
            expect(klass.name).to eq('SubdirLoadedClass')
          end
        end
      end
    end

    context 'when two class exist' do
      before :each do
        create(filename_2, file_content_2)
      end

      context 'the base names are duplicated' do
        let :filename do
          'foo.rb'
        end

        let :file_content do
          <<-EOS
            class Foo < ActiveRecord::Base
            end
          EOS
        end

        let :filename_2 do
          'bar/foo.rb'
        end

        let :file_content_2 do
          <<-EOS
            class Bar::Foo < ActiveRecord::Base
            end
          EOS
        end

        let :klass_2 do
          AnnotateModels.get_model_class(File.join(AnnotateModels.model_dir[0], filename_2))
        end

        it 'finds valid model' do
          expect(klass.name).to eq('Foo')
          expect(klass_2.name).to eq('Bar::Foo')
        end
      end

      context 'the class name and base name clash' do
        let :filename do
          'foo.rb'
        end

        let :file_content do
          <<-EOS
            class Foo < ActiveRecord::Base
            end
          EOS
        end

        let :filename_2 do
          'bar/foo.rb'
        end

        let :file_content_2 do
          <<-EOS
            class Bar::Foo < ActiveRecord::Base
            end
          EOS
        end

        let :klass_2 do
          AnnotateModels.get_model_class(File.join(AnnotateModels.model_dir[0], filename_2))
        end

        it 'finds valid model' do
          expect(klass.name).to eq('Foo')
          expect(klass_2.name).to eq('Bar::Foo')
        end

        it 'attempts to load the model path without expanding if skip_subdirectory_model_load is false' do
          allow(AnnotateModels).to receive(:skip_subdirectory_model_load).and_return(false)
          full_path = File.join(AnnotateModels.model_dir[0], filename_2)
          expect(File).to_not receive(:expand_path).with(full_path)
          AnnotateModels.get_model_class(full_path)
        end

        it 'does not attempt to load the model path without expanding if skip_subdirectory_model_load is true' do
          $LOAD_PATH.unshift(AnnotateModels.model_dir[0])
          allow(AnnotateModels).to receive(:skip_subdirectory_model_load).and_return(true)
          full_path = File.join(AnnotateModels.model_dir[0], filename_2)
          expect(File).to receive(:expand_path).with(full_path).and_call_original
          AnnotateModels.get_model_class(full_path)
        end
      end

      context 'one of the classes is nested in another class' do
        let :filename do
          'voucher.rb'
        end

        let :file_content do
          <<-EOS
            class Voucher < ActiveRecord::Base
            end
          EOS
        end

        let :filename_2 do
          'voucher/foo.rb'
        end

        let :file_content_2 do
          <<~EOS
            class Voucher
              class Foo < ActiveRecord::Base
              end
            end
          EOS
        end

        let :klass_2 do
          AnnotateModels.get_model_class(File.join(AnnotateModels.model_dir[0], filename_2))
        end

        it 'finds valid model' do
          expect(klass.name).to eq('Voucher')
          expect(klass_2.name).to eq('Voucher::Foo')
        end
      end
    end
  end

  describe '.remove_annotation_of_file' do
    subject do
      AnnotateModels.remove_annotation_of_file(path)
    end

    let :tmpdir do
      Dir.mktmpdir('annotate_models')
    end

    let :path do
      File.join(tmpdir, filename).tap do |path|
        File.open(path, 'w') do |f|
          f.puts(file_content)
        end
      end
    end

    let :file_content_after_removal do
      subject
      File.read(path)
    end

    let :expected_result do
      <<~EOS
        class Foo < ActiveRecord::Base
        end
      EOS
    end

    context 'when annotation is before main content' do
      let :filename do
        'before.rb'
      end

      let :file_content do
        <<~EOS
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
      end

      it 'removes annotation' do
        expect(file_content_after_removal).to eq expected_result
      end
    end

    context 'when annotation is before main content and CRLF is used for line breaks' do
      let :filename do
        'before.rb'
      end

      let :file_content do
        <<~EOS
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
      end

      it 'removes annotation' do
        expect(file_content_after_removal).to eq expected_result
      end
    end

    context 'when annotation is before main content and with opening wrapper' do
      let :filename do
        'opening_wrapper.rb'
      end

      let :file_content do
        <<~EOS
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
      end

      subject do
        AnnotateModels.remove_annotation_of_file(path, wrapper_open: 'wrapper')
      end

      it 'removes annotation' do
        expect(file_content_after_removal).to eq expected_result
      end
    end

    context 'when annotation is before main content and with opening wrapper' do
      let :filename do
        'opening_wrapper.rb'
      end

      let :file_content do
        <<~EOS
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
      end

      subject do
        AnnotateModels.remove_annotation_of_file(path, wrapper_open: 'wrapper')
      end

      it 'removes annotation' do
        expect(file_content_after_removal).to eq expected_result
      end
    end

    context 'when annotation is after main content' do
      let :filename do
        'after.rb'
      end

      let :file_content do
        <<~EOS
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
      end

      it 'removes annotation' do
        expect(file_content_after_removal).to eq expected_result
      end
    end

    context 'when annotation is after main content and with closing wrapper' do
      let :filename do
        'closing_wrapper.rb'
      end

      let :file_content do
        <<~EOS
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
      end

      subject do
        AnnotateModels.remove_annotation_of_file(path, wrapper_close: 'wrapper')
      end

      it 'removes annotation' do
        expect(file_content_after_removal).to eq expected_result
      end
    end

    context 'when annotation is before main content and with comment "-*- SkipSchemaAnnotations"' do
      let :filename do
        'skip.rb'
      end

      let :file_content do
        <<~EOS
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
      end

      let :expected_result do
        file_content
      end

      it 'does not remove annotation' do
        expect(file_content_after_removal).to eq expected_result
      end
    end
  end

  describe '.resolve_filename' do
    subject do
      AnnotateModels.resolve_filename(filename_template, model_name, table_name)
    end

    context 'When model_name is "example_model" and table_name is "example_models"' do
      let(:model_name) { 'example_model' }
      let(:table_name) { 'example_models' }

      context "when filename_template is 'test/unit/%MODEL_NAME%_test.rb'" do
        let(:filename_template) { 'test/unit/%MODEL_NAME%_test.rb' }

        it 'returns the test path for a model' do
          is_expected.to eq 'test/unit/example_model_test.rb'
        end
      end

      context "when filename_template is '/foo/bar/%MODEL_NAME%/testing.rb'" do
        let(:filename_template) { '/foo/bar/%MODEL_NAME%/testing.rb' }

        it 'returns the additional glob' do
          is_expected.to eq '/foo/bar/example_model/testing.rb'
        end
      end

      context "when filename_template is '/foo/bar/%PLURALIZED_MODEL_NAME%/testing.rb'" do
        let(:filename_template) { '/foo/bar/%PLURALIZED_MODEL_NAME%/testing.rb' }

        it 'returns the additional glob' do
          is_expected.to eq '/foo/bar/example_models/testing.rb'
        end
      end

      context "when filename_template is 'test/fixtures/%TABLE_NAME%.yml'" do
        let(:filename_template) { 'test/fixtures/%TABLE_NAME%.yml' }

        it 'returns the fixture path for a model' do
          is_expected.to eq 'test/fixtures/example_models.yml'
        end
      end
    end

    context 'When model_name is "parent/child" and table_name is "parent_children"' do
      let(:model_name) { 'parent/child' }
      let(:table_name) { 'parent_children' }

      context "when filename_template is 'test/fixtures/%PLURALIZED_MODEL_NAME%.yml'" do
        let(:filename_template) { 'test/fixtures/%PLURALIZED_MODEL_NAME%.yml' }

        it 'returns the fixture path for a nested model' do
          is_expected.to eq 'test/fixtures/parent/children.yml'
        end
      end
    end
  end

  describe 'annotating a file' do
    before do
      @model_dir = Dir.mktmpdir('annotate_models')
      (@model_file_name, @file_content) = write_model 'user.rb', <<~EOS
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
      Annotate::Helpers.reset_options(Annotate::Constants::ALL_ANNOTATE_OPTIONS)
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
      Annotate::Constants::POSITION_OPTIONS.each { |key| ENV[key.to_s] = '' }
      Annotate::Constants::FLAG_OPTIONS.each { |key| ENV[key.to_s] = '' }
      Annotate::Constants::PATH_OPTIONS.each { |key| ENV[key.to_s] = '' }
    end

    ['before', :before, 'top', :top].each do |position|
      it "should put annotation before class if :position == #{position}" do
        annotate_one_file position: position
        expect(File.read(@model_file_name))
          .to eq("#{@schema_info}#{@file_content}")
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
        .to eq("# START\n#{@schema_info}# END\n#{@file_content}")
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
        expect(File.read(@model_file_name)).to eq("#{@file_content}\n#{@schema_info}\n")
      end

      it 'should retain current position even when :position is changed to :before' do
        annotate_one_file position: :before
        expect(File.read(@model_file_name)).to eq("#{@file_content}\n#{@schema_info}\n")
      end

      it 'should change position to :before when force: true' do
        annotate_one_file position: :before, force: true
        expect(File.read(@model_file_name)).to eq("#{@schema_info}#{@file_content}")
      end
    end

    it 'should skip columns with option[:ignore_columns] set' do
      output = AnnotateModels.get_schema_info(@klass, '== Schema Info',
                                              :ignore_columns => '(id|updated_at|created_at)')
      expect(output.match(/id/)).to be_nil
    end

    it 'works with namespaced models (i.e. models inside modules/subdirectories)' do
      (model_file_name, file_content) = write_model 'foo/user.rb', <<~EOS
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
      expect(File.read(model_file_name)).to eq("#{schema_info}#{file_content}")
    end

    it 'should not touch magic comments' do
      MAGIC_COMMENTS.each do |magic_comment|
        write_model 'user.rb', <<~EOS
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
      MAGIC_COMMENTS.each do |magic_comment|
        model_file_name, = write_model 'user.rb', "#{magic_comment}\n#{content}"

        annotate_one_file position: :before
        schema_info = AnnotateModels.get_schema_info(@klass, '== Schema Info')

        expect(File.read(model_file_name)).to eq("#{magic_comment}\n\n#{schema_info}#{content}")
      end
    end

    it 'only keeps a single empty line around the annotation (position :before)' do
      content = "class User < ActiveRecord::Base\nend\n"
      MAGIC_COMMENTS.each do |magic_comment|
        schema_info = AnnotateModels.get_schema_info(@klass, '== Schema Info')
        model_file_name, = write_model 'user.rb', "#{magic_comment}\n\n\n\n#{content}"

        annotate_one_file position: :before

        expect(File.read(model_file_name)).to eq("#{magic_comment}\n\n#{schema_info}#{content}")
      end
    end

    it 'does not change whitespace between magic comments and model file content (position :after)' do
      content = "class User < ActiveRecord::Base\nend\n"
      MAGIC_COMMENTS.each do |magic_comment|
        model_file_name, = write_model 'user.rb', "#{magic_comment}\n#{content}"

        annotate_one_file position: :after
        schema_info = AnnotateModels.get_schema_info(@klass, '== Schema Info')

        expect(File.read(model_file_name)).to eq("#{magic_comment}\n#{content}\n#{schema_info}")
      end
    end

    describe "if a file can't be annotated" do
      before do
        allow(AnnotateModels).to receive(:get_loaded_model_by_path).with('user').and_return(nil)

        write_model('user.rb', <<~EOS)
          class User < ActiveRecord::Base
            raise "oops"
          end
        EOS
      end

      it 'displays just the error message with trace disabled (default)' do
        expect { AnnotateModels.do_annotations model_dir: @model_dir, is_rake: true }.to output(a_string_including("Unable to annotate #{@model_dir}/user.rb: oops")).to_stderr
        expect { AnnotateModels.do_annotations model_dir: @model_dir, is_rake: true }.not_to output(a_string_including('/spec/annotate/annotate_models_spec.rb:')).to_stderr
      end

      it 'displays the error message and stacktrace with trace enabled' do
        expect { AnnotateModels.do_annotations model_dir: @model_dir, is_rake: true, trace: true }.to output(a_string_including("Unable to annotate #{@model_dir}/user.rb: oops")).to_stderr
        expect { AnnotateModels.do_annotations model_dir: @model_dir, is_rake: true, trace: true }.to output(a_string_including('/spec/lib/annotate/annotate_models_spec.rb:')).to_stderr
      end
    end

    describe "if a file can't be deannotated" do
      before do
        allow(AnnotateModels).to receive(:get_loaded_model_by_path).with('user').and_return(nil)

        write_model('user.rb', <<~EOS)
          class User < ActiveRecord::Base
            raise "oops"
          end
        EOS
      end

      it 'displays just the error message with trace disabled (default)' do
        expect { AnnotateModels.remove_annotations model_dir: @model_dir, is_rake: true }.to output(a_string_including("Unable to deannotate #{@model_dir}/user.rb: oops")).to_stderr
        expect { AnnotateModels.remove_annotations model_dir: @model_dir, is_rake: true }.not_to output(a_string_including("/user.rb:2:in `<class:User>'")).to_stderr
      end

      it 'displays the error message and stacktrace with trace enabled' do
        expect { AnnotateModels.remove_annotations model_dir: @model_dir, is_rake: true, trace: true }.to output(a_string_including("Unable to deannotate #{@model_dir}/user.rb: oops")).to_stderr
        expect { AnnotateModels.remove_annotations model_dir: @model_dir, is_rake: true, trace: true }.to output(a_string_including("/user.rb:2:in `<class:User>'")).to_stderr
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

    subject do
      AnnotateModels.annotate_model_file([], 'foo.rb', nil, {})
    end

    after { Object.send :remove_const, 'Foo' }

    it 'skips attempt to annotate if no table exists for model' do
      is_expected.to eq nil
    end

    context 'with a non-class' do
      before do
        NotAClass = 'foo'.freeze # rubocop:disable Naming/ConstantName
        allow(AnnotateModels).to receive(:get_model_class).with('foo.rb') { NotAClass }
      end

      after { Object.send :remove_const, 'NotAClass' }

      it "doesn't output an error" do
        expect { subject }.not_to output.to_stderr
      end
    end
  end
end
