# Usage:
# ruby -w Redmine_TicketTracker_RejectDuplicate.rb <UserLogin> <MySQLHost> <DBName> <DBUser> <DBPassword> <MasterTicketID> <SlaveTicketID>
# Example: ruby -w Redmine_TicketTracker_RejectDuplicate.rb Scripts_Validator mysql-r redminedb redminedbuser redminedbpassword 123 124
#
# Check http://weacemethod.sourceforge.net for details.
#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

require "#{File.dirname(__FILE__)}/../Redmine_Common"
require 'date'

module Redmine

  module TicketTracker
  
    class RejectDuplicate
    
      # Mark 2 tickets as duplicated and close the slave ticket
      #
      # Parameters:
      # * *iUserID* (_String_): User ID of the script adding this info
      # * *iMySQLHost* (_String_): The name of the MySQL host
      # * *iDBName* (_String_): The name of the database of Redmine
      # * *iDBUser* (_String_): The name of the database user
      # * *iDBPassword* (_String_): The pasword of the database user
      # * *iMasterTicketID* (_String_): The Master Ticket ID
      # * *iSlaveTicketID* (_String_): The Slave Ticket ID
      def self.execute(iUserID, iMySQLHost, iDBName, iDBUser, iDBPassword, iMasterTicketID, iSlaveTicketID)
        require 'rubygems'
        require 'mysql'
        # Connect to the db
        lMySQLConnection = Mysql::new(iMySQLHost, iDBName, iDBUser, iDBPassword)
        # Get the User ID
        lRedmineUserID = Redmine::getUserID(lMySQLConnection, iUserID)
        # Create a transaction
        lMySQLConnection.query("start transaction")
        begin
          # Insert a comment on the Master ticket
          iMySQLConnection.query(
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
          iMySQLConnection.query(
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
          iMySQLConnection.query(
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
          lJournalID = iMySQLConnection.insert_id()
          lOldValue = nil
          iMySQLConnection.query(
            "select status_id
             from issues
             where
               id = #{iSlaveTicketID}").each do |iRow|
            lOldValue = iRow[0]
          end
          iMySQLConnection.query(
            "update issues
               set status_id = 6
               where
                 id = #{iSlaveTicketID}")
          iMySQLConnection.query(
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
          lMySQLConnection.query("commit")
        rescue RuntimeError
          lMySQLConnection.query("rollback")
          raise
        end
      end
      
    end
  
  end

end

# If we were invoked directly
if (__FILE__ == $0)
  # Parse command line arguments, check them, and call the main function
  lUserLogin, lMySQLHost, lDBName, lDBUser, lDBPassword, lMasterTicketID, lSlaveTicketID = ARGV
  if ((lMySQLHost == nil) or
      (lDBName == nil) or
      (lDBUser == nil) or
      (lDBPassword == nil) or
      (lUserLogin == nil) or
      (lMasterTicketID == nil) or
      (lSlaveTicketID == nil))
    # Print some usage
    puts 'Usage:'
    puts 'ruby -w Redmine_TicketTracker_RejectDuplicate.rb <UserLogin> <MySQLHost> <DBName> <DBUser> <DBPassword> <MasterTicketID> <SlaveTicketID>'
    puts 'Example: ruby -w Redmine_TicketTracker_RejectDuplicate.rb Scripts_Validator mysql-r redminedb redminedbuser redminedbpassword 123 124'
    puts ''
    puts 'Check http://weacemethod.sourceforge.net for details.'
    exit 1
  else
    # Execute
    Redmine::TicketTracker::RejectDuplicate::execute(lUserLogin, lMySQLHost, lDBName, lDBUser, lDBPassword, lMasterTicketID, lSlaveTicketID)
    exit 0
  end
end
