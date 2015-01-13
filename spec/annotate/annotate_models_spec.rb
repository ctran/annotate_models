#encoding: utf-8
require File.dirname(__FILE__) + '/../spec_helper.rb'
require 'annotate/annotate_models'
require 'annotate/active_record_patch'

describe AnnotateModels do
  def mock_class(table_name, primary_key, columns)
    options = {
      :connection   => double("Conn", :indexes => []),
      :table_name   => table_name,
      :primary_key  => primary_key,
      :column_names => columns.map { |col| col.name.to_s },
      :columns      => columns
    }

    double("An ActiveRecord class", options)
  end

  def mock_column(name, type, options={})
    default_options = {
      :limit   => nil,
      :null    => false,
      :default => nil
    }

    stubs = default_options.dup
    stubs.merge!(options)
    stubs.merge!(:name => name, :type => type)

    double("Column", stubs)
  end

  it { expect(AnnotateModels.quote(nil)).to eql("NULL") }
  it { expect(AnnotateModels.quote(true)).to eql("TRUE") }
  it { expect(AnnotateModels.quote(false)).to eql("FALSE") }
  it { expect(AnnotateModels.quote(25)).to eql("25") }
  it { expect(AnnotateModels.quote(25.6)).to eql("25.6") }
  it { expect(AnnotateModels.quote(1e-20)).to eql("1.0e-20") }

  it "should get schema info" do
    klass = mock_class(:users, :id, [
                                     mock_column(:id, :integer),
                                     mock_column(:name, :string, :limit => 50)
                                    ])

    expect(AnnotateModels.get_schema_info(klass, "Schema Info")).to eql(<<-EOS)
# Schema Info
#
# Table name: users
#
#  id   :integer          not null, primary key
#  name :string(50)       not null
#
EOS
  end

  it "should get schema info even if the primary key is not set" do
    klass = mock_class(:users, nil, [
                                     mock_column(:id, :integer),
                                     mock_column(:name, :string, :limit => 50)
                                    ])

    expect(AnnotateModels.get_schema_info(klass, "Schema Info")).to eql(<<-EOS)
# Schema Info
#
# Table name: users
#
#  id   :integer          not null
#  name :string(50)       not null
#
EOS
  end

  it "should get schema info even if the primary key is array, if using composite_primary_keys" do
    klass = mock_class(:users, [:a_id, :b_id], [
                                     mock_column(:a_id, :integer),
                                     mock_column(:b_id, :integer),
                                     mock_column(:name, :string, :limit => 50)
                                    ])

    expect(AnnotateModels.get_schema_info(klass, "Schema Info")).to eql(<<-EOS)
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
  it "should get schema info with enum type " do
    klass = mock_class(:users, nil, [
                                     mock_column(:id, :integer),
                                     mock_column(:name, :enum, :limit => [:enum1, :enum2])
                                    ])

    expect(AnnotateModels.get_schema_info(klass, "Schema Info")).to eql(<<-EOS)
