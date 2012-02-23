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

        # Sender that logs everything we ask it to do
        class DummySender

          # Prepare a file to be sent, and return data to be put in the SlaveActions to execute
          #
          # Parameters::
          # * *iLocalFileName* (_String_): The local file name to be transfered
          # Return::
          # * _Exception_: An error, or nil in case of success
          # * _Object_: The data to put in the SlaveActions
          def prepareFileTransfer(iLocalFileName)
            rError = nil

            if (defined?(@PersoParam) == nil)
              if ($Variables[:DummySenderCalls] == nil)
                $Variables[:DummySenderCalls] = []
              end
              $Variables[:DummySenderCalls] << [ 'prepareFileTransfer', [ iLocalFileName ] ]
            else
              if ($Variables[:DummySenderCalls] == nil)
                $Variables[:DummySenderCalls] = {}
              end
              if ($Variables[:DummySenderCalls][@PersoParam] == nil)
                $Variables[:DummySenderCalls][@PersoParam] = []
              end
              $Variables[:DummySenderCalls][@PersoParam] << [ 'prepareFileTransfer', [ iLocalFileName ] ]
            end

            if ($Context[:DummySenderPrepareError] != nil)
              if ($Context[:DummySenderPrepareError].is_a?(Hash))
                # The error depends on @PersoParam
                rError = $Context[:DummySenderPrepareError][@PersoParam]
              else
                rError = $Context[:DummySenderPrepareError]
              end
            end

            return rError, "#{iLocalFileName}_PREPARED"
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

            if (defined?(@PersoParam) == nil)
              if ($Variables[:DummySenderCalls] == nil)
                $Variables[:DummySenderCalls] = []
              end
              $Variables[:DummySenderCalls] << [ 'sendMessage', [ iUserScriptID, iSlaveActions ] ]
            else
              if ($Variables[:DummySenderCalls] == nil)
                $Variables[:DummySenderCalls] = {}
              end
              if ($Variables[:DummySenderCalls][@PersoParam] == nil)
                $Variables[:DummySenderCalls][@PersoParam] = []
              end
              $Variables[:DummySenderCalls][@PersoParam] << [ 'sendMessage', [ iUserScriptID, iSlaveActions ] ]
            end

            if ($Context[:DummySenderSendError] != nil)
              if ($Context[:DummySenderSendError].is_a?(Hash))
                # The error depends on @PersoParam
                rError = $Context[:DummySenderSendError][@PersoParam]
              else
                rError = $Context[:DummySenderSendError]
              end
            end

            return rError
          end

        end

      end

    end

  end

end
