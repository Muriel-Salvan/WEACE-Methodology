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
  
    # Process the script and get the actions to perform on WEACE Slave Clients
    #
    # Parameters:
    # * *ioSlaveActions* (_SlaveActions_): The slave actions to populate (check WEACEMasterServer.rb for API)
    # * *iTicketID* (_String_): The Ticket ID to link to the Task.
    # * *iTaskID* (_String_): The Task ID to link to the Ticket.
    def def processScript(ioSlaveActions, iTicketID, iTaskID)
      ioSlaveActions.addSlaveAction(
        Tools_TicketTracker, Action_Ticket_AddLinkToTask,
        iTicketID, iTaskID
      )
      ioSlaveActions.addSlaveAction(
        Tools_ProjectManager, Action_Task_AddLinkToTicket,
        iTaskID, iTicketID
      )
    end

  end

end
