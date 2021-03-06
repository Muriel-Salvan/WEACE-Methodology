# Usage:
# ruby -w Redmine_TicketTracker_AddReleaseComment.rb <UserLogin> <MySQLHost> <DBName> <DBUser> <DBPassword> <TicketID> <BranchName> <ReleaseVersion> <ReleaseUser> <ReleaseComment>
# Example: ruby -w Redmine_TicketTracker_AddReleaseComment.rb Scripts_Developer mysql-r redminedb redminedbuser redminedbpassword 123 trunk 0.2.20090407 msalvan 'Releaseted a part of this Ticket'
#
# Check http://weacemethod.sourceforge.net for details.
#--
# Copyright (c) 2009 - 2012 Muriel Salvan  (muriel@x-aeon.com)
# Licensed under BSD LICENSE. No warranty is provided.
#++

require 'WEACEToolkit/Slave/Adapters/Redmine/TicketTracker_Common'
require 'date'

module WEACE

  module Slave

    module Adapters

      module Redmine

        module TicketTracker

          class AddReleaseComment

            include WEACE::Slave::Adapters::Redmine::TicketTracker_Common

            # Execute SQL
            class SQL_AddReleaseComment < SQL_Execute

              include WEACE::Slave::Adapters::Redmine::Common::MiscUtils

              # Execute SQL.
              # This is the internal method used once the DB connection is active.
              #
              # Parameters::
              # * *ioSQL* (_Object_): The SQL connection
              # * *iUserID* (_String_): User ID of the script adding this info
              # * *iTicketID* (_String_): The Ticket ID
              # * *iBranchName* (_String_): Name of the branch receiving the commit
              # * *iReleaseVersion* (_String_): The Release version
              # * *iReleaseUser* (_String_): The Release user
              # * *iReleaseComment* (_String_): The Release comment
              # Return::
              # * _Exception_: An error, or nil if success
              def execute(ioSQL, iUserID, iTicketID, iBranchName, iReleaseVersion, iReleaseUser, iReleaseComment)
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
                       '[#{lNow.strftime('%Y-%m-%d %H:%M:%S')}] - Release #{iReleaseVersion} (released by #{iReleaseUser}) is shipping modifications made for this Ticket:\n#{iReleaseComment.gsub(/'/,'\\\\\'')}',
                       '#{lNow.strftime('%Y-%m-%d %H:%M:%S')}'
                     )")

                return nil
              end

            end

            # Add the release information to the ticket
            #
            # Parameters::
            # * *iUserID* (_String_): User ID of the script adding this info
            # * *iTicketID* (_String_): The Ticket ID
            # * *iBranchName* (_String_): Name of the branch receiving the commit
            # * *iReleaseVersion* (_String_): The Release version
            # * *iReleaseUser* (_String_): The Release user
            # * *iReleaseComment* (_String_): The Release comment
            # Return::
            # * _Exception_: An error, or nil in case of success
            def execute(iUserID, iTicketID, iBranchName, iReleaseVersion, iReleaseUser, iReleaseComment)
              return executeRedmine(
                SQL_AddReleaseComment.new,
                [ iUserID, iTicketID, iBranchName, iReleaseVersion, iReleaseUser, iReleaseComment ]
              )
            end

          end

        end

      end

    end

  end

end
