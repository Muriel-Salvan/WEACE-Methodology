#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  module Test

    module Master

      module Common

        # Execute WEACE Master Server
        #
        # Parameters:
        # * *iParameters* (<em>list<String></em>): The parameters to give WEACE Master Server
        # * *iOptions* (<em>map<Symbol,Object></em>): Additional options: [optional = {}]
        # ** *:Error* (_class_): The error class the execution is supposed to return [optional = nil]
        # ** *:AddRegressionProcesses* (_Boolean_): Do we add Processes defined from the regression ? [optional = false]
        # ** *:AddRegressionSenders* (_Boolean_): Do we add Senders defined from the regression ? [optional = false]
        # * _CodeBlock_: The code called once the server was run: [optional = nil]
        # ** *iError* (_Exception_): The error returned by the server, or nil in case of success
        def executeMaster(iParameters, iOptions = {}, &iCheckCode)
          # Parse options
          lExpectedErrorClass = iOptions[:Error]
          lAddRegressionProcesses = iOptions[:AddRegressionProcesses]
          if (lAddRegressionProcesses == nil)
            lAddRegressionProcesses = false
          end
          lAddRegressionSenders = iOptions[:AddRegressionSenders]
          if (lAddRegressionSenders == nil)
            lAddRegressionSenders = false
          end

          # Mute any output except for terminal output.
          setLogErrorsStack([])
          setLogMessagesStack([])

          # Clear variables set in tests
          $Variables = {}

          require 'WEACEToolkit/Master/Server/WEACEMasterServer'
          lMasterServer = WEACE::Master::Server.new

          # Add regression Processes if needed
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

  end

end
