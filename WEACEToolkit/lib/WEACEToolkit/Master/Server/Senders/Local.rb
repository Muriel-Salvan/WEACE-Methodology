# Usage:
# This file is used by WEACEMasterServer.rb.
# Do not call it directly.
#
# Example: ruby -w WEACEMasterServer.rb Scripts_Validator Ticket_CloseDuplicate 123 456
#
# Check http://weacemethod.sourceforge.net for details.
#--
# Copyright (c) 2009 - 2012 Muriel Salvan  (muriel@x-aeon.com)
# Licensed under BSD LICENSE. No warranty is provided.
#++

module WEACE

  module Master

    class Server

      module Senders

        # Class that sends messages to a Slave Client local
        class Local

          include WEACE::Common

          # Prepare a file to be sent, and return data to be put in the SlaveActions to execute
          #
          # Parameters::
          # * *iLocalFileName* (_String_): The local file name to be transfered
          # Return::
          # * _Exception_: An error, or nil in case of success
          # * _Object_: The data to put in the SlaveActions
          def prepareFileTransfer(iLocalFileName)
            # We are local: the local file name will be directly accessible to the SlaveClient.
            return nil, iLocalFileName
          end

          # Send a message containing the specified Slave Actions.
          #
          # Parameters::
          # * *iUserScriptID* (_String_): The user ID of the script
          # * *iSlaveActions* (<em>map< ToolID, map< ActionID, list < Parameters > > ></em>): The map of actions to send to the Slave Client
          # Return::
          # * _Exception_: An error, or nil in case of success
          def sendMessage(iUserScriptID, iSlaveActions)
            rError = nil

            # Try requiring directly the Slave Client
            require "WEACEToolkit/Slave/Client/WEACESlaveClient"
            # Save the Log file location before, and restore it after
            lOldLogFile = get_log_file
            # Call the Slave Client directly
            rError = WEACE::Slave::Client.new.executeActions(iUserScriptID, iSlaveActions)
            set_log_file(lOldLogFile)

            return rError
          end

        end

      end

    end

  end

end
