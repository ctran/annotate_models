# Smoke test to assure basic functionality works on a variety of Rails versions.
require 'files'
require 'wrong'
include Files
include Wrong::D

describe "annotate inside Rails" do
 here = File.expand_path(File.dirname __FILE__)
 ['3.2', '2.3'].each do |base_version|
  it "works under Rails #{base_version}" do
   base_dir = "rails-#{base_version}"
   gemfile = "#{here}/#{base_dir}.gems"
   annotate_bin = File.expand_path "#{here}/../../bin/annotate"
  
   Bundler.with_clean_env do
    dir base_dir do
      temp_dir = Dir.pwd
      File.basename(Dir.pwd).should == base_dir
      rails_cmd = "#{temp_dir}/rails"

      case base_version
      when /^2\./
        new_cmd = "#{rails_cmd}"
        generate_cmd = "script/generate"
        
      when /^3\./
        new_cmd = "#{rails_cmd} new"
        generate_cmd = "#{rails_cmd} generate"
      end
      
      # todo: optionally use rvm
      `bundle install  --binstubs=#{temp_dir} --gemfile #{gemfile}`.should =~ /Your bundle is complete/
      rails_version = `#{rails_cmd} -v`.chomp
      rails_version.should =~ /^Rails/
      rails_version = rails_version.split(" ").last
      rails_version.should =~ /(\d+)(\.\d+)*/
      rails_version.should =~ /^#{base_version}/

      `#{new_cmd} todo`
      Dir.chdir("#{temp_dir}/todo") do
        `#{generate_cmd} scaffold Task content:string`.should =~ %r{db/migrate/.*_create_tasks.rb}
        `../rake db:migrate`.should =~ /CreateTasks: migrated/
        File.read("app/models/task.rb").should == "class Task < ActiveRecord::Base\nend\n"
        `#{annotate_bin}`.chomp.should == "Annotated (1): Task"
        File.read("app/models/task.rb").should == <<-RUBY
# == Schema Information
#
# Table name: tasks
#
#  content    :string(255)
#  created_at :datetime         not null
#  id         :integer          not null, primary key
#  updated_at :datetime         not null
#

class Task < ActiveRecord::Base
end
        RUBY
      end
    end
   end
  end
 end
end