# Schema Info
#
# Table name: users
#
#  id   :integer          not null
#  name :enum             not null, (enum1, enum2)
#
EOS
  end

  it "should get schema info as RDoc" do
    klass = mock_class(:users, :id, [
                                     mock_column(:id, :integer),
                                     mock_column(:name, :string, :limit => 50)
                                    ])
    expect(AnnotateModels.get_schema_info(klass, AnnotateModels::PREFIX, :format_rdoc => true)).to eql(<<-EOS)
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

  describe "#get_model_class" do
    require "tmpdir"

    module ::ActiveRecord
      class Base
        def self.has_many name
        end
      end
    end

    # todo: use 'files' gem instead
    def create(file, body="hi")
      file_path = File.join(AnnotateModels.model_dir, file)
      FileUtils.mkdir_p(File.dirname(file_path))

      File.open(file_path, "wb") do |f|
        f.puts(body)
      end
      file_path
    end

    def check_class_name(file, class_name)
      klass = AnnotateModels.get_model_class(file)

      expect(klass).not_to eq(nil)
      expect(klass.name).to eq(class_name)
    end

    before :each do
      AnnotateModels.model_dir = Dir.mktmpdir 'annotate_models'
    end

    it "should work" do
      create 'foo.rb', <<-EOS
        class Foo < ActiveRecord::Base
        end
      EOS
      check_class_name 'foo.rb', 'Foo'
    end

    it "should find models with non standard capitalization" do
      create 'foo_with_capitals.rb', <<-EOS
        class FooWithCAPITALS < ActiveRecord::Base
        end
      EOS
      check_class_name 'foo_with_capitals.rb', 'FooWithCAPITALS'
    end

    it "should find models inside modules" do
      create 'bar/foo_inside_bar.rb', <<-EOS
        module Bar
          class FooInsideBar < ActiveRecord::Base
          end
        end
      EOS
      check_class_name 'bar/foo_inside_bar.rb', 'Bar::FooInsideBar'
    end

    it "should find AR model when duplicated by a nested model" do
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

    it "should find AR model nested inside a class" do
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


    it "should not care about unknown macros" do
      create 'foo_with_macro.rb', <<-EOS
        class FooWithMacro < ActiveRecord::Base
          acts_as_awesome :yah
        end
      EOS
      check_class_name 'foo_with_macro.rb', 'FooWithMacro'
    end

    it "should not care about known macros" do
      create('foo_with_known_macro.rb', <<-EOS)
        class FooWithKnownMacro < ActiveRecord::Base
          has_many :yah
        end
      EOS
      check_class_name 'foo_with_known_macro.rb', 'FooWithKnownMacro'
    end

    it "should work with class names with ALL CAPS segments" do
      create('foo_with_capitals.rb', <<-EOS)
        class FooWithCAPITALS < ActiveRecord::Base
          acts_as_awesome :yah
          end
        EOS
      check_class_name 'foo_with_capitals.rb', 'FooWithCAPITALS'
    end

    it "should not complain of invalid multibyte char (USASCII)" do
      create 'foo_with_utf8.rb', <<-EOS
        #encoding: utf-8
        class FooWithUtf8 < ActiveRecord::Base
          UTF8STRINGS = %w[résumé façon âge]
        end
      EOS
      check_class_name 'foo_with_utf8.rb', 'FooWithUtf8'
    end

    it "should find models inside modules with non standard capitalization" do
      create 'bar/foo_inside_capitals_bar.rb', <<-EOS
        module BAR
          class FooInsideCapitalsBAR < ActiveRecord::Base
          end
        end
      EOS
      check_class_name 'bar/foo_inside_capitals_bar.rb', 'BAR::FooInsideCapitalsBAR'
    end

    it "should find non-namespaced models inside subdirectories" do
      create 'bar/non_namespaced_foo_inside_bar.rb', <<-EOS
        class NonNamespacedFooInsideBar < ActiveRecord::Base
        end
      EOS
      check_class_name 'bar/non_namespaced_foo_inside_bar.rb', 'NonNamespacedFooInsideBar'
    end

    it "should find non-namespaced models with non standard capitalization inside subdirectories" do
      create 'bar/non_namespaced_foo_with_capitals_inside_bar.rb', <<-EOS
        class NonNamespacedFooWithCapitalsInsideBar < ActiveRecord::Base
        end
      EOS
      check_class_name 'bar/non_namespaced_foo_with_capitals_inside_bar.rb', 'NonNamespacedFooWithCapitalsInsideBar'
    end

    it "should allow known macros" do
      create('foo_with_known_macro.rb', <<-EOS)
        class FooWithKnownMacro < ActiveRecord::Base
          has_many :yah
        end
      EOS
      expect(capturing(:stderr) do
        check_class_name 'foo_with_known_macro.rb', 'FooWithKnownMacro'
      end).to eq("")
    end

    it "should not require model files twice" do
      create 'loaded_class.rb', <<-EOS
        class LoadedClass < ActiveRecord::Base
          CONSTANT = 1
        end
      EOS
      path = File.expand_path("#{AnnotateModels.model_dir}/loaded_class")
      Kernel.load "#{path}.rb"
      expect(Kernel).not_to receive(:require).with(path)

      expect(capturing(:stderr) {
        check_class_name 'loaded_class.rb', 'LoadedClass'
      }).not_to include("warning: already initialized constant LoadedClass::CONSTANT")
    end
  end

  describe "#remove_annotation_of_file" do
    require "tmpdir"

    def create(file, body="hi")
      path = File.join(@dir, file)
      File.open(path, "w") do |f|
        f.puts(body)
      end
      return path
    end

    def content(path)
      File.read(path)
    end

    before :each do
      @dir = Dir.mktmpdir 'annotate_models'
    end

    it "should remove before annotate" do
      path = create "before.rb", <<-EOS
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

    it "should remove after annotate" do
      path = create "after.rb", <<-EOS
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
  end

  describe "annotating a file" do
    before do
      @model_dir = Dir.mktmpdir('annotate_models')
      (@model_file_name, @file_content) = write_model "user.rb", <<-EOS
