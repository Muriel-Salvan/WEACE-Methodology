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
    
    # Class that sends messages to an URL in a CGI script via POST HTTP method
    class Sender_ExternalCGIPost
    
      require WEACE::Logging
      
      # Parameters:
      # * *iUserScriptID* (_String_): The user ID of the script
      # * *iSlaveActions* (<em>map< ToolID, list< ActionID, Parameters > ></em>): The map of actions to send to the Slave Client
      # * *iURL* (_String_): The URL to post to
      # Return:
      # * _Boolean_: Has sending been performed successfully ?
      def sendMessage(iUserScriptID, iSlaveActions, iURL)
        rResult = true

        require 'net/http'
        require 'uri'
        lParsedURL = URI.parse(iURL)
        lData = Marshal.dump(iSlaveActions)
        lResult = Net::HTTP.post_form(lParsedURL, {'userid' => iUserScriptID, 'actions' => lData} )
        if (lResult.response.is_a?(Net::HTTPOK))
          log "POST successful to #{iURL}."
        else
          logErr "POST to #{iURL} ended in error: #{lResult.message}"
          rResult = false
        end
        
        return rResult
      end
      
    end
    
  end
  
end
