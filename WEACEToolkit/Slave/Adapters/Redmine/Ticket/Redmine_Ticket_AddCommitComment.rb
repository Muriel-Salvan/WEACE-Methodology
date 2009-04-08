# Usage:
# ruby -w Redmine_Ticket_AddCommitComment.rb <MySQLHost> <DBName> <DBUser> <DBPassword> <UserLogin> <TicketID> <BranchName> <CommitID> <CommitUser> <CommitComment>
# Example: ruby -w Redmine_Ticket_AddCommitComment.rb mysql-r redminedb redminedbuser redminedbpassword Scripts_Developer 123 trunk 456 msalvan 'Committed a part of this Ticket'
#
# Check http://weacemethod.sourceforge.net for details.
#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

require '../Redmine_Common'
require 'date'

module Redmine

  module Ticket
  
    class AddCommitComment
    
      # Add the commit information to the ticket
      #
      # Parameters:
      # * *iMySQLConnection* (_Mysql_): The MySQL connection
      # * *iUserID* (_String_): User ID of the script adding this info
      # * *iTicketID* (_String_): The Ticket ID
      # * *iBranchName* (_String_): Name of the branch receiving the commit
      # * *iCommitID* (_String_): The commit ID
      # * *iCommitUser* (_String_): The commit user
      # * *iCommitComment* (_String_): The commit comment
      def self.execute(iMySQLConnection, iUserID, iTicketID, iBranchName, iCommitID, iCommitUser, iCommitComment)
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
               #{iUserID},
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
  lMySQLHost, lDBName, lDBUser, lDBPassword, lUserLogin, lTicketID, lBranchName, lCommitID, lCommitUser, lCommitComment = ARGV
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
    puts 'ruby -w Redmine_Ticket_AddCommitComment.rb <MySQLHost> <DBName> <DBUser> <DBPassword> <UserLogin> <TicketID> <BranchName> <CommitID> <CommitUser> <CommitComment>'
    puts 'Example: ruby -w Redmine_Ticket_AddCommitComment.rb mysql-r redminedb redminedbuser redminedbpassword Scripts_Developer 123 trunk 456 msalvan \'Committed a part of this Ticket\''
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
      Redmine::Ticket::AddCommitComment::execute(lMySQLConnection, lUserID, lTicketID, lBranchName, lCommitID, lCommitUser, lCommitComment)
      lMySQLConnection.query("commit")
      exit 0
    rescue RuntimeError
      lMySQLConnection.query("rollback")
      raise
    end
  end
end
