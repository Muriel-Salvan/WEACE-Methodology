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

        class Ticket_CloseDuplicate

          # Process the script and get the actions to perform on WEACE Slave Clients
          #
          # Parameters:
          # * *ioSlaveActions* (_SlaveActions_): The slave actions to populate (check WEACEMasterServer.rb for API)
          # * *iAdditionalParameters* (<em>list<String></em>): Additional parameters given that were not parsed by the options parser
          # Return:
          # * _Exception_: An error, or nil in case of success
          def processScript(ioSlaveActions, iAdditionalParameters)
            rError = nil

            ioSlaveActions.addSlaveAction(
              Tools_TicketTracker, Action_Ticket_RejectDuplicate,
              @MasterTicketID, @SlaveTicketID
            )

            return rError
          end

          # Get the command line options for this Process
          #
          # Return:
          # * _OptionsParser_: The corresponding options
          def getOptions
            rOptions = OptionsParser.new

            rOptions.banner = '-m|--masterticket <TicketID> -s|--slaveticket <TicketID>'
            rOptions.on('-m', '--masterticket <TicketID>', String,
              '<TicketID>: ID of the Ticket to remain as the master one.') do |iArg|
              @MasterTicketID = iArg
            end
            rOptions.on('-s', '--slaveticket <TicketID>', String,
              '<TicketID>: ID of the Ticket to be rejected as a duplicate.') do |iArg|
              @SlaveTicketID = iArg
            end

            return rOptions
          end

        end

      end

    end

  end

end
