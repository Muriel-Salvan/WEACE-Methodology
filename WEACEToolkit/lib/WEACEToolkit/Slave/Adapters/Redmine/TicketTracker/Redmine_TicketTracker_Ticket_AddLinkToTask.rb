# Usage:
# ruby -w Redmine_TicketTracker_Ticket_AddLinkToTask.rb <UserLogin> <MySQLHost> <DBName> <DBUser> <DBPassword> <TicketID> <TaskID> <TaskName>
# Example: ruby -w Redmine_TicketTracker_Ticket_AddLinkToTask.rb Scripts_Planner mysql-r redminedb redminedbuser redminedbpassword 123 45 'Name of my task'
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
  
    class Ticket_AddLinkToTask
    
      # Add the task reference to the corresponding ticket
      #
      # Parameters:
      # * *iUserID* (_String_): User ID of the script adding this info
      # * *iMySQLHost* (_String_): The name of the MySQL host
      # * *iDBName* (_String_): The name of the database of Redmine
      # * *iDBUser* (_String_): The name of the database user
      # * *iDBPassword* (_String_): The pasword of the database user
      # * *iTicketID* (_String_): The Ticket ID
      # * *iTaskID* (_String_): The Task ID
      # * *iTaskName* (_String_): The Task name to add into the comment
      def self.execute(iUserID, iMySQLHost, iDBName, iDBUser, iDBPassword, iTicketID, iTaskID, iTaskName)
        require 'rubygems'
        require 'mysql'
        # Connect to the db
        lMySQLConnection = Mysql::new(iMySQLHost, iDBUser, iDBPassword, iDBName)
        # Get the User ID
        lRedmineUserID = Redmine::getUserID(lMySQLConnection, iUserID)
        # Insert a comment for the Ticket
        lMySQLConnection.query(
          "insert
             into journals
             ( journalized_id,
               journalized_type,
               user_id,
               notes,
               created_on )
             values (
               #{iTicketID},
               'Issue',
               #{lRedmineUserID},
               '[#{DateTime.now.strftime('%Y-%m-%d %H:%M:%S')}] - This Ticket has been linked to Task \"#{iTaskName.gsub(/'/,'\\\\\'')}\" (ID: #{iTaskID})',
               '#{DateTime.now.strftime('%Y-%m-%d %H:%M:%S')}'
             )")
      end
      
    end
  
  end

end

# If we were invoked directly
if (__FILE__ == $0)
  # Parse command line arguments, check them, and call the main function
  lUserLogin, lMySQLHost, lDBName, lDBUser, lDBPassword, lTicketID, lTaskID, lTaskName = ARGV
  if ((lMySQLHost == nil) or
      (lDBName == nil) or
      (lDBUser == nil) or
      (lDBPassword == nil) or
      (lUserLogin == nil) or
      (lTicketID == nil) or
      (lTaskID == nil) or
      (lTaskName == nil))
    # Print some usage
    puts 'Usage:'
    puts 'ruby -w Redmine_TicketTracker_Ticket_AddLinkToTask.rb <UserLogin> <MySQLHost> <DBName> <DBUser> <DBPassword> <TicketID> <TaskID> <TaskName>'
    puts 'Example: ruby -w Redmine_TicketTracker_Ticket_AddLinkToTask.rb Scripts_Planner mysql-r redminedb redminedbuser redminedbpassword 123 45 \'Name of my task\''
    puts ''
    puts 'Check http://weacemethod.sourceforge.net for details.'
    exit 1
  else
    # Execute
    Redmine::TicketTracker::Ticket_AddLinkToTask::execute(lUserLogin, lMySQLHost, lDBName, lDBUser, lDBPassword, lTicketID, lTaskID, lTaskName)
    exit 0
  end
end
