require_relative '../../spec_helper'
require 'annotate/annotate_routes'

describe AnnotateRoutes do
  ROUTE_FILE = 'config/routes.rb'.freeze

  MESSAGE_ANNOTATED = "#{ROUTE_FILE} was annotated.".freeze
  MESSAGE_UNCHANGED = "#{ROUTE_FILE} was not changed.".freeze
  MESSAGE_NOT_FOUND = "#{ROUTE_FILE} could not be found.".freeze
  MESSAGE_REMOVED = "Annotations were removed from #{ROUTE_FILE}.".freeze

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
    '# -*- frozen_string_literal : true -*-'
  ].freeze

  let :stubs do
    {}
  end

  let :mock_file do
    double(File, stubs)
  end

  it 'should check if routes.rb exists' do
    expect(File).to receive(:exist?).with(ROUTE_FILE).and_return(false)
    expect(AnnotateRoutes).to receive(:puts).with(MESSAGE_NOT_FOUND)
    AnnotateRoutes.do_annotations
  end

  describe 'Annotate#example' do
    let :rake_routes_result do
      <<-EOS
                                      Prefix Verb       URI Pattern                                               Controller#Action
                                   myaction1 GET        /url1(.:format)                                           mycontroller1#action
                                   myaction2 POST       /url2(.:format)                                           mycontroller2#action
                                   myaction3 DELETE|GET /url3(.:format)                                           mycontroller3#action
      EOS
    end

    before(:each) do
      expect(File).to receive(:exist?).with(ROUTE_FILE).and_return(true).at_least(:once)

      expect(File).to receive(:read).with(ROUTE_FILE).and_return("").at_least(:once)

      expect(AnnotateRoutes).to receive(:puts).with(MESSAGE_ANNOTATED).at_least(:once)
    end

    context 'without magic comments' do
      before(:each) do
        expect(AnnotateRoutes).to receive(:`).with('rake routes').and_return(rake_routes_result)
      end

      it 'annotate normal' do
        expected_result = <<~EOS

          # == Route Map
          #
          #                                       Prefix Verb       URI Pattern                                               Controller#Action
          #                                    myaction1 GET        /url1(.:format)                                           mycontroller1#action
          #                                    myaction2 POST       /url2(.:format)                                           mycontroller2#action
          #                                    myaction3 DELETE|GET /url3(.:format)                                           mycontroller3#action
        EOS

        expect(File).to receive(:open).with(ROUTE_FILE, 'wb').and_yield(mock_file)
        expect(mock_file).to receive(:puts).with(expected_result)

        AnnotateRoutes.do_annotations
      end

      it 'annotate markdown' do
        expected_result = <<~EOS

          # ## Route Map
          #
          # Prefix    | Verb       | URI Pattern     | Controller#Action   
          # --------- | ---------- | --------------- | --------------------
          # myaction1 | GET        | /url1(.:format) | mycontroller1#action
          # myaction2 | POST       | /url2(.:format) | mycontroller2#action
          # myaction3 | DELETE-GET | /url3(.:format) | mycontroller3#action
        EOS

        expect(File).to receive(:open).with(ROUTE_FILE, 'wb').and_yield(mock_file)
        expect(mock_file).to receive(:puts).with(expected_result)

        AnnotateRoutes.do_annotations(format_markdown: true)
      end

      it 'wraps annotation if wrapper is specified' do
        expected_result = <<~EOS

          # START
          # == Route Map
          #
          #                                       Prefix Verb       URI Pattern                                               Controller#Action
          #                                    myaction1 GET        /url1(.:format)                                           mycontroller1#action
          #                                    myaction2 POST       /url2(.:format)                                           mycontroller2#action
          #                                    myaction3 DELETE|GET /url3(.:format)                                           mycontroller3#action
          # END
        EOS

        expect(File).to receive(:open).with(ROUTE_FILE, 'wb').and_yield(mock_file)
        expect(mock_file).to receive(:puts).with(expected_result)

        AnnotateRoutes.do_annotations(wrapper_open: 'START', wrapper_close: 'END')
      end
    end

    context 'When the file contains magic comments' do
      MAGIC_COMMENTS.each do |magic_comment|
        describe "magic comment: #{magic_comment.inspect}" do
          let :rake_routes_result do
            <<~EOS
              #{magic_comment}
                                                    Prefix Verb       URI Pattern                                               Controller#Action
                                                 myaction1 GET        /url1(.:format)                                           mycontroller1#action
                                                 myaction2 POST       /url2(.:format)                                           mycontroller2#action
                                                 myaction3 DELETE|GET /url3(.:format)                                           mycontroller3#action
            EOS
          end

          context 'When the file does not contain annotation yet' do
            context 'When no option is passed' do
              let :expected_result do
                <<~EOS

                  #{magic_comment}

                  # == Route Map
                  #
                  #                                       Prefix Verb       URI Pattern                                               Controller#Action
                  #                                    myaction1 GET        /url1(.:format)                                           mycontroller1#action
                  #                                    myaction2 POST       /url2(.:format)                                           mycontroller2#action
                  #                                    myaction3 DELETE|GET /url3(.:format)                                           mycontroller3#action
                EOS
              end

              it 'annotates normally' do
                expect(AnnotateRoutes).to receive(:`).with('rake routes')
                  .and_return(rake_routes_result)

                expect(File).to receive(:open).with(ROUTE_FILE, 'wb').and_yield(mock_file)
                expect(mock_file).to receive(:puts).with(expected_result)

                AnnotateRoutes.do_annotations
              end
            end

            context 'When the option "format_markdown" is passed' do
              let :expected_result do
                <<~EOS

                  #{magic_comment}

                  # ## Route Map
                  #
                  # Prefix    | Verb       | URI Pattern     | Controller#Action   
                  # --------- | ---------- | --------------- | --------------------
                  # myaction1 | GET        | /url1(.:format) | mycontroller1#action
                  # myaction2 | POST       | /url2(.:format) | mycontroller2#action
                  # myaction3 | DELETE-GET | /url3(.:format) | mycontroller3#action
                EOS
              end

              it 'annotates in Markdown format' do
                expect(AnnotateRoutes).to receive(:`).with('rake routes')
                  .and_return(rake_routes_result)

                expect(File).to receive(:open).with(ROUTE_FILE, 'wb').and_yield(mock_file)
                expect(mock_file).to receive(:puts).with(expected_result)

                AnnotateRoutes.do_annotations(format_markdown: true)
              end
            end

            context 'When the options "wrapper_open" and "wrapper_close" are passed' do
              let :expected_result do
                <<~EOS

                  #{magic_comment}

                  # START
                  # == Route Map
                  #
                  #                                       Prefix Verb       URI Pattern                                               Controller#Action
                  #                                    myaction1 GET        /url1(.:format)                                           mycontroller1#action
                  #                                    myaction2 POST       /url2(.:format)                                           mycontroller2#action
                  #                                    myaction3 DELETE|GET /url3(.:format)                                           mycontroller3#action
                  # END
                EOS
              end

              it 'annotates and wraps annotation with specified words' do
                expect(AnnotateRoutes).to receive(:`).with('rake routes')
                  .and_return(rake_routes_result)
                expect(File).to receive(:open).with(ROUTE_FILE, 'wb').and_yield(mock_file)
                expect(mock_file).to receive(:puts).with(expected_result)

                AnnotateRoutes.do_annotations(wrapper_open: 'START', wrapper_close: 'END')
              end
            end
          end
        end
      end
    end
  end

  describe 'When adding' do
    before(:each) do
      expect(File).to receive(:exist?).with(ROUTE_FILE)
        .and_return(true).at_least(:once)
      expect(AnnotateRoutes).to receive(:`).with('rake routes')
        .and_return('').at_least(:once)
    end

    it 'should insert annotations if file does not contain annotations' do
      expect(File).to receive(:read).with(ROUTE_FILE).and_return("")
      expect(File).to receive(:open).with(ROUTE_FILE, 'wb').and_yield(mock_file)
      expect(mock_file).to receive(:puts).with("\n# == Route Map\n#\n")
      expect(AnnotateRoutes).to receive(:puts).with(MESSAGE_ANNOTATED)

      AnnotateRoutes.do_annotations
    end

    it 'should insert annotations if file does not contain annotations and ignore routes' do
      expect(File).to receive(:read).with(ROUTE_FILE).and_return("")
      expect(File).to receive(:open).with(ROUTE_FILE, 'wb').and_yield(mock_file)
      expect(mock_file).to receive(:puts).with("\n# == Route Map\n#\n")
      expect(AnnotateRoutes).to receive(:puts).with(MESSAGE_ANNOTATED)

      AnnotateRoutes.do_annotations(ignore_routes: 'my_route')
    end

    it 'should insert annotations if file does not contain annotations and position top' do
      expect(File).to receive(:read).with(ROUTE_FILE).and_return("")
      expect(File).to receive(:open).with(ROUTE_FILE, 'wb').and_yield(mock_file)
      expect(mock_file).to receive(:puts).with("# == Route Map\n#\n")
      expect(AnnotateRoutes).to receive(:puts).with(MESSAGE_ANNOTATED)

      AnnotateRoutes.do_annotations(position_in_routes: 'top')
    end

    it 'should skip annotations if file does already contain annotation' do
      expect(File).to receive(:read).with(ROUTE_FILE).and_return("\n# == Route Map\n#\n")
      expect(AnnotateRoutes).to receive(:puts).with(MESSAGE_UNCHANGED)

      AnnotateRoutes.do_annotations
    end

    context 'When the file contains magic comments' do
      MAGIC_COMMENTS.each do |magic_comment|
        describe "magic comment: #{magic_comment.inspect}" do
          let :route_file_content do
            <<~EOS
              #{magic_comment}
              Something
            EOS
          end

          context 'When the option "position_in_routes" is specified as "top"' do
            let :expected_result do
              <<~EOS
                #{magic_comment}

                # == Route Map
                #

                Something
              EOS
            end

            it 'leaves magic comment on top and adds an empty line between magic comment and annotation' do
              expect(File).to receive(:open).with(ROUTE_FILE, 'wb')
                .and_yield(mock_file).at_least(:once)

              expect(File).to receive(:read).with(ROUTE_FILE).and_return(route_file_content)
              expect(mock_file).to receive(:puts).with(expected_result)
              expect(AnnotateRoutes).to receive(:puts).with(MESSAGE_ANNOTATED)
              AnnotateRoutes.do_annotations(position_in_routes: 'top')
            end
          end

          context 'When the option "position_in_routes" is specified as "bottom"' do
            let :expected_result do
              <<~EOS
                #{magic_comment}
                Something

                # == Route Map
                #
              EOS
            end

            it 'leaves magic comment on top and adds an empty line between magic comment and annotation' do
              expect(File).to receive(:open).with(ROUTE_FILE, 'wb')
                .and_yield(mock_file).at_least(:once)

              expect(File).to receive(:read).with(ROUTE_FILE).and_return(route_file_content)
              expect(mock_file).to receive(:puts).with(expected_result)
              expect(AnnotateRoutes).to receive(:puts).with(MESSAGE_ANNOTATED)
              AnnotateRoutes.do_annotations(position_in_routes: 'bottom')
            end
          end

          context 'When the file already contains annotation' do
            let :route_file_content do
              <<~EOS
                #{magic_comment}

                # == Route Map
                #
              EOS
            end

            it 'skips annotations' do
              expect(File).to receive(:read).with(ROUTE_FILE)
                .and_return(route_file_content)
              expect(AnnotateRoutes).to receive(:puts).with(MESSAGE_UNCHANGED)

              AnnotateRoutes.do_annotations
            end
          end
        end
      end
    end
  end

  describe 'As for Rake versions' do
    before :each do
      expect(File).to receive(:exist?).with(ROUTE_FILE).and_return(true)
      expect(File).to receive(:open).with(ROUTE_FILE, 'wb').and_yield(mock_file)
      expect(File).to receive(:read).with(ROUTE_FILE).and_return(route_file_content)

      expect(AnnotateRoutes).to receive(:`).with('rake routes').and_return(rake_routes_result)
    end

    context 'with older Rake versions' do
      let :rake_routes_result do
        <<~EOS.chomp
          (in /bad/line)
          good line
        EOS
      end

      context 'When the route file does not end with an empty line' do
        let :route_file_content do
          <<~EOS.chomp
            ActionController::Routing...
            foo
          EOS
        end

        let :expected_result do
          <<~EOS
            ActionController::Routing...
            foo

            # == Route Map
            #
            # good line
          EOS
        end

        it 'annotates with an empty line' do
          expect(mock_file).to receive(:puts).with(expected_result)
          expect(AnnotateRoutes).to receive(:puts).with(MESSAGE_ANNOTATED)

          AnnotateRoutes.do_annotations
        end
      end

      context 'When the route file ends with an empty line' do
        let :route_file_content do
          <<~EOS
            ActionController::Routing...
            foo
          EOS
        end

        let :expected_result do
          <<~EOS
            ActionController::Routing...
            foo

            # == Route Map
            #
            # good line
          EOS
        end

        it 'annotates without an empty line' do
          expect(mock_file).to receive(:puts).with(expected_result)
          expect(AnnotateRoutes).to receive(:puts).with(MESSAGE_ANNOTATED)

          AnnotateRoutes.do_annotations
        end
      end
    end

    context 'with newer Rake versions' do
      let :rake_routes_result do
        <<~EOS.chomp
          another good line
          good line
        EOS
      end

      context 'When the route file does not end with an empty line' do
        context 'When no option is passed' do
          let :route_file_content do
            <<~EOS.chomp
              ActionController::Routing...
              foo
            EOS
          end

          let :expected_result do
            <<~EOS
              ActionController::Routing...
              foo

              # == Route Map
              #
              # another good line
              # good line
            EOS
          end

          it 'annotates with an empty line' do
            expect(mock_file).to receive(:puts).with(expected_result)
            expect(AnnotateRoutes).to receive(:puts).with(MESSAGE_ANNOTATED)

            AnnotateRoutes.do_annotations
          end
        end
      end

      context 'When the route file ends with an empty line' do
        let :route_file_content do
          <<~EOS
            ActionController::Routing...
            foo
          EOS
        end

        let :expected_result do
          <<~EOS
            ActionController::Routing...
            foo

            # == Route Map
            #
            # another good line
            # good line
          EOS
        end

        it 'annotates without an empty line' do
          expect(mock_file).to receive(:puts).with(expected_result)
          expect(AnnotateRoutes).to receive(:puts).with(MESSAGE_ANNOTATED)

          AnnotateRoutes.do_annotations
        end
      end

      context 'When option "timestamp" is passed' do
        let :route_file_content do
          <<~EOS.chomp
            ActionController::Routing...
            foo
          EOS
        end

        let :expected_result do
          /ActionController::Routing...\nfoo\n\n# == Route Map \(Updated \d{4}-\d{2}-\d{2} \d{2}:\d{2}\)\n#\n# another good line\n# good line\n/
        end

        it 'annotates with the timestamp and an empty line' do
          expect(mock_file).to receive(:puts).with(expected_result)
          expect(AnnotateRoutes).to receive(:puts).with(MESSAGE_ANNOTATED)

          AnnotateRoutes.do_annotations timestamp: true
        end
      end
    end
  end

  describe '.remove_annotations' do
    before :each do
      expect(File).to receive(:exist?).with(ROUTE_FILE).and_return(true).once
      expect(File).to receive(:read).with(ROUTE_FILE).and_return(route_file_content).once
      expect(File).to receive(:open).with(ROUTE_FILE, 'wb').and_yield(mock_file).once
    end

    context 'When trailing annotation exists' do
      let :route_file_content do
        <<~EOS



          ActionController::Routing...
          foo


          # == Route Map
          #
          # another good line
          # good line
        EOS
      end

      let :expected_result do
        <<~EOS



          ActionController::Routing...
          foo
        EOS
      end

      it 'removes trailing annotation and trim trailing newlines, but leave leading newlines alone' do
        expect(mock_file).to receive(:puts).with(expected_result).once
        expect(AnnotateRoutes).to receive(:puts).with(MESSAGE_REMOVED).once

        AnnotateRoutes.remove_annotations
      end
    end

    context 'When prepended annotation exists' do
      let :route_file_content do
        <<~EOS
          # == Route Map
          #
          # another good line
          # good line




          Rails.application.routes.draw do
            root 'root#index'
          end



        EOS
      end

      let :expected_result do
        <<~EOS
          Rails.application.routes.draw do
            root 'root#index'
          end



        EOS
      end

      it 'removes prepended annotation and trim leading newlines, but leave trailing newlines alone' do
        expect(mock_file).to receive(:puts).with(expected_result).once
        expect(AnnotateRoutes).to receive(:puts).with(MESSAGE_REMOVED).once

        AnnotateRoutes.remove_annotations
      end
    end

    context 'When custom comments are above route map' do
      let :route_file_content do
        <<~EOS
          # My comment
          # == Route Map
          #
          # another good line
          # good line
          Rails.application.routes.draw do
            root 'root#index'
          end
        EOS
      end

      let :expected_result do
        <<~EOS
          # My comment
          Rails.application.routes.draw do
            root 'root#index'
          end
        EOS
      end

      it 'does not remove custom comments above route map' do
        expect(mock_file).to receive(:puts).with(expected_result).once
        expect(AnnotateRoutes).to receive(:puts).with(MESSAGE_REMOVED).once

        AnnotateRoutes.remove_annotations
      end
    end
  end
end
