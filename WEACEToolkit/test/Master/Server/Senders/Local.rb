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

          # Test a normal run with 1 action to execute with parameters
          def test1ActionParameters
            executeSender(
              'DummyUser',
              {
                'DummyTool' => [
                  [ 'DummyActionWithParams', [ 'Param1', 'Param2' ] ]
                ]
              },
              :DummySlaveClient => true,
              :ClientAddRegressionActions => true,
              :ClientInstallActions => [
                [ 'DummyProduct', 'DummyTool', 'DummyActionWithParams' ]
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
                    'DummyActionWithParams' => [
                      [ 'Param1', 'Param2' ]
                    ]
                  }
                },
                lActions
              )
            end
          end

          # Test a normal run with 1 action to execute 2 times with different parameters
          def test1ActionTwiceDifferentParameters
            executeSender(
              'DummyUser',
              {
                'DummyTool' => [
                  [ 'DummyActionWithParams', [ 'Param11', 'Param21' ] ],
                  [ 'DummyActionWithParams', [ 'Param12', 'Param22' ] ]
                ]
              },
              :DummySlaveClient => true,
              :ClientAddRegressionActions => true,
              :ClientInstallActions => [
                [ 'DummyProduct', 'DummyTool', 'DummyActionWithParams' ]
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
                    'DummyActionWithParams' => [
                      [ 'Param11', 'Param21' ],
                      [ 'Param12', 'Param22' ]
                    ]
                  }
                },
                lActions
              )
            end
          end

          # Test a normal run with 2 different actions to execute
          def test2Actions
            executeSender(
              'DummyUser',
              {
                'DummyTool' => [
                  [ 'DummyActionWithParams', [ 'Param1', 'Param2' ] ],
                  [ 'DummyAction', [] ]
                ]
              },
              :DummySlaveClient => true,
              :ClientAddRegressionActions => true,
              :ClientInstallActions => [
                [ 'DummyProduct', 'DummyTool', 'DummyAction' ],
                [ 'DummyProduct', 'DummyTool', 'DummyActionWithParams' ]
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
                    'DummyActionWithParams' => [
                      [ 'Param1', 'Param2' ]
                    ],
                    'DummyAction' => [
                      []
                    ]
                  }
                },
                lActions
              )
            end
          end

          # Test a normal run with 2 different actions to execute on 2 different Tools
          def test2ActionsDifferentTools
            executeSender(
              'DummyUser',
              {
                'DummyTool' => [
                  [ 'DummyAction', [] ]
                ],
                'DummyTool2' => [
                  [ 'DummyAction2', [] ]
                ]
              },
              :DummySlaveClient => true,
              :ClientAddRegressionActions => true,
              :ClientInstallActions => [
                [ 'DummyProduct', 'DummyTool', 'DummyAction' ],
                [ 'DummyProduct', 'DummyTool2', 'DummyAction2' ]
              ],
              :ClientConfigureProducts => [
                [
                  'DummyProduct', 'DummyTool',
                  {}
                ],
                [
                  'DummyProduct', 'DummyTool2',
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
                  },
                  'DummyTool2' => {
                    'DummyAction2' => [
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
