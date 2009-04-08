# Usage:
# ruby -w Redmine_TicketTracker_AddCommitComment.rb <UserLogin> <MySQLHost> <DBName> <DBUser> <DBPassword> <TicketID> <BranchName> <CommitID> <CommitUser> <CommitComment>
# Example: ruby -w Redmine_TicketTracker_AddCommitComment.rb Scripts_Developer mysql-r redminedb redminedbuser redminedbpassword 123 trunk 456 msalvan 'Committed a part of this Ticket'
#
# Check http://weacemethod.sourceforge.net for details.
#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

require '../Redmine_Common'
require 'date'

module Redmine

  module TicketTracker
  
    class AddCommitComment
    
      # Add the commit information to the ticket
      #
      # Parameters:
      # * *iUserID* (_String_): User ID of the script adding this info
      # * *iMySQLHost* (_String_): The name of the MySQL host
      # * *iDBName* (_String_): The name of the database of Redmine
      # * *iDBUser* (_String_): The name of the database user
      # * *iDBPassword* (_String_): The pasword of the database user
      # * *iTicketID* (_String_): The Ticket ID
      # * *iBranchName* (_String_): Name of the branch receiving the commit
      # * *iCommitID* (_String_): The commit ID
      # * *iCommitUser* (_String_): The commit user
      # * *iCommitComment* (_String_): The commit comment
      def self.execute(iUserID, iMySQLHost, iDBName, iDBUser, iDBPassword, iTicketID, iBranchName, iCommitID, iCommitUser, iCommitComment)
        require 'rubygems'
        require 'mysql'
        # Connect to the db
        lMySQLConnection = Mysql::new(iMySQLHost, iDBName, iDBUser, iDBPassword)
        # Get the User ID
        lRedmineUserID = Redmine::getUserID(lMySQLConnection, iUserID)
        # Insert a comment on the ticket
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
               #{lRedmineUserID},
               '[#{DateTime.now.strftime('%Y-%m-%d %H:%M:%S')}] - A new Commit (ID=#{iCommitID}) from #{iCommitUser} on branch #{iBranchName} is affecting this Ticket:\n#{iCommitComment.gsub(/'/,'\\\\\'')}',
               '#{DateTime.now.strftime('%Y-%m-%d %H:%M:%S')}'
             )")
      end
      
    end
  
  end

end

# If we were invoked directly
if (__FILE__ == $0)
  # Parse command line arguments, check them, and call the main function
  lUserLogin, lMySQLHost, lDBName, lDBUser, lDBPassword, lTicketID, lBranchName, lCommitID, lCommitUser, lCommitComment = ARGV
  if ((lMySQLHost == nil) or
      (lDBName == nil) or
      (lDBUser == nil) or
      (lDBPassword == nil) or
      (lUserLogin == nil) or
      (lTicketID == nil) or
      (lBranchName == nil) or
      (lCommitID == nil) or
      (lCommitUser == nil) or
      (lCommitComment == nil))
    # Print some usage
    puts 'Usage:'
    puts 'ruby -w Redmine_TicketTracker_AddCommitComment.rb <UserLogin> <MySQLHost> <DBName> <DBUser> <DBPassword> <TicketID> <BranchName> <CommitID> <CommitUser> <CommitComment>'
    puts 'Example: ruby -w Redmine_TicketTracker_AddCommitComment.rb Scripts_Developer mysql-r redminedb redminedbuser redminedbpassword 123 trunk 456 msalvan \'Committed a part of this Ticket\''
    puts ''
    puts 'Check http://weacemethod.sourceforge.net for details.'
    exit 1
  else
    # Execute
    Redmine::TicketTracker::AddCommitComment::execute(lUserLogin, lMySQLHost, lDBName, lDBUser, lDBPassword, lTicketID, lBranchName, lCommitID, lCommitUser, lCommitComment)
  end
end
