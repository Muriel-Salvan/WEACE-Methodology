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
      # * *iWEACEToolkitDir* (_String_): The installation directory of the WEACE toolkit
      # Return:
      # * _Boolean_: Has sending been performed successfully ?
      def sendMessage(iUserScriptID, iSlaveActions, iWEACEToolkitDir)
        # Try requiring directly the Slave Client
        begin
          require "#{iWEACEToolkitDir}/Slave/Client/WEACESlaveClient.rb"
        rescue RuntimeError
          puts "!!! Unable to require file #{iWEACEToolkitDir}/Slave/Client/WEACESlaveClient.rb"
          return false
        end
        # Save the Log file location before, and restore it after
        lOldLogFile = $LogFile
        # Call the Slave Client directly
        lSuccess = WEACE::Slave::Client.new.execute(iUserScriptID, iSlaveActions)
        $LogFile = lOldLogFile
        
        return lSuccess
      end
      
    end
    
  end
  
end
