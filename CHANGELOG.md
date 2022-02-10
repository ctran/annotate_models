## 3.1.1
Changes
- Bump required ruby version to >= 2.4 [#772](https://github.com/ctran/annotate_models/pull/772)
- [Revert #677] Fix column default annotations [#768](https://github.com/ctran/annotate_models/pull/768)

Project Improvements
- Refactor by adding AnnotateRoutes::Helpers [#770](https://github.com/ctran/annotate_models/pull/770) 
- Bump puma from 4.3.1 to 4.3.3 in /spec/integration/rails_6.0.2.1 [#771](https://github.com/ctran/annotate_models/pull/771)
- Bump puma from 3.12.2 to 4.3.3 in /spec/integration/rails_5.2.4.1 [#769](https://github.com/ctran/annotate_models/pull/769)
- Bump nokogiri from 1.10.7 to 1.10.8 in /spec/integration/rails_5.2.4.1 [#766](https://github.com/ctran/annotate_models/pull/766)
- Bump nokogiri from 1.10.7 to 1.10.8 in /spec/integration/rails_6.0.2.1 [#765](https://github.com/ctran/annotate_models/pull/765)
- Refactor test cases of AnnotateRoutes [#760](https://github.com/ctran/annotate_models/pull/760)
- Rename FactoryGirl -> FactoryBot comment [#759](https://github.com/ctran/annotate_models/pull/759)

## 3.1.0
Changes
- Fix new lines after comments for rubocop compatibility [#757](https://github.com/ctran/annotate_models/pull/757)
- Fix messages from AnnotateRoutes [#737](https://github.com/ctran/annotate_models/pull/737)
- Support YARD notation [#724](https://github.com/ctran/annotate_models/pull/724)
- Refactor AnnotateRoutes.routes_file_exist? [#716](https://github.com/ctran/annotate_models/pull/716)
- Refactor namespace Annotate [#719](https://github.com/ctran/annotate_models/pull/719)
- Add columns managed by Globalize gem [#602](https://github.com/ctran/annotate_models/pull/602)

Bug Fixes
- Fix additional_file_patterns parsing [#756](https://github.com/ctran/annotate_models/pull/756)
- Fix typo in README [#752](https://github.com/ctran/annotate_models/pull/752)
- Fix bin/annotate NoMethodError [#745](https://github.com/ctran/annotate_models/pull/745)
- Fix README for YARD format [#740](https://github.com/ctran/annotate_models/pull/740)
- Fix constant names that were not renamed in #721 [#739](https://github.com/ctran/annotate_models/pull/739)
- Replace soft-deprecated constant `HashWithIndifferentAccess` to `ActiveSupport::HashWithIndifferentAccess` [#699](https://github.com/ctran/annotate_models/pull/699)
- [Fix #570](https://github.com/ctran/annotate_models/issues/570) Change of foreign key should be considered as a column change
- [Fix #430](https://github.com/ctran/annotate_models/issues/430) Handle columns from activerecord-postgis-adapter [#694](https://github.com/ctran/annotate_models/pull/694)
- Add ActiveAdmin option to template [#693](https://github.com/ctran/annotate_models/pull/693)
- Fix foreign key issue with Rails 6 and Sqlite3 [#695](https://github.com/ctran/annotate_models/pull/695)
- Fix Serializers Test Directory [#625](https://github.com/ctran/annotate_models/pull/625)
- [Fix #624](https://github.com/ctran/annotate_models/issues/624) Correct default values for columns when ActiveRecord::Enum is used [#677](https://github.com/ctran/annotate_models/pull/677)
- [Fix #675](https://github.com/ctran/annotate_models/issues/675) Correct indentation for double-byte characters [#676](https://github.com/ctran/annotate_models/pull/676)
- FIX: Ensure only one line is around the annotation [#669](https://github.com/ctran/annotate_models/pull/669)
- Fix shifted when format_markdown option enabled and used non-ascii [#650](https://github.com/ctran/annotate_models/pull/650)

Project improvements
- Refactor RSpec for AnnotateModels - structuralize test cases [#755](https://github.com/ctran/annotate_models/pull/755)
- Refactor test cases of AnnotateRoutes as for Rake versions [#754](https://github.com/ctran/annotate_models/pull/754)
- Add integration tests to project [#747](https://github.com/ctran/annotate_models/pull/747)
- Refactor test cases for AnnotateRoutes.remove_annotations [#748](https://github.com/ctran/annotate_models/pull/748)
- Refactor RSpec for AnnotateModels - with Globalize gem [#749](https://github.com/ctran/annotate_models/pull/749)
- Fixed CHANGELOG.md to add link to each PR [#751](https://github.com/ctran/annotate_models/pull/751)
- Delete integration test fixtures [#746](https://github.com/ctran/annotate_models/pull/746)
- Remove remaining integration test files [#744](https://github.com/ctran/annotate_models/pull/744)
- Remove unworking integration tests [#725](https://github.com/ctran/annotate_models/pull/725)
- Refactor Annotate::Parser [#742](https://github.com/ctran/annotate_models/pull/742)
- Refactor RSpec for AnnotateModels (4) - AnnotateModels.get_schema_info (without custom options) [#735](https://github.com/ctran/annotate_models/pull/735)
- Refactor RSpec for AnnotateRoutes (1) [#736](https://github.com/ctran/annotate_models/pull/736)
- Refactor AnnotateRoutes.rewrite_contents [#734](https://github.com/ctran/annotate_models/pull/734)
- AnnotateModels.get_schema_info (with custom options) [#732](https://github.com/ctran/annotate_models/pull/732)
- Fix typo in RSpec of AnnotateModels [#731](https://github.com/ctran/annotate_models/pull/731)
- Remove AnnotateRoutes.rewrite_contents_with_header [#730](https://github.com/ctran/annotate_models/pull/730)
- Refactor AnnotateRoutes.annotate_routes and .rewrite_contents_with_header [#729](https://github.com/ctran/annotate_models/pull/729)
- Refactor AnnotateModels::Parser [#728](https://github.com/ctran/annotate_models/pull/728)
- Remove invalid document of AnnotateRoutes.rewrite_contents [#727](https://github.com/ctran/annotate_models/pull/727)
- Refactor RSpec for AnnotateModels (1) [#726](https://github.com/ctran/annotate_models/pull/726)
- Refactor AnnotateModels::Helpers [#723](https://github.com/ctran/annotate_models/pull/723)
- Refactor AnnotateRoutes.remove_annotations [#715](https://github.com/ctran/annotate_models/pull/715)
- Fix AnnotateRoutes.extract_magic_comments_from_array [#712](https://github.com/ctran/annotate_models/pull/712)
- Rename FactoryGirl to FactoryBot [#721](https://github.com/ctran/annotate_models/pull/721)
- Refactor AnnotateRoutes.header [#714](https://github.com/ctran/annotate_models/pull/714)
- Freeze constant AnnotateRoutes::HEADER_ROW [#713](https://github.com/ctran/annotate_models/pull/713)
- Add constants MAGIC_COMMENT_MATCHER [#711](https://github.com/ctran/annotate_models/pull/711)
- Rename method and variable of AnnotateRoutes for readability [#709](https://github.com/ctran/annotate_models/pull/709)
- Refactor lib/annotate.rb [#707](https://github.com/ctran/annotate_models/pull/707)
- Delete TODO.md [#700](https://github.com/ctran/annotate_models/pull/700)
- Tidy README [#701](https://github.com/ctran/annotate_models/pull/701)
- Convert documentation files to Markdown [#697](https://github.com/ctran/annotate_models/pull/697)
- Upgrade and fix CI [#698](https://github.com/ctran/annotate_models/pull/698)
- Add upgrade instructions to README [#687](https://github.com/ctran/annotate_models/pull/687)
- Fix Github release action [#682](https://github.com/ctran/annotate_models/pull/682)

## 3.0.3
- Use a less error-prone way of specifying gem files [#662](https://github.com/ctran/annotate_models/pull/662)
- Update rake requirement from `>= 10.4, < 13.0` to `>= 10.4, < 14.0` [#659](https://github.com/ctran/annotate_models/pull/659)
- Bump nokogiri from 1.6.6.2 to 1.10.4 in /spec/integration/rails_4.2.0 [#655](https://github.com/ctran/annotate_models/pull/655)
- Default annotate models to true in config generated by `rails g annotate:install` [#671](https://github.com/ctran/annotate_models/pull/671)
- Bump loofah from 2.3.0 to 2.3.1 in /spec/integration/rails_4.2.0 [#681](https://github.com/ctran/annotate_models/pull/681)

## 3.0.2
- Fixes `LoadError` due to gemspec not referencing `parser.rb`, issue [#657](https://github.com/ctran/annotate_models/issues/657) [#660](https://github.com/ctran/annotate_models/pull/660)
- Changes `--additional_file_patterns` to use dashes `--additional-file-patterns` for consistency [#649](https://github.com/ctran/annotate_models/pull/649)
- Refactor: moving constants into `constants.rb` [#653](https://github.com/ctran/annotate_models/pull/653)

## 3.0.1
- Skipped as an official release, used the 3.0.1 patch for setting up Github Actions [#619](https://github.com/ctran/annotate_models/pull/619)

## 3.0.0
- **Breaking:** when option `models` is not set - models will not be annotated by default.

  Add `'models'=>'true'` to your config manually or use `--models` option if using CLI.

- Added `--models` CLI option fixing issue [#563](https://github.com/ctran/annotate_models/issues/563) [#647](https://github.com/ctran/annotate_models/pull/647)
- Added `--additional_file_patterns` option for additional file patterns [#633](https://github.com/ctran/annotate_models/pull/633) [#636](https://github.com/ctran/annotate_models/pull/636) [#637](https://github.com/ctran/annotate_models/pull/637)
- Refactored CLI parser [#646](https://github.com/ctran/annotate_models/pull/646)
- Fixed `BigDecimal.new` deprecation warning [#634](https://github.com/ctran/annotate_models/pull/634)
- Fixed annotations for columns with long data types [#622](https://github.com/ctran/annotate_models/pull/622)
- Made methods private in AnnotateRoutes [#598](https://github.com/ctran/annotate_models/pull/598)

See https://github.com/ctran/annotate_models/releases/tag/v3.0.0

## 2.7.5
See https://github.com/ctran/annotate_models/releases/tag/v2.7.5

## 2.7.3
See https://github.com/ctran/annotate_models/releases/tag/v2.7.3

## 2.7.2
See https://github.com/ctran/annotate_models/releases/tag/v2.7.2

## 2.7.1
See https://github.com/ctran/annotate_models/releases/tag/v2.7.1

## 2.7.0
See https://github.com/ctran/annotate_models/releases/tag/v2.7.0

## 2.6.9
- Support foreigh key [#241](https://github.com/ctran/annotate_models/pull/241)
- Check if model has skip tag in annotate_model_file [#167](https://github.com/ctran/annotate_models/pull/167)
- Fix issue where serializer-related flags weren't being honored [#246](https://github.com/ctran/annotate_models/issues/246)
- Prefer SQL column type over normalized AR type [#231](https://github.com/ctran/annotate_models/issues/231)

## 2.6.8
- Nothing annotated unless `options[:model_dir]` is specified, [#234](https://github.com/ctran/annotate_models/pull/234)

## 2.6.7
- Nothing annotated unless `options[:model_dir]` is specified, [#234](https://github.com/ctran/annotate_models/pull/234)

## 2.6.6
- Makes it possible to wrap annotations, [#225](https://github.com/ctran/annotate_models/pull/225)
- Fix single model generation, [#214](https://github.com/ctran/annotate_models/pull/214)
- Fix default value for Rails 4.2, [#212](https://github.com/ctran/annotate_models/issues/212)
- Don't crash on inherited models in subdirectories, [#232](https://github.com/ctran/annotate_models/issues/232)
- Process model_dir in rake task, [#197](https://github.com/ctran/annotate_models/pull/197)

## 2.6.4
- Skip "models/concerns", [#194](https://github.com/ctran/annotate_models/pull/194)
- Fix [#173](https://github.com/ctran/annotate_models/issues/173) where annotate says "Nothing to annotate" in rails 4.2
- Display an error message if not run from the root of the project, [#186](https://github.com/ctran/annotate_models/pull/186)
- Support rails 4.0 new default test directory, [#182](https://github.com/ctran/annotate_models/issues/182)
- Add an option to show timestamp in routes "-timestamp", [#136](https://github.com/ctran/annotate_models/issues/136)
- Skip plain ruby objects if they have the same class name as an ActiveRecord object, [#121](https://github.com/ctran/annotate_models/issues/121)

## 2.6.3
- Fix bug of annotate position in routes [#158](https://github.com/ctran/annotate_models/issues/158)

## 2.6.2
- Retain the current annotate block unless --force is specified
- Always load models, since they may not be autoloaded by Rails
- The pg array type is now detected (see [#158](https://github.com/ctran/annotate_models/pull/158))

## 2.6.0.beta2
- support for composite_primary_keys (garysweaver)
- bug fix for annotate_one_file (vlado)


## 2.6.0.beta1

- It's now possible to use Annotate in standalone ActiveRecord (non-Rails) projects again.
- Adding note that Markdown is actually MultiMarkdown, and recommending the use
  of the `kramdown` engine for parsing it.
- Improved Markdown formatting considerably.
- Bugfix: Needed to use inline-code tag for column and table names,
    otherwise underscores would cause havok with the formatting.
- Bugfix: Markdown syntax was incorrect
    (can't have trailing spaces before the closing marker for an emphasis tag).
- Bugfix: Remove-annotations wasn't properly finding test/spec files,
    and wasn't even looking for FactoryGirl factories under the new naming convention.
- Bugfix: Load the Rakefile from the current directory, not the first
    Rakefile in our load path.
- Added support for new FactoryGirl naming convention.
- Fix behavior of route annotations in newer versions of Rake that don't
    spit out the CWD as their first line of output.
- Overhauled integration testing system to be much easier to work with,
    better compartmentalized, and so forth -- at the cost that you must be
    using RVM to utilize it.  (It'll spit out appropriate pending messages if
    you don't.) Also includes a mode for "tinkering" by hand with a scenario,
    and won't let you run it through rspect if the repo is in a dirty state. 
    Added appropriate rake tasks to help with all of this.
- Routes can now be appended, pre-pended, or removed -- and do sane things in all cases.
- Expose all `position_*` variables as CLI params.
- Make `ENV ['position']` work as a default for all the `ENV ['position_*']` variables.
- Make rake tasks more resilient to unusual circumstances / code loading behavior.
- Resolve annotate vs. annotate_models ambiguity once and for all by
  settling on `annotate_models` *and* `annotate_routes`.  This avoids a name
  collision with RMagick while not needlessly overloading the term.
- Fixed that schema kept prepending additional newlines
- Updates to make annotate smarter about when to touch a model
- Recognize column+type, and don't change a file unless the column+type
  combination of the new schema are different than that of the old (i.e.,
  don't regenerate if columns happen to be in a different order. That's just
  how life is sometimes)
- Change annotate to use options hash instead of ENV.


## 2.5.0

- Works better with Rails 3
- Bugfix: schema kept prepending additional newlines
- Updates to make annotate smarter about when to touch a model
- Recognize column+type, and don't change a file unless the column+type
  combination of the new schema are different than that of the old (i.e.,
  don't regenerate if columns happen to be in a different order. That's just
  how life is sometimes.)
- Grab old specification even if it has `\r\n` as line endings rather than pure `\n`s
- Various warning and specification fixes
- Fix "no such file to load -- annotate/annotate_models (MissingSourceFile)"
  error (require statements in tasks now use full path to lib files)
- warn about macros, to mitigate when we're included during a production
  run, not just a rakefile run -- possibly at the expense of too much noise
- Adding rake as a runtime dependency
- If the schema is already in the model file, it will be replaced into the same location.
  If it didn't previously exist, it'll be placed according to the "position", as before.
- Allow task loading from Rakefile for gems (plugin installation already auto-detects).
- Add skip_on_db_migrate option as well for people that don't want it
- Fix options parsing to convert strings to proper booleans
- Add support for Fabrication fabricators
- Leave magic encoding comment intact
- Fix issue #14 - RuntimeError: Already memoized
- Count a model as 'annotated' if any of its tests/fixtures are annotated
- Support FactoryGirl
- Support :change migrations (Rails 3.1)
- Allow models with non-standard capitalization
- Widen type column so we can handle longtexts with chopping things off.
- Skip trying to get list of models from commandline when running via Rake
  (was preventing the use of multiple rake tasks in one command if one of them was `db:migrate`).
- Add ability to skip annotations for a model by adding
  `# -*- SkipSchemaAnnotations` anywhere in the file.
- Don't show column limits for integer and boolean types.
- Add sorting for columns and indexes.
  (Helpful for out-of-order migration execution.  Use `--sort` if you want this.)
- Annotate unit tests in subfolders.
- Add generator to install rakefile that automatically annotates on `db:migrate`.
- Correct Gemfile to clarify which environments need which gems.
- Add an .rvmrc to facilitate clean development.
- Refactor out ActiveRecord monkey-patch to permit extending without side-effects.
- Use ObjectSpace to locate models to facilitate handling of models with
  non-standard capitalization.
  Note that this still requires that the inflector be configured to understand
  the special case.
- Shore up test cases a bit.
- Merge against many of the older branches on Github whose functionality is
  already reflected to reduce confusion about what is and is not implemented here.
- Accept String or Symbol for :position (et al) options.
- Add RDoc output formatting as an option.
- Add Markdown output formatting as an option.
- Add option to force annotation regeneration.
- Add new configuration option for controlling where info is placed in
  fixtures/factories.
- Fix for models without tables.
- Fix gemspec generation now that Jeweler looks at Gemfile.
- Fix warning: `NOTE: Gem::Specification#default_executable= is deprecated
  with no replacement. It will be removed on or after 2011-10-01.`
- Fix handling of files with no trailing newline when putting annotations at
  the end of the file.
- Now works on tables with no primary key.
- `--format=markdown` option
- `--trace` option to help debug "Unable to annotate" errors
- "Table name" annotation (if table name is different from model name)
- "Human name" annotation (enabling translation to non-English locales)
- Fix JRuby ObjectSpace compatibility bug (https://github.com/ctran/annotate_models/pull/85)
- Fix FactoryGirl compatibility bug (https://github.com/ctran/annotate_models/pull/82)


## 2.4.2 2009-11-21
- Annotates `(spec|test)/factories/<model>_factory.rb` files

## 2.4.1 2009-11-20

- Annotates thoughtbot's factory_girl factories (`test/factories/<model>_factory.rb`)
- Move default annotation position back to top


## 2.4.0 2009-12-13
- Incorporated lots of patches from the Github community,
  including support for Blueprints fixtures
- Several bug fixes

## 2.1 2009-10-18

- New options
    - `-R` to require additional files before loading the models
    - `-i` to show database indexes in annotations
    - `-e` to exclude annotating tests or fixtures
    - `-m` to include the migration version number in the annotation
    - `--model-dir` to annotate model files stored a different place than `app/models`

- Ignore unknown macros ('acts_as_whatever')


## 2.0 2009-02-03

- Add annotate_models plugin fork additions
    - Annotates Rspec and Test Unit models
    - Annotates Object Daddy exemplars
    - Annotates geometrical columns

- Add AnnotateRoutes rake task
- Up gem structure to newgem defaults


## 1.0.4 2008-09-04

- Only update modified models since last run, thanks to sant0sk1

## 1.0.3 2008-05-02

- Add misc changes from Dustin Sallings and Henrik N
    - Remove trailing whitespace
    - More intuitive info messages
    - Update README file with update-to-date example

## 1.0.2 2008-03-22

- Add contributions from Michael Bumann (http://github.com/bumi)
    - added an option "position" to choose to put the annotation,
    - spec/fixtures now also get annotated
    - added a task to remove the annotations
    - these options can be specified from command line as `-d` and `-p [before|after]`


