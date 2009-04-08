# Usage:
# This file is used by WEACEMasterServer.rb.
# Do not call it directly.
#
# Check http://weacemethod.sourceforge.net for details.
#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

module WEACE

  module Master
  
    class Server
    
      # Process the script and get the actions to perform on WEACE Slave Clients
      #
      # Parameters:
      # * *ioSlaveActions* (_SlaveActions_): The slave actions to populate (check WEACEMasterServer.rb for API)
      # * *iMasterTicketID* (_String_): The Master Ticket ID
      # * *iSlaveTaskID* (_String_): The Slave Ticket ID
      def processScript(ioSlaveActions, iTicketID, iTaskID)
        ioSlaveActions.addSlaveAction(
          Tools_TicketTracker, Action_Ticket_RejectDuplicate,
          iTicketID, iTaskID
        )
      end
      
    end

  end

end
