#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  module Test

    module Master

      module Senders

        class Local < ::Test::Unit::TestCase

          include WEACE::Test::Master::Common

          # Test a normal run without any action to execute
          def testNoAction
            executeSender(
              'DummyUser',
              {},
              :DummySlaveClient => true
            ) do |iError|
              assert($Variables[:SlaveActions] != nil)
              assert_equal('DummyUser', $Variables[:SlaveActions][:UserID])
              lActions = $Variables[:SlaveActions][:ActionsToExecute]
              assert_equal({}, lActions)
            end
          end

          # Test a normal run with 1 action to execute
          def test1Action
            executeSender(
              'DummyUser',
              {
                'DummyTool' => [
                  [ 'DummyAction', [] ]
                ]
              },
              :DummySlaveClient => true,
              :ClientAddRegressionActions => true,
              :ClientInstallActions => [
                [ 'DummyProduct', 'DummyTool', 'DummyAction' ]
              ],
              :ClientConfigureProducts => [
                [
                  'DummyProduct', 'DummyTool',
                  {}
                ]
              ]
            ) do |iError|
              assert($Variables[:SlaveActions] != nil)
              assert_equal('DummyUser', $Variables[:SlaveActions][:UserID])
              lActions = $Variables[:SlaveActions][:ActionsToExecute]
              assert_equal(
                {
                  'DummyTool' => {
                    'DummyAction' => [
                      []
                    ]
                  }
                },
                lActions
              )
            end
          end

        end

      end

    end

  end

end
