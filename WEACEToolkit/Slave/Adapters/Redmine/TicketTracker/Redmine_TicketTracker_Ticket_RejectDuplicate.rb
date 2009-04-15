# Usage: This file is used by others.
# Do not call it directly.
#
# Check http://weacemethod.sourceforge.net for details.
#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

require 'Slave/Adapters/Redmine/Redmine_Common.rb'
require 'date'

module Redmine

  module TicketTracker
  
    class Ticket_RejectDuplicate
    
      include WEACE::Logging
      include WEACE::Toolbox
      include WEACE::Slave::Adapters::Redmine::Common
      
      # Mark 2 tickets as duplicated and close the slave ticket
      #
      # Parameters:
      # * *iMySQL* (_MySQL_): The MySQL connection
      # * *iUserID* (_String_): User ID of the script adding this info
      # * *iMasterTicketID* (_String_): The Master Ticket ID
      # * *iSlaveTicketID* (_String_): The Slave Ticket ID
      def executeSQL(iMySQL, iUserID, iMasterTicketID, iSlaveTicketID)
        # Get the User ID
        lRedmineUserID = getUserID(iMySQL, iUserID)
        # Insert a comment on the Master ticket
        iMySQL.query(
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
        iMySQL.query(
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
        iMySQL.query(
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
        lJournalID = iMySQL.insert_id()
        lOldValue = nil
        iMySQL.query(
          "select status_id
           from issues
           where
             id = #{iSlaveTicketID}").each do |iRow|
          lOldValue = iRow[0]
        end
        iMySQL.query(
          "update issues
             set status_id = 6
             where
               id = #{iSlaveTicketID}")
        iMySQL.query(
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
    
      # Mark 2 tickets as duplicated and close the slave ticket
      #
      # Parameters:
      # * *iUserID* (_String_): User ID of the script adding this info
      # * *iMySQLHost* (_String_): The name of the MySQL host
      # * *iDBName* (_String_): The name of the database of Redmine
      # * *iDBUser* (_String_): The name of the database user
      # * *iDBPassword* (_String_): The password of the database user
      # * *iMasterTicketID* (_String_): The Master Ticket ID
      # * *iSlaveTicketID* (_String_): The Slave Ticket ID
      def execute(iUserID, iMySQLHost, iDBName, iDBUser, iDBPassword, iMasterTicketID, iSlaveTicketID)
        execSQLOtherSession(iMySQLHost, iDBName, iDBUser, iDBPassword, iUserID, iMasterTicketID, iSlaveTicketID)
      end
      
    end
  
  end

end
