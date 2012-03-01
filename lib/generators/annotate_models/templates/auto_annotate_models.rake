# This file was derived from a Rakefile described in this blog post:
# http://talklikeaduck.denhaven2.com/2011/01/29/automatic-annotation-with-rails-3-with-the-annotate-gem
# Position in class/fixture is either 'before' or 'after'

namespace :db do
  task :migrate do
    unless Rails.env.production?
      require "annotate/annotate_models"
      AnnotateModels.do_annotations(:position_in_class => 'after', :position_in_fixture => 'after')
    end
  end

  namespace :migrate do
    [:up, :down, :reset, :redo].each do |t|
      task t do
        unless Rails.env.production?
          require "annotate/annotate_models"
          AnnotateModels.do_annotations(:position_in_class => 'after', :position_in_fixture => 'after')
        end
      end
    end
  end
end
