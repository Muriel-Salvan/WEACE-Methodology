#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  module Test

    module Slave

      module Client

        class WEACESlaveClient < ::Test::Unit::TestCase

          include WEACE::Test::Slave::Common

          # Test command line option listing Actions
          def testCommandLineList
            executeSlave( [ '--list' ] )
          end

          # Test command line option listing Actions (short version)
          def testCommandLineListShort
            executeSlave( [ '-l' ] )
          end

          # Test command line option listing Actions in detail
          def testCommandLineDetailedList
            executeSlave( [ '--detailedlist' ] )
          end

          # Test command line option listing Processes in detail (short version)
          def testCommandLineDetailedListShort
            executeSlave( [ '-e' ] )
          end

          # Test command line option giving help
          def testCommandLineHelp
            executeSlave( [ '--help' ] )
          end

          # Test command line option giving help (short version)
          def testCommandLineHelpShort
            executeSlave( [ '-h' ] )
          end

          # Test command line option giving version
          def testCommandLineVersion
            executeSlave( [ '--version' ] )
          end

          # Test command line option giving version (short version)
          def testCommandLineVersionShort
            executeSlave( [ '-v' ] )
          end

          # Test command line option enabling debug
          def testCommandLineDebug
            # Make sure we don't break debug
            lDebugMode = debugActivated?
            begin
              executeSlave( [ '--debug' ] )
            rescue Exception
              activateLogDebug(lDebugMode)
              raise
            end
            activateLogDebug(lDebugMode)
          end

          # Test command line option enabling debug (short version)
          def testCommandLineDebugShort
            # Make sure we don't break debug
            lDebugMode = debugActivated?
            begin
              executeSlave( [ '-d' ] )
            rescue Exception
              activateLogDebug(lDebugMode)
              raise
            end
            activateLogDebug(lDebugMode)
          end

          # Test executing an Action without User
          def testRunActionWithoutUser
            executeSlave(
              [
                '--tool', 'DummyTool',
                '--action', 'DummyAction'
              ],
              :AddRegressionActions => true,
              :Error => WEACE::Slave::Client::CommandLineError
            )
          end

          # Test executing an Action from a given User
          def testRunActionWithoutTool
            executeSlave(
              [
                '--user', 'DummyUser',
                '--action', 'DummyAction'
              ],
              :AddRegressionActions => true,
              :Error => WEACE::Slave::Client::CommandLineError
            )
          end

          # Test executing an Action from a given User
          def testRunAction
            executeSlave(
              [
                '--user', 'DummyUser',
                '--tool', 'DummyTool',
                '--action', 'DummyAction'
              ],
              :AddRegressionActions => true,
              :Repository => 'Dummy/SlaveActionActive'
            ) do |iError|
              assert_equal('DummyUser', $Variables[:DummyAction_User])
            end
          end

          # Test executing an Action from a Product having a configuration parameter
          def testRunActionProductConfigParam
            executeSlave(
              [
                '--user', 'DummyUser',
                '--tool', 'DummyTool',
                '--action', 'DummyAction'
              ],
              :AddRegressionActions => true,
              :Repository => 'Dummy/SlaveActionActive'
            ) do |iError|
              assert_equal(
                {
                  :PersonalizedProductAttr => 'PersonalizedProductValue'
                },
                $Variables[:DummyAction_ProductConfig]
              )
            end
          end

          # Test executing an Action from a Tool having a configuration parameter
          def testRunActionToolConfigParam
            executeSlave(
              [
                '--user', 'DummyUser',
                '--tool', 'DummyTool',
                '--action', 'DummyAction'
              ],
              :AddRegressionActions => true,
              :Repository => 'Dummy/SlaveActionActive'
            ) do |iError|
              assert_equal(
                {
                  :PersonalizedToolAttr => 'PersonalizedToolValue'
                },
                $Variables[:DummyAction_ToolConfig]
              )
            end
          end

          # Test executing an Action from an Action having a configuration parameter
          def testRunActionActionConfigParam
            executeSlave(
              [
                '--user', 'DummyUser',
                '--tool', 'DummyTool',
                '--action', 'DummyAction'
              ],
              :AddRegressionActions => true,
              :Repository => 'Dummy/SlaveActionActive'
            ) do |iError|
              assert_equal(
                {
                  :PersonalizedActionAttr => 'PersonalizedActionValue'
                },
                $Variables[:DummyAction_ActionConfig]
              )
            end
          end

          # Test executing an Action from a given User with parameters
          def testRunActionWithParameters
            executeSlave(
              [
                '--user', 'DummyUser',
                '--tool', 'DummyTool',
                '--action', 'DummyActionWithParams',
                'Param1',
                'Param2'
              ],
              :AddRegressionActions => true,
              :Repository => 'Dummy/AllDummyActionsAvailable'
            ) do |iError|
              assert_equal([ 'Param1', 'Param2' ], $Variables[:DummyActionWithParams_Params])
            end
          end

          # Test executing an Action from a given User with too much parameters
          def testRunActionWithTooMuchParameters
            executeSlave(
              [
                '--user', 'DummyUser',
                '--tool', 'DummyTool',
                '--action', 'DummyActionWithParams',
                'Param1',
                'Param2',
                'Param3'
              ],
              :AddRegressionActions => true,
              :Repository => 'Dummy/AllDummyActionsAvailable',
              :Error => WEACE::Slave::Client::ActionExecutionsError
            ) do |iError|
              assert(defined?(iError.ErrorsList))
              assert(iError.ErrorsList.kind_of?(Array))
              assert_equal(1, iError.ErrorsList.size)
              assert(iError.ErrorsList[0].kind_of?(Array))
              assert_equal(5, iError.ErrorsList[0].size)
              lProduct, lTool, lAction, lParams, lError = iError.ErrorsList[0]
              assert_equal('RegProduct', lProduct)
              assert_equal('DummyTool', lTool)
              assert_equal('DummyActionWithParams', lAction)
              assert_equal(['Param1', 'Param2', 'Param3'], lParams)
              assert(lError.kind_of?(WEACE::Slave::Client::AdapterArgumentError))
            end
          end

          # Test executing an Action from a given User with a missing parameter
          def testRunActionWithMissingParameters
            executeSlave(
              [
                '--user', 'DummyUser',
                '--tool', 'DummyTool',
                '--action', 'DummyActionWithParams',
                'Param1'
              ],
              :AddRegressionActions => true,
              :Repository => 'Dummy/AllDummyActionsAvailable',
              :Error => WEACE::Slave::Client::ActionExecutionsError
            ) do |iError|
              assert(defined?(iError.ErrorsList))
              assert(iError.ErrorsList.kind_of?(Array))
              assert_equal(1, iError.ErrorsList.size)
              assert(iError.ErrorsList[0].kind_of?(Array))
              assert_equal(5, iError.ErrorsList[0].size)
              lProduct, lTool, lAction, lParams, lError = iError.ErrorsList[0]
              assert_equal('RegProduct', lProduct)
              assert_equal('DummyTool', lTool)
              assert_equal('DummyActionWithParams', lAction)
              assert_equal(['Param1'], lParams)
              assert(lError.kind_of?(WEACE::Slave::Client::AdapterArgumentError))
            end
          end

          # Test executing an Action that returns an error
          def testRunActionWithError
            executeSlave(
              [
                '--user', 'DummyUser',
                '--tool', 'DummyTool',
                '--action', 'DummyActionError'
              ],
              :AddRegressionActions => true,
              :Repository => 'Dummy/AllDummyActionsAvailable',
              :Error => WEACE::Slave::Client::ActionExecutionsError
            ) do |iError|
              assert(defined?(iError.ErrorsList))
              assert(iError.ErrorsList.kind_of?(Array))
              assert_equal(1, iError.ErrorsList.size)
              assert(iError.ErrorsList[0].kind_of?(Array))
              assert_equal(5, iError.ErrorsList[0].size)
              lProduct, lTool, lAction, lParams, lError = iError.ErrorsList[0]
              assert_equal('RegProduct', lProduct)
              assert_equal('DummyTool', lTool)
              assert_equal('DummyActionError', lAction)
              assert_equal([], lParams)
              assert(lError.kind_of?(WEACE::Slave::Adapters::DummyProduct::DummyTool::DummyError))
            end
          end

          # Test executing 2 Actions
          def testRun2Actions
            executeSlave(
              [
                '--user', 'DummyUser',
                '--tool', 'DummyTool',
                '--action', 'DummyActionWithParams',
                'Param1',
                'Param2',
                '--action', 'DummyAction'
              ],
              :AddRegressionActions => true,
              :Repository => 'Dummy/AllDummyActionsAvailable'
            ) do |iError|
              assert_equal('DummyUser', $Variables[:DummyAction_User])
              assert_equal('DummyUser', $Variables[:DummyActionWithParams_User])
              assert_equal([ 'Param1', 'Param2' ], $Variables[:DummyActionWithParams_Params])
            end
          end

          # Test executing 2 Actions on different Tools
          def testRun2ActionsDifferentTools
            executeSlave(
              [
                '--user', 'DummyUser',
                '--tool', 'DummyTool',
                '--action', 'DummyAction',
                '--tool', 'DummyTool2',
                '--action', 'DummyAction2'
              ],
              :AddRegressionActions => true,
              :Repository => 'Dummy/AllDummyActionsAvailable'
            ) do |iError|
              assert_equal('DummyUser', $Variables[:DummyAction_User])
              assert_equal('DummyUser', $Variables[:DummyAction2_User])
            end
          end

          # Test executing 2 Actions on different Tools and different Products
          def testRun2ActionsDifferentToolsDifferentProducts
            executeSlave(
              [
                '--user', 'DummyUser',
                '--tool', 'DummyTool',
                '--action', 'DummyAction',
                '--tool', 'DummyTool3',
                '--action', 'DummyAction3'
              ],
              :AddRegressionActions => true,
              :Repository => 'Dummy/AllDummyActionsAvailable'
            ) do |iError|
              assert_equal('DummyUser', $Variables[:DummyAction_User])
              assert_equal('DummyUser', $Variables[:DummyAction3_User])
            end
          end

          # Test executing 1 Action on different Products
          def testRun2ActionsSameToolDifferentProducts
            executeSlave(
              [
                '--user', 'DummyUser',
                '--tool', 'DummyTool4',
                '--action', 'DummyAction4'
              ],
              :AddRegressionActions => true,
              :Repository => 'Dummy/AllDummyActionsAvailable'
            ) do |iError|
              assert_equal('DummyUser', $Variables[:DummyAction4_User])
              assert_equal(true, $Variables[:DummyAction4_DummyProduct])
              assert_equal(true, $Variables[:DummyAction4_DummyProduct2])
            end
          end

          # Test executing 2 Actions, with 1 in error
          def testRun2ActionsWith1Error
            executeSlave(
              [
                '--user', 'DummyUser',
                '--tool', 'DummyTool',
                '--action', 'DummyActionWithParams',
                'Param1',
                '--action', 'DummyAction'
              ],
              :AddRegressionActions => true,
              :Repository => 'Dummy/AllDummyActionsAvailable',
              :Error => WEACE::Slave::Client::ActionExecutionsError
            ) do |iError|
              assert_equal('DummyUser', $Variables[:DummyAction_User])
              assert(defined?(iError.ErrorsList))
              assert(iError.ErrorsList.kind_of?(Array))
              assert_equal(1, iError.ErrorsList.size)
              assert(iError.ErrorsList[0].kind_of?(Array))
              assert_equal(5, iError.ErrorsList[0].size)
              lProduct, lTool, lAction, lParams, lError = iError.ErrorsList[0]
              assert_equal('RegProduct', lProduct)
              assert_equal('DummyTool', lTool)
              assert_equal('DummyActionWithParams', lAction)
              assert_equal(['Param1'], lParams)
              assert(lError.kind_of?(WEACE::Slave::Client::AdapterArgumentError))
            end
          end

          # Test executing 2 Actions, with 2 in error
          def testRun2ActionsWith2Errors
            executeSlave(
              [
                '--user', 'DummyUser',
                '--tool', 'DummyTool',
                '--action', 'DummyActionWithParams',
                'Param1',
                '--action', 'DummyActionError'
              ],
              :AddRegressionActions => true,
              :Repository => 'Dummy/AllDummyActionsAvailable',
              :Error => WEACE::Slave::Client::ActionExecutionsError
            ) do |iError|
              assert(defined?(iError.ErrorsList))
              assert(iError.ErrorsList.kind_of?(Array))
              assert_equal(2, iError.ErrorsList.size)
              # First error
              assert(iError.ErrorsList[0].kind_of?(Array))
              assert_equal(5, iError.ErrorsList[0].size)
              lProduct, lTool, lAction, lParams, lError = iError.ErrorsList[0]
              assert_equal('RegProduct', lProduct)
              assert_equal('DummyTool', lTool)
              assert_equal('DummyActionWithParams', lAction)
              assert_equal(['Param1'], lParams)
              assert(lError.kind_of?(WEACE::Slave::Client::AdapterArgumentError))
              # Second error
              assert(iError.ErrorsList[1].kind_of?(Array))
              assert_equal(5, iError.ErrorsList[1].size)
              lProduct, lTool, lAction, lParams, lError = iError.ErrorsList[1]
              assert_equal('RegProduct', lProduct)
              assert_equal('DummyTool', lTool)
              assert_equal('DummyActionError', lAction)
              assert_equal([], lParams)
              assert(lError.kind_of?(WEACE::Slave::Adapters::DummyProduct::DummyTool::DummyError))
            end
          end

        end

      end

    end

  end

end
