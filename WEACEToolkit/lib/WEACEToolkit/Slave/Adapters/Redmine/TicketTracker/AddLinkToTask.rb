# Usage:
# ruby -w Redmine_TicketTracker_Ticket_AddLinkToTask.rb <UserLogin> <MySQLHost> <DBName> <DBUser> <DBPassword> <TicketID> <TaskID> <TaskName>
# Example: ruby -w Redmine_TicketTracker_Ticket_AddLinkToTask.rb Scripts_Planner mysql-r redminedb redminedbuser redminedbpassword 123 45 'Name of my task'
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

          class AddLinkToTask

            include WEACE::Toolbox
            include WEACE::Slave::Adapters::Redmine::Common

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
            # Return:
            # * _Exception_: An error, or nil in case of success
            def execute(iUserID, iTicketID, iTaskID, iTaskName)
              checkVar(:RedmineDir, 'The directory where Redmine is installed')
              checkVar(:DBHost, 'The name of the MySQL host')
              checkVar(:DBName, 'The name of the database of Redmine')
              checkVar(:DBUser, 'The name of the database user')
              checkVar(:DBPassword, 'The password of the database user')
#              execMySQLOtherSession(@RedmineDir, @DBHost, @DBName, @DBUser, @DBPassword, iUserID, iTicketID, iTaskID, iTaskName)
              execMySQL(@DBHost, @DBName, @DBUser, @DBPassword, iUserID, iTicketID, iTaskID, iTaskName)
              return nil
            end

            # Execute the corresponding SQL statements
            #
            # Parameters:
            # * *iSQL* (_Object_): The SQL connection
            # * *iUserID* (_String_): User ID of the script adding this info
            # * *iTicketID* (_String_): The Ticket ID
            # * *iTaskID* (_String_): The Task ID
            # * *iTaskName* (_String_): The Task name to add into the comment
            def executeSQL(iSQL, iUserID, iTicketID, iTaskID, iTaskName)
              # Get the User ID
              lRedmineUserID = getUserID(iSQL, iUserID)
              # Insert a comment for the Ticket
              lNow = DateTime.now
              iSQL.query(
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
                     '[#{lNow.strftime('%Y-%m-%d %H:%M:%S')}] - This Ticket has been linked to Task \"#{iTaskName.gsub(/'/,'\\\\\'')}\" (ID: #{iTaskID})',
                     '#{lNow.strftime('%Y-%m-%d %H:%M:%S')}'
                   )")
            end

          end

        end

      end

    end

  end

end
