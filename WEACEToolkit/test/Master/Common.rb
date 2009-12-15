#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

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

          initTestCase

          # Create a new WEACE repository by copying the wanted one
          setupTmpDir(File.expand_path("#{File.dirname(__FILE__)}/../Repositories/#{lRepositoryName}"), 'WEACETestRepository') do |iTmpDir|
            @WEACERepositoryDir = iTmpDir

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

          accessProcessPlugin do |iProcessPlugin|
            lProcessOptions = iProcessPlugin.getOptions
            begin
              lAdditionalArgs = lProcessOptions.parse(iParameters)
            rescue Exception
              assert(false)
            end
            require 'WEACEToolkit/Master/Server/WEACEMasterServer'
            lSlaveActions = WEACE::Master::SlaveActions.new
            lError = iProcessPlugin.processScript(lSlaveActions, lAdditionalArgs)
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

    end

  end

end
