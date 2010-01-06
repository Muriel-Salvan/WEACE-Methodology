#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  module Test

    module Slave

      module Adapters

        module Common

          include WEACE::Test::Slave::Common
          
          # Execute a Slave Adapter
          #
          # Parameters:
          # * *iProductToolConfig* (<em>map<Symbol,Object></em>): The Product's configuration
          # * *iActionParameters* (<em>list<String></em>): The command line parameters to give the Action
          # * *iOptions* (<em>map<Symbol,Object></em>): Additional options: [optional = {}]
          # ** *:Error* (_class_): The error class the execution is supposed to return [optional = nil]
          # ** *:Repository* (_String_): Name of the repository to be used [optional = 'SlaveClientInstalled']
          # ** *:AddRegressionActions* (_Boolean_): Do we add Actions defined from the regression ? [optional = false]
          # ** *:CatchMySQL* (_Boolean_): Do we redirect MySQL calls to a local Regression function ? [optional = false]
          # * _CodeBlock_: The code called once the server was run: [optional = nil]
          # ** *iError* (_Exception_): The error returned by the server, or nil in case of success
          def executeSlaveAdapter(iProductToolConfig, iActionParameters, iOptions = {})
            # Parse options
            lExpectedErrorClass = iOptions[:Error]
            lRepositoryName = iOptions[:Repository]
            if (lRepositoryName == nil)
              lRepositoryName = 'SlaveClientInstalled'
            end
            lAddRegressionActions = iOptions[:AddRegressionActions]
            if (lAddRegressionActions == nil)
              lAddRegressionActions = false
            end
            lCatchMySQL = iOptions[:CatchMySQL]
            if (lCatchMySQL == nil)
              lCatchMySQL = false
            end

            # Get the Product, Tool and Action IDs from the test class name
            lType, lProductID, lToolID, lActionID, lTestName, lInstallTest = getTestDetails

            executeSlave(
              [
                '--user', 'DummyUser',
                '--tool', lToolID,
                '--action', lActionID
              ] + iActionParameters,
              :Error => lExpectedErrorClass,
              :AddRegressionActions => lAddRegressionActions,
              :Repository => lRepositoryName,
              :InstallActions => [
                [ lProductID, lToolID, lActionID ]
              ],
              :ConfigureProducts => [
                [
                  lProductID, lToolID,
                  iProductToolConfig
                ]
              ],
              :CatchMySQL => lCatchMySQL
            ) do |iError|
              yield(iError)
            end
          end

        end

      end

    end

  end

end
