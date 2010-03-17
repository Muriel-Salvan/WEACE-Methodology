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

        # Class that sends messages to an URL in a CGI script via POST HTTP method
        class ExternalCGIPost

          include WEACE::Common

          # Prepare a file to be sent, and return data to be put in the SlaveActions to execute
          #
          # Parameters:
          # * *iLocalFileName* (_String_): The local file name to be transfered
          # Return:
          # * _Exception_: An error, or nil in case of success
          # * _Object_: The data to put in the SlaveActions
          def prepareFileTransfer(iLocalFileName)
            rError = nil
            rNewData = nil

            # Put the complete file in the POST value.
            # TODO: Make a better handling, generic (use FTP/SCP/Netbios... if the MasterProvider allows it)
            # Read the file
            File.open(iLocalFileName, 'rb') do |iFile|
              rNewData = iFile.read
            end

            return rError, rNewData
          end

          # Send a message containing the specified Slave Actions.
          #
          # Parameters:
          # * *iUserScriptID* (_String_): The user ID of the script
          # * *iSlaveActions* (<em>map< ToolID, map< ActionID, list < Parameters > > ></em>): The map of actions to send to the Slave Client
          # Return:
          # * _Exception_: An error, or nil in case of success
          def sendMessage(iUserScriptID, iSlaveActions)
            rError = nil

            checkVar(:ExternalCGIURL, 'The URL of the CGI script where Actions will be posted')
            require 'net/http'
            require 'uri'
            lParsedURL = URI.parse(@ExternalCGIURL)
            lData = Marshal.dump(iSlaveActions)
            lResult = Net::HTTP.post_form(lParsedURL, {'userid' => iUserScriptID, 'actions' => lData} )
            if (lResult.response.is_a?(Net::HTTPOK))
              # Check the last line as it contains the error code
              lLinesResult = lResult.entity.strip.split("\n")
              if (lLinesResult[-1] == 'CGI_EXIT: OK')
                logDebug "POST successful to #{@ExternalCGIURL}."
              else
                rError = RuntimeError.new("POST to #{@ExternalCGIURL} ended in error. Response obtained:\n#{lResult.entity}")
              end
            else
              rError = RuntimeError.new("POST to #{@ExternalCGIURL} ended in error: #{lResult.message}. response obtained:\n#{lResult.entity}")
            end

            return rError
          end

        end

      end
      
    end
    
  end
  
end
