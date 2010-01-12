# Usage:
# ruby -w Redmine_TicketTracker_AddCommitComment.rb <UserLogin> <MySQLHost> <DBName> <DBUser> <DBPassword> <TicketID> <BranchName> <CommitID> <CommitUser> <CommitComment>
# Example: ruby -w Redmine_TicketTracker_AddCommitComment.rb Scripts_Developer mysql-r redminedb redminedbuser redminedbpassword 123 trunk 456 msalvan 'Committed a part of this Ticket'
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

          class AddCommitComment

            include WEACE::Toolbox
            include WEACE::Slave::Adapters::Redmine::Common

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
              checkVar(:RedmineDir, 'The directory where Redmine is installed')
              checkVar(:DBHost, 'The name of the MySQL host')
              checkVar(:DBName, 'The name of the database of Redmine')
              checkVar(:DBUser, 'The name of the database user')
              checkVar(:DBPassword, 'The password of the database user')
#              execMySQLOtherSession(@RedmineDir, @DBHost, @DBName, @DBUser, @DBPassword, iUserID, iTicketID, iBranchName, iCommitID, iCommitUser, iCommitComment)
              execMySQL(@DBHost, @DBName, @DBUser, @DBPassword, iUserID, iTicketID, iBranchName, iCommitID, iCommitUser, iCommitComment)
              return nil
            end

            # Execute the corresponding SQL statements
            #
            # Parameters:
            # * *iSQL* (_Object_): The SQL connection
            # * *iUserID* (_String_): User ID of the script adding this info
            # * *iTicketID* (_String_): The Ticket ID
            # * *iBranchName* (_String_): Name of the branch receiving the commit
            # * *iCommitID* (_String_): The commit ID
            # * *iCommitUser* (_String_): The commit user
            # * *iCommitComment* (_String_): The commit comment
            def executeSQL(iSQL, iUserID, iTicketID, iBranchName, iCommitID, iCommitUser, iCommitComment)
              # Get the User ID
              lRedmineUserID = getUserID(iSQL, iUserID)
              # Insert a comment on the ticket
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
                     '[#{lNow.strftime('%Y-%m-%d %H:%M:%S')}] - A new Commit (ID=#{iCommitID}) from #{iCommitUser} on branch #{iBranchName} is affecting this Ticket:\n#{iCommitComment.gsub(/'/,'\\\\\'')}',
                     '#{lNow.strftime('%Y-%m-%d %H:%M:%S')}'
                   )")
              return nil
            end

          end

        end

      end

    end

  end

end
