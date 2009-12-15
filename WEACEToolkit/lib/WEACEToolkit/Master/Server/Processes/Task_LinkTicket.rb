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

      module Processes

        class Task_LinkTicket

          include WEACE::Toolbox

          # Process the script and get the actions to perform on WEACE Slave Clients
          #
          # Parameters:
          # * *ioSlaveActions* (_SlaveActions_): The slave actions to populate (check WEACEMasterServer.rb for API)
          # * *iAdditionalParameters* (<em>list<String></em>): Additional parameters given that were not parsed by the options parser
          # Return:
          # * _Exception_: An error, or nil in case of success
          def processScript(ioSlaveActions, iAdditionalParameters)
            rError = nil

            checkVar(:@TicketID, 'Ticket ID to link to the Task')
            checkVar(:@TaskID, 'Task ID to be linked to the Ticket')
            ioSlaveActions.addSlaveAction(
              Tools_TicketTracker, Action_Ticket_AddLinkToTask,
              @TicketID, @TaskID
            )
            ioSlaveActions.addSlaveAction(
              Tools_ProjectManager, Action_Task_AddLinkToTicket,
              @TaskID, @TicketID
            )

            return rError
          end

          # Get the command line options for this Process
          #
          # Return:
          # * _OptionParser_: The corresponding options
          def getOptions
            rOptions = OptionParser.new

            rOptions.banner = '-t|--ticket <TicketID> -a|--task <TaskID>'
            rOptions.on('-t', '--ticket <TicketID>', String,
              '<TicketID>: ID of the Ticket to link to a Task.') do |iArg|
              @TicketID = iArg
            end
            rOptions.on('-a', '--task <TaskID>', String,
              '<TaskID>: ID of the Task to be linked to the Ticket.') do |iArg|
              @TaskID = iArg
            end

            return rOptions
          end

        end

      end
    
    end

  end

end
