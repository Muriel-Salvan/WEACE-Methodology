# Usage:
# ruby -w Redmine_TicketTracker_Ticket_AddLinkToTask.rb <UserLogin> <MySQLHost> <DBName> <DBUser> <DBPassword> <TicketID> <TaskID> <TaskName>
# Example: ruby -w Redmine_TicketTracker_Ticket_AddLinkToTask.rb Scripts_Planner mysql-r redminedb redminedbuser redminedbpassword 123 45 'Name of my task'
#
# Check http://weacemethod.sourceforge.net for details.
#--
# Copyright (c) 2009 - 2011 Muriel Salvan  (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

require 'WEACEToolkit/Slave/Adapters/Redmine/TicketTracker_Common'
require 'date'

module WEACE

  module Slave

    module Adapters

      module Redmine

        module TicketTracker

          class AddLinkToTask

            include WEACE::Slave::Adapters::Redmine::TicketTracker_Common

            # Execute SQL
            class SQL_AddLinkToTask < SQL_Execute

              include WEACE::Slave::Adapters::Redmine::Common::MiscUtils

              # Execute SQL.
              # This is the internal method used once the DB connection is active.
              #
              # Parameters:
              # * *ioSQL* (_Object_): The SQL connection
              # * *iUserID* (_String_): User ID of the script adding this info
              # * *iTicketID* (_String_): The Ticket ID
              # * *iTaskID* (_String_): The Task ID
              # * *iTaskName* (_String_): The Task name to add into the comment
              # Return:
              # * _Exception_: An error, or nil if success
              def execute(ioSQL, iUserID, iTicketID, iTaskID, iTaskName)
                # Get the User ID
                lRedmineUserID = getUserID(ioSQL, iUserID)
                # Insert a comment for the Ticket
                lNow = DateTime.now
                ioSQL.query(
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

                return nil
              end

            end

            # Add the task reference to the corresponding ticket
            #
            # Parameters:
            # * *iUserID* (_String_): User ID of the script adding this info
            # * *iTicketID* (_String_): The Ticket ID
            # * *iTaskID* (_String_): The Task ID
            # * *iTaskName* (_String_): The Task name to add into the comment
            # Return:
            # * _Exception_: An error, or nil in case of success
            def execute(iUserID, iTicketID, iTaskID, iTaskName)
              return executeRedmine(
                SQL_AddLinkToTask.new,
                [ iUserID, iTicketID, iTaskID, iTaskName ]
              )
            end

          end

        end

      end

    end

  end

end
