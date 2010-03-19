#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  module Test

    module Master

      # This module is meant to be included by test suites testing Senders
      module MasterSender

        include WEACE::Common
        include WEACE::Test::Common

        # Give access to a Sender plugin
        #
        # Parameters:
        # * _CodeBlock_: The code executed with the Sender instance created:
        # ** *iSenderPlugin* (_Object_): The Sender plugin
        def accessSenderPlugin
          # Get the name of the Sender plugin
          lMatch = self.class.to_s.match(/^WEACE::Test::Master::Senders::(.*)$/)
          if (lMatch == nil)
            logErr "Class #{self.class} does not have format /^WEACE::Test::Master::Senders::(.*)$/."
          else
            lProcessName = lMatch[1]
            require "WEACEToolkit/Master/Server/Senders/#{lProcessName}"
            lSenderPlugin = eval("WEACE::Master::Server::Senders::#{lProcessName}.new")
            yield(lSenderPlugin)
          end
        end

        # Execute a Sender Test with the following User and Actions
        #
        # Parameters:
        # * *iUserID* (_String_): The User ID to give the Sender
        # * *iActions* (<em>map<String,map<String,list<list<Object>>>></em>: The Actions to give the Sender
        def executeTest(iUserID, iActions)
          initTestCase do
            prepareExecution do
              # Load the plugin
              accessSenderPlugin do |ioSenderPlugin|
                # Instantiate variables
                instantiateVars(ioSenderPlugin, getVarsToInstantiate)
                # Parse SlaveActions to handle file transfers correctly.
                lSlaveActionsForClient = {}
                iActions.each do |iToolID, iSlaveActionsList|
                  # map< ActionID, list< Parameters > >
                  lSlaveActionsList = {}
                  iSlaveActionsList.each do |iActionID, iParametersLists|
                    lParametersLists = []
                    iParametersLists.each do |iParametersList|
                      lParametersList = []
                      iParametersList.each do |iParameter|
                        if (iParameter.is_a?(WEACE::Master::TransferFile))
                          lError, lNewData = ioSenderPlugin.prepareFileTransfer(iParameter.LocalFileName)
                          assert_equal(nil, lError)
                          lParametersList << lNewData
                        else
                          lParametersList << iParameter
                        end
                      end
                      lParametersLists << lParametersList
                    end
                    lSlaveActionsList[iActionID] = lParametersLists
                  end
                  lSlaveActionsForClient[iToolID] = lSlaveActionsList
                end
                # Send the message
                lError = ioSenderPlugin.sendMessage(iUserID, lSlaveActionsForClient)
                assert_equal(nil, lError)
                # Check User and Actions received
                lUser, lActions = getUserActions
                assert_equal(iUserID, lUser)
                assert_equal(lSlaveActionsForClient, lActions)
              end
            end
          end
        end

        # === Following are test cases that are applied for all Senders

        # Test the Sender's signature
        def testSignature
          accessSenderPlugin do |ioSenderPlugin|
            assert(ioSenderPlugin.respond_to?(:prepareFileTransfer))
            assert_equal(1, ioSenderPlugin.method(:prepareFileTransfer).arity)
            assert(ioSenderPlugin.respond_to?(:sendMessage))
            assert_equal(2, ioSenderPlugin.method(:sendMessage).arity)
          end
        end

        # Test the file transfer preparation
        def testFileTransfer
          setupTempFile do |iTmpFileName|
            accessSenderPlugin do |ioSenderPlugin|
              lError, lNewData = ioSenderPlugin.prepareFileTransfer(iTmpFileName)
              assert_equal(nil, lError)
              assert_equal(getFileNewData(iTmpFileName), lNewData)
            end
          end
        end

        # Test a normal run without any action to execute
        def testNoAction
          executeTest('DummyUser', {})
        end

        # Test a normal run with 1 action to execute
        def test1Action
          executeTest(
            'DummyUser',
            {
              'DummyTool' => {
                'DummyAction' => [
                  []
                ]
              }
            }
          )
        end

        # Test a normal run with 1 action to execute with parameters
        def test1ActionParameters
          executeTest(
            'DummyUser',
            {
              'DummyTool' => {
                'DummyActionWithParams' => [
                  [ 'Param1', 'Param2' ]
                ]
              }
            }
          )
        end

        # Test a normal run with 1 action to execute with a file parameter
        def test1ActionFileParameter
          # Create a local file name to transfer
          setupTempFile do |iTempFileName|
            executeTest(
              'DummyUser',
              {
                'DummyTool' => {
                  'DummyAction' => [
                    [ WEACE::Master::TransferFile.new(iTempFileName) ]
                  ]
                }
              }
            )
          end
        end

        # Test a normal run with 1 action to execute 2 times with different parameters
        def test1ActionTwiceDifferentParameters
          executeTest(
            'DummyUser',
            {
              'DummyTool' => {
                'DummyActionWithParams' => [
                  [ 'Param11', 'Param21' ],
                  [ 'Param12', 'Param22' ]
                ]
              }
            }
          )
        end

        # Test a normal run with 2 different actions to execute
        def test2Actions
          executeTest(
            'DummyUser',
            {
              'DummyTool' => {
                'DummyActionWithParams' => [
                  [ 'Param1', 'Param2' ]
                ],
                'DummyAction' => [
                  []
                ]
              }
            }
          )
        end

        # Test a normal run with 2 different actions to execute on 2 different Tools
        def test2ActionsDifferentTools
          executeTest(
            'DummyUser',
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
            }
          )
        end

      end

    end

  end

end
