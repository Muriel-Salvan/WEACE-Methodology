# Usage:
# ruby -w Redmine_TicketTracker_AddCommitComment.rb <UserLogin> <MySQLHost> <DBName> <DBUser> <DBPassword> <TicketID> <BranchName> <CommitID> <CommitUser> <CommitComment>
# Example: ruby -w Redmine_TicketTracker_AddCommitComment.rb Scripts_Developer mysql-r redminedb redminedbuser redminedbpassword 123 trunk 456 msalvan 'Committed a part of this Ticket'
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

          class AddCommitComment

            include WEACE::Slave::Adapters::Redmine::TicketTracker_Common

            # Execute SQL
            class SQL_AddCommitComment < SQL_Execute

              include WEACE::Slave::Adapters::Redmine::Common::MiscUtils

              # Execute SQL.
              # This is the internal method used once the DB connection is active.
              #
              # Parameters:
              # * *ioSQL* (_Object_): The SQL connection
              # * *iUserID* (_String_): User ID of the script adding this info
              # * *iTicketID* (_String_): The Ticket ID
              # * *iBranchName* (_String_): Name of the branch receiving the commit
              # * *iCommitID* (_String_): The commit ID
              # * *iCommitUser* (_String_): The commit user
              # * *iCommitComment* (_String_): The commit comment
              # Return:
              # * _Exception_: An error, or nil if success
              def execute(ioSQL, iUserID, iTicketID, iBranchName, iCommitID, iCommitUser, iCommitComment)
                # Get the User ID
                lRedmineUserID = getUserID(ioSQL, iUserID)
                # Insert a comment on the ticket
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
                       '[#{lNow.strftime('%Y-%m-%d %H:%M:%S')}] - A new Commit (ID=#{iCommitID}) from #{iCommitUser} on branch #{iBranchName} is affecting this Ticket:\n#{iCommitComment.gsub(/'/,'\\\\\'')}',
                       '#{lNow.strftime('%Y-%m-%d %H:%M:%S')}'
                     )")

                return nil
              end

            end

            # Add the commit information to the ticket
            #
            # Parameters:
            # * *iUserID* (_String_): User ID of the script adding this info
            # * *iTicketID* (_String_): The Ticket ID
            # * *iBranchName* (_String_): Name of the branch receiving the commit
            # * *iCommitID* (_String_): The commit ID
            # * *iCommitUser* (_String_): The commit user
            # * *iCommitComment* (_String_): The commit comment
            # Return:
            # * _Exception_: An error, or nil in case of success
            def execute(iUserID, iTicketID, iBranchName, iCommitID, iCommitUser, iCommitComment)
              return executeRedmine(
                SQL_AddCommitComment.new,
                [ iUserID, iTicketID, iBranchName, iCommitID, iCommitUser, iCommitComment ]
              )
            end

          end

        end

      end

    end

  end

end
