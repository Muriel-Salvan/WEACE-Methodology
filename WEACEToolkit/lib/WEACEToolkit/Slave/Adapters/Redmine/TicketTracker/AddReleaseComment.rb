# Usage:
# ruby -w Redmine_TicketTracker_AddReleaseComment.rb <UserLogin> <MySQLHost> <DBName> <DBUser> <DBPassword> <TicketID> <BranchName> <ReleaseVersion> <ReleaseUser> <ReleaseComment>
# Example: ruby -w Redmine_TicketTracker_AddReleaseComment.rb Scripts_Developer mysql-r redminedb redminedbuser redminedbpassword 123 trunk 0.2.20090407 msalvan 'Releaseted a part of this Ticket'
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

          class AddReleaseComment

            include WEACE::Toolbox
            include WEACE::Slave::Adapters::Redmine::Common

            # Add the release information to the ticket
            #
            # Parameters:
            # * *iUserID* (_String_): User ID of the script adding this info
            # * *iTicketID* (_String_): The Ticket ID
            # * *iBranchName* (_String_): Name of the branch receiving the commit
            # * *iReleaseVersion* (_String_): The Release version
            # * *iReleaseUser* (_String_): The Release user
            # * *iReleaseComment* (_String_): The Release comment
            # Return:
            # * _Exception_: An error, or nil in case of success
            def execute(iUserID, iTicketID, iBranchName, iReleaseVersion, iReleaseUser, iReleaseComment)
              checkVar(:RedmineDir, 'The directory where Redmine is installed')
              checkVar(:DBHost, 'The name of the MySQL host')
              checkVar(:DBName, 'The name of the database of Redmine')
              checkVar(:DBUser, 'The name of the database user')
              checkVar(:DBPassword, 'The password of the database user')
#              execMySQLOtherSession(@RedmineDir, @DBHost, @DBName, @DBUser, @DBPassword, iUserID, iTicketID, iBranchName, iReleaseVersion, iReleaseUser, iReleaseComment)
              execMySQL(@DBHost, @DBName, @DBUser, @DBPassword, iUserID, iTicketID, iBranchName, iReleaseVersion, iReleaseUser, iReleaseComment)
              return nil
            end

            # Execute the corresponding SQL statements
            #
            # Parameters:
            # * *iSQL* (_Object_): The SQL connection
            # * *iUserID* (_String_): User ID of the script adding this info
            # * *iTicketID* (_String_): The Ticket ID
            # * *iBranchName* (_String_): Name of the branch receiving the commit
            # * *iReleaseVersion* (_String_): The Release version
            # * *iReleaseUser* (_String_): The Release user
            # * *iReleaseComment* (_String_): The Release comment
            def executeSQL(iSQL, iUserID, iTicketID, iBranchName, iReleaseVersion, iReleaseUser, iReleaseComment)
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
                     '[#{lNow.strftime('%Y-%m-%d %H:%M:%S')}] - Release #{iReleaseVersion} (released by #{iReleaseUser}) is shipping modifications made for this Ticket:\n#{iReleaseComment.gsub(/'/,'\\\\\'')}',
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
