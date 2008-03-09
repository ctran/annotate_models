== AnnotateModels

Add a comment summarizing the current schema to the top of each ActiveRecord model source file.

  # Schema as of Sun Feb 26 21:58:32 CST 2006 (schema version 7)
  #
  #  id                  :integer(11)   not null
  #  quantity            :integer(11)   
  #  product_id          :integer(11)   
  #  unit_price          :float         
  #  order_id            :integer(11)   
  #

  class LineItem < ActiveRecord::Base 
    belongs_to :product
  
   end
  
Note that this code will blow away the initial comment block in your models if it looks like it was 
previously added by annotate models, so you don't want to add additional text to an automatically 
created comment block.

== Install

  sudo gem install sake annotate-models
  
== Usage

  cd [your project]
  annotate

== Source

  http://github.com/ctran/annotate_models
  
  
== Author
   Dave Thomas
   Pragmatic Programmers, LLC

Released under the same license as Ruby. No Support. No Warranty. 


== Modifications
 - alex@pivotallabs.com
 - ctran@pragmaquest.com
