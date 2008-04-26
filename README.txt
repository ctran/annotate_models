== AnnotateModels

Add a comment summarizing the current schema to the top of each ActiveRecord model source file.

  # == Schema Information
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

  sudo gem install annotate-models
  
== Usage

  cd [your project]
  annotate
  annotate -d
  annotate -p [before|after]
  annotate -h

== Source

  http://github.com/ctran/annotate_models
  
== Author
   Dave Thomas
   Pragmatic Programmers, LLC

Released under the same license as Ruby. No Support. No Warranty. 

== Modifications
 - alex@pivotallabs.com
 - Cuong Tran - http://github.com/ctran
 - Jack Danger - http://github.com/JackDanger
 - Michael Bumann - http://github.com/bumi
 - Henrik Nyh - http://github.com/henrik
