# Usage: This file is used by others.
# Do not call it directly.
#
# Check http://weacemethod.sourceforge.net for details.
#--
# Copyright (c) 2009 - 2012 Muriel Salvan  (muriel@x-aeon.com)
# Licensed under BSD LICENSE. No warranty is provided.
#++

require 'WEACEToolkit/Slave/Adapters/Redmine/TicketTracker_Common'
require 'date'

module WEACE

  module Slave

    module Adapters

      module Redmine

        module TicketTracker

          class RejectDuplicate

            include WEACE::Slave::Adapters::Redmine::TicketTracker_Common

            # Execute SQL
            class SQL_RejectDuplicate < SQL_Execute

              include WEACE::Slave::Adapters::Redmine::Common::MiscUtils

              # Execute SQL.
              # This is the internal method used once the DB connection is active.
              #
              # Parameters::
              # * *ioSQL* (_Object_): The SQL connection
              # * *iUserID* (_String_): User ID of the script adding this info
              # * *iMasterTicketID* (_String_): The Master Ticket ID
              # * *iSlaveTicketID* (_String_): The Slave Ticket ID
              # Return::
              # * _Exception_: An error, or nil if success
              def execute(ioSQL, iUserID, iMasterTicketID, iSlaveTicketID)
                # Get the User ID
                lRedmineUserID = getUserID(ioSQL, iUserID)
                # Insert a comment on the Master ticket
                ioSQL.query(
                  "insert
                     into journals
                     ( journalized_id,
                       journalized_type,
                       user_id,
                       notes,
                       created_on )
                     values (
                       #{iMasterTicketID},
                       'Issue',
                       #{lRedmineUserID},
                       'Another Ticket (ID=#{iSlaveTicketID}) has been closed as a duplicate of this one.',
                       '#{DateTime.now.strftime('%Y-%m-%d %H:%M:%S')}'
                     )")
                # Insert a relation on the Master ticket
                ioSQL.query(
                  "insert
                     into issue_relations
                     ( issue_from_id,
                       issue_to_id,
                       relation_type,
                       delay )
                     values (
                       #{iMasterTicketID},
                       #{iSlaveTicketID},
                       'duplicates',
                       NULL
                     )")
                # Insert a comment on the Slave ticket
                ioSQL.query(
                  "insert
                     into journals
                     ( journalized_id,
                       journalized_type,
                       user_id,
                       notes,
                       created_on )
                     values (
                       #{iSlaveTicketID},
                       'Issue',
                       #{lRedmineUserID},
                       'This Ticket is a duplicate of another Ticket (ID=#{iMasterTicketID}).',
                       '#{DateTime.now.strftime('%Y-%m-%d %H:%M:%S')}'
                     )")
                # Close the Slave ticket
                lJournalID = ioSQL.insert_id()
                lOldValue = nil
                ioSQL.query(
                  "select status_id
                   from issues
                   where
                     id = #{iSlaveTicketID}").each do |iRow|
                  lOldValue = iRow[0]
                end
                ioSQL.query(
                  "update issues
                     set status_id = 6
                     where
                       id = #{iSlaveTicketID}")
                ioSQL.query(
                  "insert
                     into journal_details
                     ( journal_id,
                       property,
                       prop_key,
                       old_value,
                       value )
                     values (
                       #{lJournalID},
                       'attr',
                       'status_id',
                       #{lOldValue},
                       6
                     )")
                return nil
              end

            end

            # Mark 2 tickets as duplicated and close the slave ticket
            #
            # Parameters::
            # * *iUserID* (_String_): User ID of the script adding this info
            # * *iMasterTicketID* (_String_): The Master Ticket ID
            # * *iSlaveTicketID* (_String_): The Slave Ticket ID
            # Return::
            # * _Exception_: An error, or nil in case of success
            def execute(iUserID, iMasterTicketID, iSlaveTicketID)
              return executeRedmine(
                SQL_RejectDuplicate.new,
                [ iUserID, iMasterTicketID, iSlaveTicketID ]
              )
            end

          end

        end

      end

    end

  end

end
