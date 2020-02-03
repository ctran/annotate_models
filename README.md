## Annotate (aka AnnotateModels)

[![Gem Version](https://badge.fury.io/rb/annotate.svg)](http://badge.fury.io/rb/annotate)
[![Downloads count](https://img.shields.io/gem/dt/annotate.svg?style=flat)](https://rubygems.org/gems/annotate)
[![Build status](https://travis-ci.org/ctran/annotate_models.svg?branch=develop)](https://travis-ci.org/ctran/annotate_models)
[![CI Status](https://github.com/ctran/annotate_models/workflows/CI/badge.svg)](https://github.com/ctran/annotate_models/actions?workflow=CI)
[![Coveralls](https://coveralls.io/repos/ctran/annotate_models/badge.svg?branch=develop)](https://coveralls.io/r/ctran/annotate_models?branch=develop)
[![Maintenability](https://codeclimate.com/github/ctran/annotate_models/badges/gpa.svg)](https://codeclimate.com/github/ctran/annotate_models)
[![Inline docs](http://inch-ci.org/github/ctran/annotate_models.svg?branch=develop)](http://inch-ci.org/github/ctran/annotate_models)

Add a comment summarizing the current schema to the top or bottom of each of your...

- ActiveRecord models
- Fixture files
- Tests and Specs
- Object Daddy exemplars
- Machinist blueprints
- Fabrication fabricators
- Thoughtbot's factory_bot factories, i.e. the `(spec|test)/factories/<model>_factory.rb` files
- `routes.rb` file (for Rails projects)


The schema comment looks like this:

```ruby
# == Schema Info
#
# Table name: line_items
#
#  id                  :integer(11)    not null, primary key
#  quantity            :integer(11)    not null
#  product_id          :integer(11)    not null
#  unit_price          :float
#  order_id            :integer(11)
#

class LineItem < ActiveRecord::Base
  belongs_to :product
  . . .
```

It also annotates geometrical columns, `geom` type and `srid`,
when using `SpatialAdapter`, `PostgisAdapter` or `PostGISAdapter`:

```ruby
# == Schema Info
#
# Table name: trips
#
#  local           :geometry        point, 4326
#  path            :geometry        line_string, 4326
```

Also, if you pass the `-r` option, it'll annotate `routes.rb` with the output of `rake routes`.


## Upgrading to 3.X and annotate models not working?

In versions 2.7.X the annotate gem defaulted to annotating models if no arguments were passed in.
The annotate gem by default would not allow for routes and models to be annotated together.
A [change was added in #647](https://github.com/ctran/annotate_models/pull/647).
You [can read more here](https://github.com/ctran/annotate_models/issues/663).

There are a few ways of fixing this:

- If using CLI explicitly pass in models flag using `--models`

OR

a) Running `rails g annotate:install` will overwrite your defaults with the annotating `models` option set to `'true'`.

b) In `lib/tasks/auto_annotate_models.rake` add the `models` key-value option:

```ruby
    Annotate.set_defaults(
      ...
      'models'                      => 'true',
      ...
```

## Install

Into Gemfile from rubygems.org:

```ruby
group :development do
  gem 'annotate'
end
```

Into Gemfile from Github:

```ruby
group :development do
  gem 'annotate', git: 'https://github.com/ctran/annotate_models.git'
end
```

Into environment gems from rubygems.org:

    gem install annotate

Into environment gems from Github checkout:

    git clone https://github.com/ctran/annotate_models.git annotate_models
    cd annotate_models
    rake build
    gem install pkg/annotate-*.gem

## Usage

(If you used the Gemfile install, prefix the below commands with `bundle exec`.)

### Usage in Rails

To annotate all your models, tests, fixtures, and factories:

    cd /path/to/app
    annotate

To annotate just your models, tests, and factories:

    annotate --models --exclude fixtures

To annotate just your models:

    annotate --models

To annotate routes.rb:

    annotate --routes

To remove model/test/fixture/factory/serializer annotations:

    annotate --delete

To remove routes.rb annotations:

    annotate --routes --delete

To automatically annotate every time you run `db:migrate`,
either run `rails g annotate:install`
or add `Annotate.load_tasks` to your `Rakefile`.

See the [configuration in Rails](#configuration-in-rails) section for more info.

### Usage Outside of Rails

Everything above applies, except that `--routes` is not meaningful,
and you will probably need to explicitly set one or more `--require` option(s), and/or one or more `--model-dir` options
to inform `annotate` about the structure of your project and help it bootstrap and load the relevant code.

## Configuration

If you want to always skip annotations on a particular model, add this string
anywhere in the file:

    # -*- SkipSchemaAnnotations

### Configuration in Rails

To generate a configuration file (in the form of a `.rake` file), to set
default options:

    rails g annotate:install

Edit this file to control things like output format, where annotations are
added (top or bottom of file), and in which artifacts.

The generated rakefile `lib/tasks/auto_annotate_models.rake` also contains
`Annotate.load_tasks`. This adds a few rake tasks which duplicate command-line
functionality:

    rake annotate_models                          # Add schema information (as comments) to model and fixture files
    rake annotate_routes                          # Adds the route map to routes.rb
    rake remove_annotation                        # Remove schema information from model and fixture files

By default, once you've generated a configuration file, annotate will be
executed whenever you run `rake db:migrate` (but only in development mode).
If you want to disable this behavior permanently,
edit the `.rake` file and change:

```ruby
    'skip_on_db_migrate'   => 'false',
```

To:

```ruby
    'skip_on_db_migrate'   => 'true',
```

If you want to run `rake db:migrate` as a one-off without running annotate,
you can do so with a simple environment variable, instead of editing the
`.rake` file:

    ANNOTATE_SKIP_ON_DB_MIGRATE=1 rake db:migrate

## Options

    Usage: annotate [options] [model_file]*
            --additional-file-patterns   Additional file paths or globs to annotate, separated by commas (e.g. `/foo/bar/%model_name%/*.rb,/baz/%model_name%.rb`)
        -d, --delete                     Remove annotations from all model files or the routes.rb file
        -p [before|top|after|bottom],    Place the annotations at the top (before) or the bottom (after) of the model/test/fixture/factory/route/serializer file(s)
            --position
            --pc, --position-in-class [before|top|after|bottom]
                                         Place the annotations at the top (before) or the bottom (after) of the model file
            --pf, --position-in-factory [before|top|after|bottom]
                                         Place the annotations at the top (before) or the bottom (after) of any factory files
            --px, --position-in-fixture [before|top|after|bottom]
                                         Place the annotations at the top (before) or the bottom (after) of any fixture files
            --pt, --position-in-test [before|top|after|bottom]
                                         Place the annotations at the top (before) or the bottom (after) of any test files
            --pr, --position-in-routes [before|top|after|bottom]
                                         Place the annotations at the top (before) or the bottom (after) of the routes.rb file
            --ps, --position-in-serializer [before|top|after|bottom]
                                         Place the annotations at the top (before) or the bottom (after) of the serializer files
            --w, --wrapper STR           Wrap annotation with the text passed as parameter.
                                         If --w option is used, the same text will be used as opening and closing
            --wo, --wrapper-open STR     Annotation wrapper opening.
            --wc, --wrapper-close STR    Annotation wrapper closing
        -r, --routes                     Annotate routes.rb with the output of 'rake routes'
            --models                     Annotate ActiveRecord models
        -a, --active-admin               Annotate active_admin models
        -v, --version                    Show the current version of this gem
        -m, --show-migration             Include the migration version number in the annotation
        -k, --show-foreign-keys          List the table's foreign key constraints in the annotation
            --ck, --complete-foreign-keys
                                         Complete foreign key names in the annotation
        -i, --show-indexes               List the table's database indexes in the annotation
        -s, --simple-indexes             Concat the column's related indexes in the annotation
            --model-dir dir              Annotate model files stored in dir rather than app/models, separate multiple dirs with commas
            --root-dir dir               Annotate files stored within root dir projects, separate multiple dirs with commas
            --ignore-model-subdirects    Ignore subdirectories of the models directory
            --sort                       Sort columns alphabetically, rather than in creation order
            --classified-sort            Sort columns alphabetically, but first goes id, then the rest columns, then the timestamp columns and then the association columns
        -R, --require path               Additional file to require before loading models, may be used multiple times
        -e [tests,fixtures,factories,serializers],
            --exclude                    Do not annotate fixtures, test files, factories, and/or serializers
        -f [bare|rdoc|yard|markdown],    Render Schema Infomation as plain/RDoc/YARD/Markdown
            --format
            --force                      Force new annotations even if there are no changes.
            --frozen                     Do not allow to change annotations. Exits non-zero if there are going to be changes to files.
            --timestamp                  Include timestamp in (routes) annotation
            --trace                      If unable to annotate a file, print the full stack trace, not just the exception message.
        -I, --ignore-columns REGEX       don't annotate columns that match a given REGEX (e.g. `annotate -I '^(id|updated_at|created_at)'`)
            --ignore-routes REGEX        don't annotate routes that match a given REGEX (e.g. `annotate -I '(mobile|resque|pghero)'`)_
            --hide-limit-column-types VALUES
                                         don't show limit for given column types, separated by commas (e.g. `integer,boolean,text`)
            --hide-default-column-types VALUES
                                         don't show default for given column types, separated by commas (e.g. `json,jsonb,hstore`)
            --ignore-unknown-models      don't display warnings for bad model files
            --with-comment               include database comments in model annotations

### Option: `additional_file_patterns`

CLI: `--additional-file-patterns`<br>
Ruby: `:additional_file_patterns`

Provide additional paths for the gem to annotate.  These paths can include
globs. It is recommended to use absolute paths.  Here are some examples:

*   `/app/lib/decorates/%MODEL_NAME%/*.rb`
*   `/app/lib/forms/%PLURALIZED_MODEL_NAME%/**/*.rb`
*   `/app/lib/forms/%TABLE_NAME%/*.rb`


The appropriate model will be inferred using the `%*%` syntax, annotating any
matching files. It works with existing filename resolutions (options for which
can be found in the `resolve_filename` method of `annotate_models.rb`).

When using in a Rails config, you can use the following:

`File.join(Rails.application.root,
'app/lib/forms/%PLURALIZED_MODEL_NAME%/***/**.rb')`

## Sorting

By default, columns will be sorted in database order (i.e. the order in which
migrations were run).

If you prefer to sort alphabetically so that the results of annotation are
consistent regardless of what order migrations are executed in, use `--sort`.

## Markdown

The format produced is actually MultiMarkdown, making use of the syntax
extension for tables.  It's recommended you use `kramdown` as your parser if
you want to use this format.  If you're using `yard` to generate
documentation, specify a format of markdown with `kramdown` as the provider by
adding this to your `.yardopts` file:

    --markup markdown
    --markup-provider kramdown

Be sure to add this to your `Gemfile` as well:

    gem 'kramdown', groups => [:development], require => false

## WARNING

**Don't add text after an automatically-created comment block.** This tool
will blow away the initial/final comment block in your models if it looks like
it was previously added by this gem.

Be sure to check the changes that this tool makes! If you are using Git, you
may simply check your project's status after running `annotate`:

    $ git status

If you are not using a VCS (like Git, Subversion or similar), please tread
extra carefully, and consider using one.

## Links

*   Factory Bot: http://github.com/thoughtbot/factory_bot
*   Object Daddy: http://github.com/flogic/object_daddy
*   Machinist: http://github.com/notahat/machinist
*   Fabrication: http://github.com/paulelliott/fabrication
*   SpatialAdapter: http://github.com/pdeffendol/spatial_adapter
*   PostgisAdapter: http://github.com/nofxx/postgis_adapter
*   PostGISAdapter: https://github.com/dazuma/activerecord-postgis-adapter


## License

Released under the same license as Ruby. No Support. No Warranty.

## Authors

[See AUTHORS.md](AUTHORS.md).
