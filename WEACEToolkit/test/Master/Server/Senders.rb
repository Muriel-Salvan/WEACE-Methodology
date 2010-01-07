#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  module Test

    module Master

      module Senders

        module Common

          include WEACE::Toolbox
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

          # Execute a Sender plugin
          #
          # Parameters:
          # * *iUserID* (_String_): the user ID to use while sending
          # * *iSlaveActions* (<em>map<String,list<[String,Object]>></em>): The Slave Actions to send
          # * *iOptions* (<em>map<Symbol,Object></em>): Additional options: [optional = {}]
          # ** *:Error* (_class_): The error class the execution is supposed to return [optional = nil]
          # ** *:DummySlaveClient* (_Boolean_): Do we bypass the executeActions of the WEACE Slave Client to trace it ? [optional = false]
          # ** *:ClientAddRegressionActions* (_Boolean_): Do we add Actions defined from the regression in the WEACE Slave Client to be called ? [optional = false]
          # ** *:ClientInstallActions* (<em>list<[String,String,String]></em>): List of Actions to install in the WEACE Slave Client to be called: [ ProductID, ToolID, ActionID ]. [optional = nil]
          # ** *:ClientConfigureProducts* (<em>list<[String,String,map<Symbol,Object>]></em>): The list of Product/Tool to configure in the WEACE Slave Client to be called: [ ProductID, ToolID, Parameters ]. [optional = nil]
          # ** *:InstantiateVariables* (<em>map<Symbol,Object></em>): Set of variables to instantiate in the Sender plugin. [optional = nil].
          # * _CodeBlock_: The code executed once the Process plugin has been called [optional = nil]
          # ** *iError* (_Exception_): The error returned by the Process plugin, or nil if success
          def executeSender(iUserID, iSlaveActions, iOptions = {}, &iCheckCode)
            # Parse options
            lExpectedErrorClass = iOptions[:Error]
            lDummySlaveClient = iOptions[:DummySlaveClient]
            if (lDummySlaveClient == nil)
              lDummySlaveClient = false
            end
            lClientAddRegressionActions = iOptions[:ClientAddRegressionActions]
            if (lClientAddRegressionActions == nil)
              lClientAddRegressionActions = false
            end
            lClientInstallActions = iOptions[:ClientInstallActions]
            lClientConfigureProducts = iOptions[:ClientConfigureProducts]
            lInstantiateVariables = iOptions[:InstantiateVariables]

            initTestCase do

              accessSenderPlugin do |iSenderPlugin|
                # Instantiate variables if needed
                if (lInstantiateVariables != nil)
                  instantiateVars(iSenderPlugin, lInstantiateVariables)
                end

                # Bypass the Slave Client if needed
                WEACE::Test::Common::changeMethod(
                  WEACE::Slave::Client,
                  :executeActions,
                  :executeActions_Regression,
                  lDummySlaveClient
                ) do

                  # Create a new WEACE repository by copying the wanted one
                  setupTmpDir(File.expand_path("#{File.dirname(__FILE__)}/../Repositories/Empty"), 'WEACETestRepository') do |iTmpDir|
                    @WEACERepositoryDir = iTmpDir

                    WEACE::Slave::Client.changeClient(
                      @WEACERepositoryDir,
                      lClientAddRegressionActions,
                      lClientInstallActions,
                      lClientConfigureProducts
                    ) do

                      begin
                        lError = iSenderPlugin.sendMessage(iUserID, iSlaveActions)
                      rescue Exception
                        lError = $!
                      end
                      # Check
                      if (lExpectedErrorClass == nil)
                        assert_equal(nil, lError)
                      else
                        assert(lError.kind_of?(lExpectedErrorClass))
                      end
                      # Additional checks if needed
                      if (iCheckCode != nil)
                        iCheckCode.call(lError)
                      end

                    end

                  end

                end

              end

            end
          end

          # Execute a Sender Test with the following User and Actions
          #
          # Parameters:
          # * *iUserID* (_String_): The User ID to give the Sender
          # * *iActions* (<em>map<String,map<String,list<list<String>>>></em>: The Actions to give the Sender
          def executeTest(iUserID, iActions)
            prepareExecution do
              executeSender(
                iUserID,
                iActions,
                getExecutionParameters
              ) do |iError|
                lUser, lActions = getUserActions
                assert_equal(iUserID, lUser)
                assert_equal(iActions, lActions)
              end
            end
          end

          # === Following are test cases that are applied for all Senders

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

end
