#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

# Require the file defining exceptions
require 'WEACEToolkit/Master/Server/WEACEMasterServer'

module WEACE

  # Needed to track the WEACE Slave Client behaviour when testing Senders
  module Slave

    class Client

      # Execute all the Actions having parameters.
      # This method uses @Actions to get the possible Actions.
      #
      # Parameters:
      # * *iUserID* (_String_): The User ID
      # Return:
      # * _ActionExecutionsError_: An error, or nil in case of success
      def executeActions_Regression(iUserID)
        # Actions to execute, taken from @Actions
        # map< String, map< String,   list< list< String > > > >
        # map< ToolID, map< ActionID, list< Parameters     > > >
        lActionsToExecute = {}
        @Actions.each do |iToolID, iToolInfo|
          # For each adapter adapting iToolID
          iToolInfo.each do |iActionID, iActionInfo|
            iProductsList, iAskedParameters = iActionInfo
            if (!iAskedParameters.empty?)
              if (lActionsToExecute[iToolID] == nil)
                lActionsToExecute[iToolID] = {}
              end
              lActionsToExecute[iToolID][iActionID] = iAskedParameters
            end
          end
        end

        $Variables[:SlaveActions] = {
          :UserID => iUserID,
          :ActionsToExecute => lActionsToExecute
        }

        return nil
      end

    end

  end

  module Test

    module Master

      module Common

        include WEACE::Test::Common

        # Execute WEACE Master Server
        #
        # Parameters:
        # * *iParameters* (<em>list<String></em>): The parameters to give WEACE Master Server
        # * *iOptions* (<em>map<Symbol,Object></em>): Additional options: [optional = {}]
        # ** *:Error* (_class_): The error class the execution is supposed to return [optional = nil]
        # ** *:Repository* (_String_): Name of the repository to be used [optional = 'Empty']
        # ** *:AddRegressionProcesses* (_Boolean_): Do we add Processes defined from the regression ? [optional = false]
        # ** *:AddRegressionSenders* (_Boolean_): Do we add Senders defined from the regression ? [optional = false]
        # * _CodeBlock_: The code called once the server was run: [optional = nil]
        # ** *iError* (_Exception_): The error returned by the server, or nil in case of success
        def executeMaster(iParameters, iOptions = {}, &iCheckCode)
          # Parse options
          lExpectedErrorClass = iOptions[:Error]
          lRepositoryName = iOptions[:Repository]
          if (lRepositoryName == nil)
            lRepositoryName = 'Empty'
          end
          lAddRegressionProcesses = iOptions[:AddRegressionProcesses]
          if (lAddRegressionProcesses == nil)
            lAddRegressionProcesses = false
          end
          lAddRegressionSenders = iOptions[:AddRegressionSenders]
          if (lAddRegressionSenders == nil)
            lAddRegressionSenders = false
          end

          initTestCase do

            # Create a new WEACE repository by copying the wanted one
            setupTmpDir(File.expand_path("#{File.dirname(__FILE__)}/../Repositories/#{lRepositoryName}"), 'WEACETestRepository') do |iTmpDir|
              @WEACERepositoryDir = iTmpDir

              require 'WEACEToolkit/Master/Server/WEACEMasterServer'
              lMasterServer = WEACE::Master::Server.new

              # Change the repository location internally in WEACE Slave Client
              lMasterServer.instance_variable_set(:@DefaultLogDir, "#{@WEACERepositoryDir}/Log")
              lMasterServer.instance_variable_set(:@ConfigFile, "#{@WEACERepositoryDir}/Config/MasterServer.conf.rb")

              # Add regression Components if needed
              if ((lAddRegressionProcesses) or
                  (lAddRegressionSenders))
                lInternalPluginsManager = lMasterServer.instance_variable_get(:@PluginsManager)
                lNewWEACELibDir = File.expand_path("#{File.dirname(__FILE__)}/../Components")
                if (lAddRegressionProcesses)
                  lInternalPluginsManager.parsePluginsFromDir('Processes', "#{lNewWEACELibDir}/Master/Server/Processes", 'WEACE::Master::Server::Processes')
                end
                if (lAddRegressionSenders)
                  lInternalPluginsManager.parsePluginsFromDir('Senders', "#{lNewWEACELibDir}/Master/Server/Senders", 'WEACE::Master::Server::Senders')
                end
              end

              # Execute for real
              lError = lMasterServer.execute(iParameters)
              # Check
              if (lExpectedErrorClass == nil)
                assert_equal(nil, lError)
              else
                assert(lError.kind_of?(lExpectedErrorClass))
              end
              # Call additional checks from the test case itself
              if (iCheckCode != nil)
                iCheckCode.call(lError)
              end
            end
          end
        end

        # Give access to a Process plugin
        #
        # Parameters:
        # * _CodeBlock_: The code executed with the Process instance created:
        # ** *iProcessPlugin* (_Object_): The Process plugin
        def accessProcessPlugin
          # Get the name of the Process plugin
          lMatch = self.class.to_s.match(/^WEACE::Test::Master::Processes::(.*)$/)
          if (lMatch == nil)
            logErr "Class #{self.class} does not have format /^WEACE::Test::Master::Processes::(.*)$/."
          else
            lProcessName = lMatch[1]
            require "WEACEToolkit/Master/Server/Processes/#{lProcessName}"
            lProcessPlugin = eval("WEACE::Master::Server::Processes::#{lProcessName}.new")
            yield(lProcessPlugin)
          end
        end

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

        # Execute a Process plugin
        #
        # Parameters:
        # * *iParameters* (<em>list<String></em>): The parameters to give to the Process plugin
        # * *iOptions* (<em>map<Symbol,Object></em>): Additional options: [optional = {}]
        # ** *:Error* (_class_): The error class the execution is supposed to return [optional = nil]
        # * _CodeBlock_: The code executed once the Process plugin has been called [optional = nil]
        # ** *iError* (_Exception_): The error returned by the Process plugin, or nil if success
        # ** *iSlaveActions* (<em>map<String,list<[String,Object]>></em>): The Slave Actions as reported by the Process plugin
        def executeProcess(iParameters, iOptions = {}, &iCheckCode)
          # Parse options
          lExpectedErrorClass = iOptions[:Error]

          initTestCase do

            accessProcessPlugin do |iProcessPlugin|
              lProcessOptions = iProcessPlugin.getOptions
              begin
                lAdditionalArgs = lProcessOptions.parse(iParameters)
              rescue Exception
                assert(false)
              end
              require 'WEACEToolkit/Master/Server/WEACEMasterServer'
              lSlaveActions = WEACE::Master::SlaveActions.new
              begin
                lError = iProcessPlugin.processScript(lSlaveActions, lAdditionalArgs)
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
                iCheckCode.call(lError, lSlaveActions.SlaveActions)
              end
            end

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

          initTestCase do

            accessSenderPlugin do |iSenderPlugin|
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

      end

    end

  end

end
