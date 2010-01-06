#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  module Master

    class Server

      module Common

        # Get the command line parameters to give the WEACE Slave Client corresponding to a given set of Actions to execute
        #
        # Parameters:
        # * *iUserScriptID* (_String_): The user ID of the script
        # * *iSlaveActions* (<em>map< ToolID, list< ActionID, Parameters > ></em>): The map of actions to send to the Slave Client
        # Return:
        # * <em>list<String></em>: Corresponding command line parameters
        def getSlaveClientParamsFromActions(iUserScriptID, iSlaveActions)
          rParameters = [ '--user', iUserScriptID ]

          iSlaveActions.each do |iToolID, iActionsList|
            lParameters += [ '--tool', iToolID ]
            iActionsList.each do |iActionInfo|
              iActionID, iParameters = iActionInfo
              rParameters += [ '--action', iActionID ]
              rParameters += iParameters
            end
          end

          return rParameters
        end

      end

    end

  end

end
