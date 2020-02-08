require_relative '../../../spec_helper'
require 'annotate/annotate_models'

describe AnnotateModels::SchemaInfo do
  describe '.generate' do
    subject do
      AnnotateModels::SchemaInfo.generate(klass, header, **options)
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

  describe 'private methods' do
    describe '.quote' do
      subject do
        AnnotateModels::SchemaInfo.send(:quote, value)
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
  end
end
