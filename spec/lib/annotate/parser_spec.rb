require_relative '../../spec_helper'

module Annotate # rubocop:disable Metrics/ModuleLength
  describe Parser do
    before(:example) do
      ENV.clear
    end

    context 'when given empty args' do
      it 'returns an options hash with defaults' do
        result = Parser.parse([])
        expect(result).to be_a(Hash)
        expect(result).to include(target_action: :do_annotations)
      end
    end

    %w[--additional-file-patterns].each do |option|
      describe option do
        it 'sets array of paths to :additional_file_patterns' do
          paths = 'foo/bar,baz'
          allow(ENV).to receive(:[]=)
          Parser.parse([option, paths])
          expect(ENV).to have_received(:[]=).with('additional_file_patterns', ['foo/bar', 'baz'])
        end
      end
    end

    %w[-d --delete].each do |option|
      describe option do
        it 'sets target_action to :remove_annotations' do
          result = Parser.parse([option])
          expect(result).to include(target_action: :remove_annotations)
        end
      end
    end

    %w[-p --position].each do |option|
      describe option do
        Parser::ANNOTATION_POSITIONS.each do |position|
          context "when specifying #{position}" do
            it "#{position} position is an option" do
              allow(ENV).to receive(:[]=)
              Parser.parse([option, position])
              expect(Parser::ANNOTATION_POSITIONS).to include(position)
            end

            it "sets ENV['position'] to be position" do
              allow(ENV).to receive(:[]=)
              Parser.parse([option, position])

              expect(ENV).to have_received(:[]=).with('position', position)
            end

            it 'sets the value in ENV for the different file types' do
              allow(ENV).to receive(:[]=)
              Parser.parse([option, position])

              Parser::FILE_TYPE_POSITIONS.each do |file_type|
                expect(ENV).to have_received(:[]=).with(file_type, position)
              end
            end
          end
        end
      end
    end

    context 'when position_in_class is set to top' do
      context 'and when position is a different value' do
        it 'does not override' do
          other_commands = %w[--pc top]
          position_command = %w[-p bottom]
          options = other_commands + position_command

          Parser.parse(options)
          expect(ENV['position_in_class']).to eq('top')
          expect(ENV['position']).to eq('bottom')
        end
      end
    end

    %w[--pc --position-in-class].each do |option|
      describe option do
        let(:env_key) { 'position_in_class' }

        Parser::ANNOTATION_POSITIONS.each do |position|
          context "when specifying '#{position}'" do
            it "sets the ENV variable to '#{position}'" do
              allow(ENV).to receive(:[]=)
              Parser.parse([option, position])
              expect(ENV).to have_received(:[]=).with(env_key, position)
            end
          end
        end
      end
    end

    %w[--pf --position-in-factory].each do |option|
      describe option do
        let(:env_key) { 'position_in_factory' }

        Parser::ANNOTATION_POSITIONS.each do |position|
          context "when specifying #{position}" do
            it "sets the ENV variable to #{position}" do
              allow(ENV).to receive(:[]=)
              Parser.parse([option, position])
              expect(ENV).to have_received(:[]=).with(env_key, position)
            end
          end
        end
      end
    end

    %w[--px --position-in-fixture].each do |option|
      describe option do
        let(:env_key) { 'position_in_fixture' }

        Parser::ANNOTATION_POSITIONS.each do |position|
          context "when specifying #{position}" do
            it "sets the ENV variable to #{position}" do
              allow(ENV).to receive(:[]=)
              Parser.parse([option, position])
              expect(ENV).to have_received(:[]=).with(env_key, position)
            end
          end
        end
      end
    end

    %w[--pt --position-in-test].each do |option|
      describe option do
        let(:env_key) { 'position_in_test' }

        Parser::ANNOTATION_POSITIONS.each do |position|
          context "when specifying #{position}" do
            it "sets the ENV variable to #{position}" do
              allow(ENV).to receive(:[]=)
              Parser.parse([option, position])
              expect(ENV).to have_received(:[]=).with(env_key, position)
            end
          end
        end
      end
    end

    %w[--pr --position-in-routes].each do |option|
      describe option do
        let(:env_key) { 'position_in_routes' }

        Parser::ANNOTATION_POSITIONS.each do |position|
          context "when specifying #{position}" do
            it "sets the ENV variable to #{position}" do
              allow(ENV).to receive(:[]=)
              Parser.parse([option, position])
              expect(ENV).to have_received(:[]=).with(env_key, position)
            end
          end
        end
      end
    end

    %w[--ps --position-in-serializer].each do |option|
      describe option do
        let(:env_key) { 'position_in_serializer' }

        Parser::ANNOTATION_POSITIONS.each do |position|
          context "when specifying #{position}" do
            it "sets the ENV variable to #{position}" do
              allow(ENV).to receive(:[]=)
              Parser.parse([option, position])
              expect(ENV).to have_received(:[]=).with(env_key, position)
            end
          end
        end
      end
    end

    %w[--w --wrapper].each do |option|
      describe option do
        let(:env_key) { 'wrapper' }
        let(:set_value) { 'STR' }
        it 'sets the ENV variable' do
          expect(ENV).to receive(:[]=).with(env_key, set_value)
          Parser.parse([option, set_value])
        end
      end
    end

    %w[--wo --wrapper-open].each do |option|
      describe option do
        let(:env_key) { 'wrapper_open' }
        let(:set_value) { 'STR' }
        it 'sets the ENV variable' do
          expect(ENV).to receive(:[]=).with(env_key, set_value)
          Parser.parse([option, set_value])
        end
      end
    end

    %w[--wc --wrapper-close].each do |option|
      describe option do
        let(:env_key) { 'wrapper_close' }
        let(:set_value) { 'STR' }
        it 'sets the ENV variable' do
          expect(ENV).to receive(:[]=).with(env_key, set_value)
          Parser.parse([option, set_value])
        end
      end
    end

    %w[-r --routes].each do |option|
      describe option do
        let(:env_key) { 'routes' }
        let(:set_value) { 'true' }
        it 'sets the ENV variable' do
          expect(ENV).to receive(:[]=).with(env_key, set_value)
          Parser.parse([option])
        end
      end
    end

    %w[--models].each do |option|
      describe option do
        let(:env_key) { 'models' }
        let(:set_value) { 'true' }
        it 'sets the ENV variable' do
          expect(ENV).to receive(:[]=).with(env_key, set_value)
          Parser.parse([option])
        end
      end
    end

    %w[-a --active-admin].each do |option|
      describe option do
        let(:env_key) { 'active_admin' }
        let(:set_value) { 'true' }
        it 'sets the ENV variable' do
          expect(ENV).to receive(:[]=).with(env_key, set_value)
          Parser.parse([option])
        end
      end
    end

    %w[-v --version].each do |option|
      describe option do
        it 'sets the ENV variable' do
          expect { Parser.parse([option]) }.to output("annotate v#{Annotate.version}\n").to_stdout
          expect(Parser.parse([option])).to include(exit: true)
        end
      end
    end

    %w[-m --show-migration].each do |option|
      describe option do
        let(:env_key) { 'include_version' }
        let(:set_value) { 'yes' }
        it 'sets the ENV variable' do
          expect(ENV).to receive(:[]=).with(env_key, set_value)
          Parser.parse([option])
        end
      end
    end

    %w[-k --show-foreign-keys].each do |option|
      describe option do
        let(:env_key) { 'show_foreign_keys' }
        let(:set_value) { 'yes' }
        it 'sets the ENV variable' do
          expect(ENV).to receive(:[]=).with(env_key, set_value)
          Parser.parse([option])
        end
      end
    end

    %w[--ck --complete-foreign-keys].each do |option|
      describe option do
        it 'sets the ENV variable' do
          allow(ENV).to receive(:[]=)
          Parser.parse([option])

          expect(ENV).to have_received(:[]=).with('show_foreign_keys', 'yes')
          expect(ENV).to have_received(:[]=).with('show_complete_foreign_keys', 'yes')
        end
      end
    end

    %w[-i --show-indexes].each do |option|
      describe option do
        let(:env_key) { 'show_indexes' }
        let(:set_value) { 'yes' }
        it 'sets the ENV variable' do
          expect(ENV).to receive(:[]=).with(env_key, set_value)
          Parser.parse([option])
        end
      end
    end

    %w[-s --simple-indexes].each do |option|
      describe option do
        let(:env_key) { 'simple_indexes' }
        let(:set_value) { 'yes' }
        it 'sets the ENV variable' do
          expect(ENV).to receive(:[]=).with(env_key, set_value)
          Parser.parse([option])
        end
      end
    end

    describe '--model-dir' do
      let(:option) { '--model-dir' }
      let(:env_key) { 'model_dir' }
      let(:set_value) { 'some_dir/' }
      it 'sets the ENV variable' do
        expect(ENV).to receive(:[]=).with(env_key, set_value)
        Parser.parse([option, set_value])
      end
    end

    describe '--root-dir' do
      let(:option) { '--root-dir' }
      let(:env_key) { 'root_dir' }
      let(:set_value) { 'some_dir/' }
      it 'sets the ENV variable' do
        expect(ENV).to receive(:[]=).with(env_key, set_value)
        Parser.parse([option, set_value])
      end
    end

    describe '--ignore-model-subdirects' do
      let(:option) { '--ignore-model-subdirects' }
      let(:env_key) { 'ignore_model_sub_dir' }
      let(:set_value) { 'yes' }
      it 'sets the ENV variable' do
        expect(ENV).to receive(:[]=).with(env_key, set_value)
        Parser.parse([option])
      end
    end

    describe '--sort' do
      let(:option) { '--sort' }
      let(:env_key) { 'sort' }
      let(:set_value) { 'yes' }
      it 'sets the ENV variable' do
        expect(ENV).to receive(:[]=).with(env_key, set_value)
        Parser.parse([option])
      end
    end

    describe '--classified-sort' do
      let(:option) { '--classified-sort' }
      let(:env_key) { 'classified_sort' }
      let(:set_value) { 'yes' }
      it 'sets the ENV variable' do
        expect(ENV).to receive(:[]=).with(env_key, set_value)
        Parser.parse([option])
      end
    end

    %w[-R --require].each do |option|
      describe option do
        let(:env_key) { 'require' }
        let(:set_value) { 'another_dir' }
        it 'sets the ENV variable' do
          expect(ENV).to receive(:[]=).with(env_key, set_value)
          Parser.parse([option, set_value])
        end

        context "when ENV['require'] is already set" do
          let(:preset_require_value) { 'some_dir/' }
          it "appends the path to ENV['require']" do
            env = { 'require' => preset_require_value }
            expect(ENV).to receive(:[]=).with(env_key, "#{preset_require_value},#{set_value}")
            Parser.parse([option, set_value], env)
          end
        end
      end
    end

    describe 'Parser::EXCLUSION_LIST' do
      it "has 'tests'" do
        expect(Parser::EXCLUSION_LIST).to include('tests')
      end

      it "has 'fixtures'" do
        expect(Parser::EXCLUSION_LIST).to include('fixtures')
      end

      it "has 'factories'" do
        expect(Parser::EXCLUSION_LIST).to include('factories')
      end

      it "has 'serializers'" do
        expect(Parser::EXCLUSION_LIST).to include('serializers')
      end
    end

    %w[-e --exclude].each do |option|
      describe option do
        let(:set_value) { 'yes' }

        it "sets the exclusion ENV variables for 'tests', 'fixtures', 'factories', and 'serializers'" do
          allow(ENV).to receive(:[]=)
          Parser.parse([option])

          expect(ENV).to have_received(:[]=).with('exclude_tests', set_value)
          expect(ENV).to have_received(:[]=).with('exclude_fixtures', set_value)
          expect(ENV).to have_received(:[]=).with('exclude_factories', set_value)
          expect(ENV).to have_received(:[]=).with('exclude_serializers', set_value)
        end

        context 'when a type is passed in' do
          let(:exclusions) { "tests" }

          it "sets the exclusion ENV variable for 'tests' only" do
            expect(ENV).to receive(:[]=).with('exclude_tests', set_value)
            Parser.parse([option, exclusions])
          end
        end

        context 'when two types are passed in' do
          let(:exclusions) { "tests,fixtures" }

          it "sets the exclusion ENV variable for 'tests' and 'fixtures'" do
            allow(ENV).to receive(:[]=)
            Parser.parse([option, exclusions])
            expect(ENV).to have_received(:[]=).with('exclude_tests', set_value)
            expect(ENV).to have_received(:[]=).with('exclude_fixtures', set_value)
          end
        end
      end
    end

    %w[-f --format].each do |option|
      describe option do
        Parser::FORMAT_TYPES.each do |format_type|
          context "when passing in format type '#{format_type}'" do
            let(:env_key) { "format_#{format_type}" }
            let(:set_value) { 'yes' }

            it 'sets the ENV variable' do
              expect(ENV).to receive(:[]=).with(env_key, set_value)
              Parser.parse([option, format_type])
            end
          end
        end
      end
    end

    describe '--force' do
      let(:option) { '--force' }
      let(:env_key) { 'force' }
      let(:set_value) { 'yes' }
      it 'sets the ENV variable' do
        expect(ENV).to receive(:[]=).with(env_key, set_value)
        Parser.parse([option])
      end
    end

    describe '--frozen' do
      let(:option) { '--frozen' }
      let(:env_key) { 'frozen' }
      let(:set_value) { 'yes' }
      it 'sets the ENV variable' do
        expect(ENV).to receive(:[]=).with(env_key, set_value)
        Parser.parse([option])
      end
    end

    describe '--timestamp' do
      let(:option) { '--timestamp' }
      let(:env_key) { 'timestamp' }
      let(:set_value) { 'true' }
      it 'sets the ENV variable' do
        expect(ENV).to receive(:[]=).with(env_key, set_value)
        Parser.parse([option])
      end
    end

    describe '--trace' do
      let(:option) { '--trace' }
      let(:env_key) { 'trace' }
      let(:set_value) { 'yes' }
      it 'sets the ENV variable' do
        expect(ENV).to receive(:[]=).with(env_key, set_value)
        Parser.parse([option])
      end
    end

    %w[-I --ignore-columns].each do |option|
      describe option do
        let(:env_key) { 'ignore_columns' }
        let(:regex) { '^(id|updated_at|created_at)' }

        it 'sets the ENV variable' do
          expect(ENV).to receive(:[]=).with(env_key, regex)
          Parser.parse([option, regex])
        end
      end
    end

    describe '--ignore-routes' do
      let(:option) { '--ignore-routes' }
      let(:env_key) { 'ignore_routes' }
      let(:regex) { '(mobile|resque|pghero)' }

      it 'sets the ENV variable' do
        expect(ENV).to receive(:[]=).with(env_key, regex)
        Parser.parse([option, regex])
      end
    end

    describe '--hide-limit-column-types' do
      let(:option) { '--hide-limit-column-types' }
      let(:env_key) { 'hide_limit_column_types' }
      let(:values) { 'integer,boolean,text' }

      it 'sets the ENV variable' do
        expect(ENV).to receive(:[]=).with(env_key, values)
        Parser.parse([option, values])
      end
    end

    describe '--hide-default-column-types' do
      let(:option) { '--hide-default-column-types' }
      let(:env_key) { 'hide_default_column_types' }
      let(:values) { 'json,jsonb,hstore' }

      it 'sets the ENV variable' do
        expect(ENV).to receive(:[]=).with(env_key, values)
        Parser.parse([option, values])
      end
    end

    describe '--ignore-unknown-models' do
      let(:option) { '--ignore-unknown-models' }
      let(:env_key) { 'ignore_unknown_models' }
      let(:set_value) { 'true' }
      it 'sets the ENV variable' do
        expect(ENV).to receive(:[]=).with(env_key, set_value)
        Parser.parse([option])
      end
    end

    describe '--with-comment' do
      let(:option) { '--with-comment' }
      let(:env_key) { 'with_comment' }
      let(:set_value) { 'true' }
      it 'sets the ENV variable' do
        expect(ENV).to receive(:[]=).with(env_key, set_value)
        Parser.parse([option])
      end
    end
  end
end