class User < ActiveRecord::Base
end
      EOS

      @klass = mock_class(:users, :id, [
                                        mock_column(:id, :integer),
                                        mock_column(:name, :string, :limit => 50)
                                       ])
      @schema_info = AnnotateModels.get_schema_info(@klass, "== Schema Info")
    end

    def write_model file_name, file_content
      fname = File.join(@model_dir, file_name)
      FileUtils.mkdir_p(File.dirname(fname))
      File.open(fname, "wb") { |f| f.write file_content }
      return fname, file_content
    end

    def annotate_one_file options = {}
      Annotate.set_defaults(options)
      options = Annotate.setup_options(options)
      AnnotateModels.annotate_one_file(@model_file_name, @schema_info, :position_in_class, options)

      # Wipe settings so the next call will pick up new values...
      Annotate.instance_variable_set('@has_set_defaults', false)
      Annotate::POSITION_OPTIONS.each { |key| ENV[key.to_s] = '' }
      Annotate::FLAG_OPTIONS.each { |key| ENV[key.to_s] = '' }
      Annotate::PATH_OPTIONS.each { |key| ENV[key.to_s] = '' }
    end

    def encoding_comments_list_each
      [
        '# encoding: UTF-8',
        '# coding: UTF-8',
        '# -*- coding: UTF-8 -*-',
        '#encoding: utf-8',
        '# -*- encoding : utf-8 -*-'
      ].each{|encoding_comment| yield encoding_comment }
    end

    it "should put annotation before class if :position == 'before'" do
      annotate_one_file :position => "before"
      expect(File.read(@model_file_name)).to eq("#{@schema_info}\n#{@file_content}")
    end

    it "should put annotation before class if :position => :before" do
      annotate_one_file :position => :before
      expect(File.read(@model_file_name)).to eq("#{@schema_info}\n#{@file_content}")
    end

    it "should put annotation before class if :position == 'top'" do
      annotate_one_file :position => "top"
      expect(File.read(@model_file_name)).to eq("#{@schema_info}\n#{@file_content}")
    end

    it "should put annotation before class if :position => :top" do
      annotate_one_file :position => :top
      expect(File.read(@model_file_name)).to eq("#{@schema_info}\n#{@file_content}")
    end

    it "should put annotation after class if :position => 'after'" do
      annotate_one_file :position => 'after'
      expect(File.read(@model_file_name)).to eq("#{@file_content}\n#{@schema_info}")
    end

    it "should put annotation after class if :position => :after" do
      annotate_one_file :position => :after
      expect(File.read(@model_file_name)).to eq("#{@file_content}\n#{@schema_info}")
    end

    it "should put annotation after class if :position => 'bottom'" do
      annotate_one_file :position => 'bottom'
      expect(File.read(@model_file_name)).to eq("#{@file_content}\n#{@schema_info}")
    end

    it "should put annotation after class if :position => :bottom" do
      annotate_one_file :position => :bottom
      expect(File.read(@model_file_name)).to eq("#{@file_content}\n#{@schema_info}")
    end

    it 'should wrap annotation if wrapper is specified' do
      annotate_one_file :wrapper_beg => 'START', :wrapper_end => 'END'
      expect(File.read(@model_file_name)).to eq("START\n#{@schema_info}\nEND\n#{@file_content}")
    end

    describe "with existing annotation => :before" do
      before do
        annotate_one_file :position => :before
        another_schema_info = AnnotateModels.get_schema_info(mock_class(:users, :id, [mock_column(:id, :integer),]),
                                                           "== Schema Info")
        @schema_info = another_schema_info
      end

      it "should retain current position" do
        annotate_one_file
        expect(File.read(@model_file_name)).to eq("#{@schema_info}\n#{@file_content}")
      end

      it "should retain current position even when :position is changed to :after" do
        annotate_one_file :position => :after
        expect(File.read(@model_file_name)).to eq("#{@schema_info}\n#{@file_content}")
      end

      it "should change position to :after when :force => true" do
        annotate_one_file :position => :after, :force => true
        expect(File.read(@model_file_name)).to eq("#{@file_content}\n#{@schema_info}")
      end
    end

    describe "with existing annotation => :after" do
      before do
        annotate_one_file :position => :after
        another_schema_info = AnnotateModels.get_schema_info(mock_class(:users, :id, [mock_column(:id, :integer),]),
                                                           "== Schema Info")
        @schema_info = another_schema_info
      end

      it "should retain current position" do
        annotate_one_file
        expect(File.read(@model_file_name)).to eq("#{@file_content}\n#{@schema_info}")
      end

      it "should retain current position even when :position is changed to :before" do
        annotate_one_file :position => :before
        expect(File.read(@model_file_name)).to eq("#{@file_content}\n#{@schema_info}")
      end

      it "should change position to :before when :force => true" do
        annotate_one_file :position => :before, :force => true
        expect(File.read(@model_file_name)).to eq("#{@schema_info}\n#{@file_content}")
      end
    end

    it 'should skip columns with option[:ignore_columns] set' do
      output = AnnotateModels.get_schema_info(@klass, "== Schema Info",
                                              :ignore_columns => '(id|updated_at|created_at)')
      expect(output.match(/id/)).to be_nil
    end

    it "works with namespaced models (i.e. models inside modules/subdirectories)" do
      (model_file_name, file_content) = write_model "foo/user.rb", <<-EOS
