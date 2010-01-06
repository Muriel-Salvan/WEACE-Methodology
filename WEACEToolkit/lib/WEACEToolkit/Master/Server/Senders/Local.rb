# Usage:
# This file is used by WEACEMasterServer.rb.
# Do not call it directly.
#
# Example: ruby -w WEACEMasterServer.rb Scripts_Validator Ticket_CloseDuplicate 123 456
#
# Check http://weacemethod.sourceforge.net for details.
#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

module WEACE

  module Master

    class Server

      module Senders

        # Class that sends messages to a Slave Client local
        class Local

          # Send a message containing the specified Slave Actions.
          #
          # Parameters:
          # * *iUserScriptID* (_String_): The user ID of the script
          # * *iSlaveActions* (<em>map< ToolID, list< ActionID, Parameters > ></em>): The map of actions to send to the Slave Client
          # Return:
          # * _Exception_: An error, or nil in case of success
          def sendMessage(iUserScriptID, iSlaveActions)
            rError = nil

            # Try requiring directly the Slave Client
            require "WEACEToolkit/Slave/Client/WEACESlaveClient"
            # Save the Log file location before, and restore it after
            lOldLogFile = getLogFile
            # Call the Slave Client directly
            rError = WEACE::Slave::Client.new.execute(iUserScriptID, iSlaveActions)
            setLogFile(lOldLogFile)

            return rError
          end

        end

      end

    end

  end

end
