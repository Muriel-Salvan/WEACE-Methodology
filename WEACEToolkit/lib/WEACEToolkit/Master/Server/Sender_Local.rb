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
    
    # Class that sends messages to a Slave Client local
    class Sender_Local
      
      # Parameters:
      # * *iUserScriptID* (_String_): The user ID of the script
      # * *iSlaveActions* (<em>map< ToolID, list< ActionID, Parameters > ></em>): The map of actions to send to the Slave Client
      # Return:
      # * _Boolean_: Has sending been performed successfully ?
      def sendMessage(iUserScriptID, iSlaveActions)
        checkVar(:WEACEToolkitDir, 'The installation directory of the WEACE Slave Toolkit')
        # Try requiring directly the Slave Client
        begin
          require "#{@WEACEToolkitDir}/Slave/Client/WEACESlaveClient.rb"
        rescue RuntimeError
          logErr "Unable to require file #{@WEACEToolkitDir}/Slave/Client/WEACESlaveClient.rb: #{$!}."
          logErr $!.backtrace.join("\n")
          return false
        end
        # Save the Log file location before, and restore it after
        lOldLogFile = getLogFile
        # Call the Slave Client directly
        rSuccess = WEACE::Slave::Client.new.execute(iUserScriptID, iSlaveActions)
        setLogFile(lOldLogFile)
        
        return rSuccess
      end
      
    end
    
  end
  
end
