# Usage: Check at the bottom of the file.
#
# Check http://weacemethod.sourceforge.net for details.
#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

# Get WEACE base directory, and add it to the LOAD_PATH
lOldDir = Dir.getwd
Dir.chdir("#{File.dirname(__FILE__)}/../../../..")
$WEACEToolkitDir = Dir.getwd
Dir.chdir(lOldDir)
$LOAD_PATH << $WEACEToolkitDir

require 'WEACE_Common.rb'

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
      # * *iUserID* (_String_): User ID of the script adding this info
      # * *iMySQLHost* (_String_): The name of the MySQL host
      # * *iDBName* (_String_): The name of the database of Redmine
      # * *iDBUser* (_String_): The name of the database user
      # * *iDBPassword* (_String_): The password of the database user
      # * *iMasterTicketID* (_String_): The Master Ticket ID
      # * *iSlaveTicketID* (_String_): The Slave Ticket ID
      def execute(iUserID, iMySQLHost, iDBName, iDBUser, iDBPassword, iMasterTicketID, iSlaveTicketID)
        execMySQL(__FILE__, iUserID, iMySQLHost, iDBName, iDBUser, iDBPassword, iMasterTicketID, iSlaveTicketID) do |iMySQL|
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
    puts 'ruby -w Redmine_TicketTracker_Ticket_RejectDuplicate.rb <UserLogin> <MySQLHost> <DBName> <DBUser> <DBPassword> <MasterTicketID> <SlaveTicketID>'
    puts 'Example: ruby -w Redmine_TicketTracker_Ticket_RejectDuplicate.rb Scripts_Validator mysql-r redminedb redminedbuser redminedbpassword 123 124'
    puts ''
    puts 'Check http://weacemethod.sourceforge.net for details.'
    exit 1
  else
    # Execute
    Redmine::TicketTracker::Ticket_RejectDuplicate.new.execute(lUserLogin, lMySQLHost, lDBName, lDBUser, lDBPassword, lMasterTicketID, lSlaveTicketID)
    exit 0
  end
end
