#--
# Copyright (c) 2009 - 2011 Muriel Salvan  (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  module Slave

    class Client

      # Execute all the Actions having parameters.
      #
      # Parameters:
      # * *iUserID* (_String_): The User ID
      # * *iActionsToExecute* (<em>map<ToolID,map<ActionID,list<list<String>>>></em>): Map of Actions to execute per Tool, along with their lists of parameters
      # Return:
      # * _ActionExecutionsError_: An error, or nil in case of success
      def executeActions_Regression(iUserID, iActionsToExecute)
        $Variables[:SlaveActions] = {
          :UserID => iUserID,
          :ActionsToExecute => iActionsToExecute
        }
        
        return nil
      end

    end

  end

  module Test

    module Master

      module Senders

        class Local < ::Test::Unit::TestCase

          include WEACE::Test::Master::MasterSender

          # Get a map of variables to instantiate in the plugin.
          # This is used to simulate the configuration stored in MasterServer.conf.rb
          #
          # Return:
          # * <em>map<Symbol,Object></em>: The variables to instantiate
          def getVarsToInstantiate
            return {}
          end

          # Prepare for execution.
          # Use this method to bypass methods to better track WEACE behaviour.
          #
          # Parameters:
          # * *CodeBlock*: The code to call once preparation is done
          def prepareExecution
            # Bypass SlaveClient (executeMarshalled)
            WEACE::Test::Common::changeMethod(
              WEACE::Slave::Client,
              :executeActions,
              :executeActions_Regression
            ) do
              yield
            end
          end

          # Get back the User ID and the Actions once sent.
          # This method is also used to assert some specific parts of the execution.
          #
          # Return:
          # * _String_: The User ID
          # * <em>map<String,map<String,list<list<String>>>></em>: The Actions
          def getUserActions
            assert($Variables[:SlaveActions] != nil)

            return $Variables[:SlaveActions][:UserID], $Variables[:SlaveActions][:ActionsToExecute]
          end

          # Get the new data put in SlaveActions for a given file to be transfered
          #
          # Parameters:
          # * *iFileName* (_String_): File name to be transfered
          # Return:
          # * _Object_: The data to be put in SlaveActions
          def getFileNewData(iFileName)
            return iFileName
          end

        end

      end

    end

  end

end
