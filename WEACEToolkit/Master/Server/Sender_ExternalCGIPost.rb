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
    
      include WEACE::Logging
      include WEACE::Toolbox
      
      # Parameters:
      # * *iUserScriptID* (_String_): The user ID of the script
      # * *iSlaveActions* (<em>map< ToolID, list< ActionID, Parameters > ></em>): The map of actions to send to the Slave Client
      # Return:
      # * _Boolean_: Has sending been performed successfully ?
      def sendMessage(iUserScriptID, iSlaveActions)
        rResult = true

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
            log "POST successful to #{@ExternalCGIURL}."
          else
            logErr "POST to #{@ExternalCGIURL} ended in error."
            logErr "===== Response (#{@ExternalCGIURL}) ====="
            logErr lResult.entity
            logErr "===== End of Response (#{@ExternalCGIURL}) ====="
            rResult = false
          end
        else
          logErr "POST to #{@ExternalCGIURL} ended in error: #{lResult.message}"
          logErr "===== Response (#{@ExternalCGIURL}) ====="
          logErr lResult.entity
          logErr "===== End of Response (#{@ExternalCGIURL}) ====="
          rResult = false
        end
        
        return rResult
      end
      
    end
    
  end
  
end