class Foo::User < ActiveRecord::Base
end
      EOS

      klass = mock_class(:'foo_users', :id, [
                                        mock_column(:id, :integer),
                                        mock_column(:name, :string, :limit => 50)
                                       ])
      schema_info = AnnotateModels.get_schema_info(klass, "== Schema Info")
      AnnotateModels.annotate_one_file(model_file_name, schema_info, :position => :before)
      expect(File.read(model_file_name)).to eq("#{schema_info}\n#{file_content}")
    end

    it "should not touch encoding comments" do
      encoding_comments_list_each do |encoding_comment|
        write_model "user.rb", <<-EOS
#{encoding_comment}
class User < ActiveRecord::Base
end
        EOS

        annotate_one_file :position => :before

        expect(File.open(@model_file_name, &:readline)).to eq("#{encoding_comment}\n")
      end
    end

    describe "if a file can't be annotated" do
       before do
         allow(AnnotateModels).to receive(:get_loaded_model).with('user').and_return(nil)

         write_model('user.rb', <<-EOS)
           class User < ActiveRecord::Base
             raise "oops"
           end
         EOS
       end

       it "displays an error message" do
         expect(capturing(:stdout) {
           AnnotateModels.do_annotations :model_dir => @model_dir, :is_rake => true
         }).to include("Unable to annotate user.rb: oops")
       end

       it "displays the full stack trace with --trace" do
         expect(capturing(:stdout) {
           AnnotateModels.do_annotations :model_dir => @model_dir, :trace => true, :is_rake => true
         }).to include("/spec/annotate/annotate_models_spec.rb:")
       end

       it "omits the full stack trace without --trace" do
         expect(capturing(:stdout) {
           AnnotateModels.do_annotations :model_dir => @model_dir, :trace => false, :is_rake => true
         }).not_to include("/spec/annotate/annotate_models_spec.rb:")
       end
    end

    describe "if a file can't be deannotated" do
       before do
         allow(AnnotateModels).to receive(:get_loaded_model).with('user').and_return(nil)

         write_model('user.rb', <<-EOS)
           class User < ActiveRecord::Base
             raise "oops"
           end
         EOS
       end

       it "displays an error message" do
         expect(capturing(:stdout) {
           AnnotateModels.remove_annotations :model_dir => @model_dir, :is_rake => true
         }).to include("Unable to deannotate user.rb: oops")
       end

       it "displays the full stack trace" do
         expect(capturing(:stdout) {
           AnnotateModels.remove_annotations :model_dir => @model_dir, :trace => true, :is_rake => true
         }).to include("/user.rb:2:in `<class:User>'")
       end

       it "omits the full stack trace without --trace" do
         expect(capturing(:stdout) {
           AnnotateModels.remove_annotations :model_dir => @model_dir, :trace => false, :is_rake => true
         }).not_to include("/user.rb:2:in `<class:User>'")
       end
    end
  end

  describe '.annotate_model_file' do
    before do
      class Foo < ActiveRecord::Base; end;
      allow(AnnotateModels).to receive(:get_model_class).with('foo.rb') { Foo }
      allow(Foo).to receive(:table_exists?) { false }
    end

    after { Object.send :remove_const, 'Foo' }

    it 'skips attempt to annotate if no table exists for model' do
      annotate_model_file = AnnotateModels.annotate_model_file([], 'foo.rb', nil, nil)

      expect(annotate_model_file).to eq nil
    end
  end
end
