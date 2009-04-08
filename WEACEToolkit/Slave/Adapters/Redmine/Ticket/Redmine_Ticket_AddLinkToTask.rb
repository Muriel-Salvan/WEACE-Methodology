# Usage:
# ruby -w Redmine_Ticket_AddLinkToTask.rb <MySQLHost> <DBName> <DBUser> <DBPassword> <UserLogin> <TicketID> <TaskID> <TaskName>
# Example: ruby -w Redmine_Ticket_AddLinkToTask.rb mysql-r redminedb redminedbuser redminedbpassword Scripts_Planner 123 45 'Name of my task'
#
# Check http://weacemethod.sourceforge.net for details.
#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

require '../Redmine_Common.rb'
require 'date'

module Redmine

  module Ticket
  
    class AddLinkToTask
    
      # Add the task reference to the corresponding ticket
      #
      # Parameters:
      # * *iMySQLConnection* (_Mysql_): The MySQL connection
      # * *iUserID* (_String_): User ID of the script adding this info
      # * *iTicketID* (_String_): The Ticket ID
      # * *iTaskID* (_String_): The Task ID
      # * *iTaskName* (_String_): The Task name to add into the comment
      def self.execute(iMySQLConnection, iUserID, iTicketID, iTaskID, iTaskName)
        # Insert a comment for the Ticket
        iMySQLConnection.query(
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
               #{iUserID},
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
  lMySQLHost, lDBName, lDBUser, lDBPassword, lUserLogin, lTicketID, lTaskID, lTaskName = ARGV
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
    puts 'ruby -w Redmine_Ticket_AddLinkToTask.rb <MySQLHost> <DBName> <DBUser> <DBPassword> <UserLogin> <TicketID> <TaskID> <TaskName>'
    puts 'Example: ruby -w Redmine_Ticket_AddLinkToTask.rb mysql-r redminedb redminedbuser redminedbpassword Scripts_Planner 123 45 \'Name of my task\''
    puts ''
    puts 'Check http://weacemethod.sourceforge.net for details.'
    exit 1
  else
    require 'rubygems'
    require 'mysql'
    # Connect to the db
    lMySQLConnection = Mysql::new(lMySQLHost, lDBUser, lDBPassword, lDBName)
    # Get the User ID
    lUserID = Redmine::getUserID(lMySQLConnection, lUserLogin)
    # Create a transaction
    lMySQLConnection.query("start transaction")
    begin
      # Execute
      Redmine::Ticket::AddLinkToTask::execute(lMySQLConnection, lUserID, lTicketID, lTaskID, lTaskName)
      lMySQLConnection.query("commit")
      exit 0
    rescue RuntimeError
      lMySQLConnection.query("rollback")
      raise
    end
  end
end
