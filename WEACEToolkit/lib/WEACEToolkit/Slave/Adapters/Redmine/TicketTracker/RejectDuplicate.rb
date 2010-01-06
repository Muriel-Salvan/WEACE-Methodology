# Usage: This file is used by others.
# Do not call it directly.
#
# Check http://weacemethod.sourceforge.net for details.
#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

require 'WEACEToolkit/Slave/Adapters/Redmine/Redmine_Common'
require 'date'

module WEACE

  module Slave

    module Adapters

      module Redmine

        module TicketTracker

          class RejectDuplicate

            include WEACE::Toolbox
            include WEACE::Slave::Adapters::Redmine::Common

            # Mark 2 tickets as duplicated and close the slave ticket
            #
            # Parameters:
            # * *iUserID* (_String_): User ID of the script adding this info
            # * *iMasterTicketID* (_String_): The Master Ticket ID
            # * *iSlaveTicketID* (_String_): The Slave Ticket ID
            # Return:
            # * _Exception_: An error, or nil in case of success
            def execute(iUserID, iMasterTicketID, iSlaveTicketID)
              checkVar(:RedmineDir, 'The directory where Redmine is installed')
              checkVar(:DBHost, 'The name of the MySQL host')
              checkVar(:DBName, 'The name of the database of Redmine')
              checkVar(:DBUser, 'The name of the database user')
              checkVar(:DBPassword, 'The password of the database user')
#              execMySQLOtherSession(@RedmineDir, @DBHost, @DBName, @DBUser, @DBPassword, iUserID, iMasterTicketID, iSlaveTicketID)
              execMySQL(@DBHost, @DBName, @DBUser, @DBPassword, iUserID, iMasterTicketID, iSlaveTicketID)
              return nil
            end

            private

            # Mark 2 tickets as duplicated and close the slave ticket
            #
            # Parameters:
            # * *iSQL* (_Object_): The SQL connection
            # * *iUserID* (_String_): User ID of the script adding this info
            # * *iMasterTicketID* (_String_): The Master Ticket ID
            # * *iSlaveTicketID* (_String_): The Slave Ticket ID
            def executeSQL(iSQL, iUserID, iMasterTicketID, iSlaveTicketID)
              # Get the User ID
              lRedmineUserID = getUserID(iSQL, iUserID)
              # Insert a comment on the Master ticket
              iSQL.query(
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
              iSQL.query(
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
              iSQL.query(
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
              lJournalID = iSQL.insert_id()
              lOldValue = nil
              iSQL.query(
                "select status_id
                 from issues
                 where
                   id = #{iSlaveTicketID}").each do |iRow|
                lOldValue = iRow[0]
              end
              iSQL.query(
                "update issues
                   set status_id = 6
                   where
                     id = #{iSlaveTicketID}")
              iSQL.query(
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
            end

          end

        end

      end

    end

  end

end
