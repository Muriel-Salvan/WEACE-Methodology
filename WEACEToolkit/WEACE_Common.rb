# Usage:
# This file is used by others.
# Do not call it directly.
#
# Check http://weacemethod.sourceforge.net for details.
#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

require 'date'

module WEACE

  # Actions to be performed by Slave Clients
  # For the Tickets Manager:
  Action_Ticket_AddLinkToTask = 'Ticket_AddLinkToTask'
  Action_Ticket_RejectDuplicate = 'Ticket_RejectDuplicate'
  # For the Project Manager:
  Action_Task_AddLinkToTicket = 'Task_AddLinkToTicket'
  
  # Types of tools to update
  # All tools, no matter what is installed
  Tools_All = 'All'
  # Wiki
  Tools_Wiki = 'Wiki'
  # Tickets Tracker
  Tools_TicketTracker = 'TicketTracker'
  # Project Manager
  Tools_ProjectManager = 'ProjectManager'

  module Logging
  
    # Log something
    #
    # Parameters:
    # * *iMessage* (_String_): The message to log
    def log(iMessage)
      iCompleteMessage = "#{DateTime.now.strftime('%Y-%m-%d %H:%M:%S')}] - #{iMessage}"
      puts iCompleteMessage
      if ($LogFile != nil)
        File.open($LogFile, 'a') do |iFile|
          iFile << iCompleteMessage
        end
      end
    end

    # Log something as an error
    #
    # Parameters:
    # * *iMessage* (_String_): The message to log
    def logErr(iMessage)
      iCompleteMessage = "#{DateTime.now.strftime('%Y-%m-%d %H:%M:%S')}] - !!! ERROR !!! - #{iMessage}"
      puts iCompleteMessage
      if ($LogFile != nil)
        File.open($LogFile, 'a') do |iFile|
          iFile << iCompleteMessage
        end
      end
    end
    
  end

end

# Add this directory to the load path.
# This way it will be possible to require using this directory as reference.
$LOAD_PATH << File.dirname(__FILE__)
