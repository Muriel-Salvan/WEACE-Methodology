#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

# Require the file defining exceptions
require 'WEACEToolkit/Slave/Client/WEACESlaveClient'

module WEACE

  module Test

    module Slave

      module Common

        include WEACE::Test::Common

        # Execute WEACE Slave Client
        #
        # Parameters:
        # * *iParameters* (<em>list<String></em>): The parameters to give WEACE Master Server
        # * *iOptions* (<em>map<Symbol,Object></em>): Additional options: [optional = {}]
        # ** *:Error* (_class_): The error class the execution is supposed to return [optional = nil]
        # ** *:Repository* (_String_): Name of the repository to be used [optional = 'Empty']
        # ** *:AddRegressionActions* (_Boolean_): Do we add Actions defined from the regression ? [optional = false]
        # ** *:InstallActions* (<em>list<[String,String,String]></em>): List of Actions to install: [ ProductID, ToolID, ActionID ]. [optional = nil]
        # ** *:ConfigureProducts* (<em>list<[String,String,map<Symbol,Object>]></em>): The list of Product/Tool to configure: [ ProductID, ToolID, Parameters ]. [optional = nil]
        # * _CodeBlock_: The code called once the server was run: [optional = nil]
        # ** *iError* (_Exception_): The error returned by the server, or nil in case of success
        def executeSlave(iParameters, iOptions = {}, &iCheckCode)
          # Parse options
          lExpectedErrorClass = iOptions[:Error]
          lRepositoryName = iOptions[:Repository]
          if (lRepositoryName == nil)
            lRepositoryName = 'Empty'
          end
          lAddRegressionActions = iOptions[:AddRegressionActions]
          if (lAddRegressionActions == nil)
            lAddRegressionActions = false
          end
          lInstallActions = iOptions[:InstallActions]
          lConfigureProducts = iOptions[:ConfigureProducts]

          initTestCase do

            # Create a new WEACE repository by copying the wanted one
            setupTmpDir(File.expand_path("#{File.dirname(__FILE__)}/../Repositories/#{lRepositoryName}"), 'WEACETestRepository') do |iTmpDir|
              @WEACERepositoryDir = iTmpDir

              require 'WEACEToolkit/Slave/Client/WEACESlaveClient'
              lSlaveClient = WEACE::Slave::Client.new

              # Change the repository location internally in WEACE Slave Client
              lSlaveClient.instance_variable_set(:@WEACEInstallDir, "#{@WEACERepositoryDir}/Install")
              lSlaveClient.instance_variable_set(:@DefaultLogDir, "#{@WEACERepositoryDir}/Log")
              lSlaveClient.instance_variable_set(:@ConfigFile, "#{@WEACERepositoryDir}/Config/SlaveClient.conf.rb")

              # Add regression Components if needed
              if (lAddRegressionActions)
                lNewWEACELibDir = File.expand_path("#{File.dirname(__FILE__)}/../Components")
                lSlaveClient.send(:parseAdapters, "#{lNewWEACELibDir}/Slave/Adapters")
              end

              # First, register actions if needed
              if (lInstallActions != nil)
                lSlaveActions = lSlaveClient.instance_variable_get(:@Actions)
                lInstallActions.each do |iInstalledActionInfo|
                  iProductID, iToolID, iActionID = iInstalledActionInfo
                  # Register the Action among the installed ones
                  lSlaveActions[iToolID][iActionID][0].each do |ioProductInfo|
                    iKnownProductID, iInstalled = ioProductInfo
                    if (iKnownProductID == iProductID)
                      ioProductInfo[1] = true
                    end
                  end
                end
              end

              # Configure Products if needed
              if (lConfigureProducts != nil)
                # Bypass the configuration file reader to force our configuration
                lError, $WEACESlaveConfig = lSlaveClient.send(:readConfigFile)
                def lSlaveClient.readConfigFile
                  return nil, $WEACESlaveConfig
                end
                lConfigureProducts.each do |iProductInfo|
                  iProductID, iToolID, iProductConfig = iProductInfo
                  $WEACESlaveConfig[:WEACESlaveAdapters] << iProductConfig.merge(
                    {
                    :Product => iProductID,
                    :Tool => iToolID
                    }
                  )
                end
              end

              # Execute for real
              begin
                lError = lSlaveClient.execute(iParameters)
                #lError = lSlaveClient.execute(['-d']+iParameters)
                #p lError
              rescue Exception
                # This way exception is shown on screen for better understanding
                assert_equal(nil, $!)
              end
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

  end

end
