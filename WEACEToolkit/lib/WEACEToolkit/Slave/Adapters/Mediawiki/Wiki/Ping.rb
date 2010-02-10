# Usage:
# ruby -w Mediawiki_Wiki_AddCommitComment.rb <UserLogin> <MediawikiDir> <BranchName> <CommitID> <CommitUser> <CommitComment>
# Example: ruby -w Mediawiki_Wiki_AddCommitComment.rb Scripts_Developer /home/groups/m/my/myproject/htdocs/wiki trunk 123 msalvan 'Committed a new change'
#
# Check http://weacemethod.sourceforge.net for details.
#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

require 'date'

module WEACE

  module Slave

    module Adapters

      module Mediawiki

        module Wiki

          class Ping

            include WEACE::Toolbox
            
            # Add the commit information to the wiki
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
            def execute(iUserID)
              checkVar(:MediaWikiInstallationDir, 'The directory where Mediawiki is installed')

              # Get the existing text
              lContent = `php ../Mediawiki_getContent.php #{@MediaWikiInstallationDir} Tester_Log`.split("\n")
              # Add a new entry at the end of the Tester Log
              lContent << "* [#{DateTime.now.strftime('%Y-%m-%d %H:%M:%S')}] - Ping Mediawiki/Wiki."
              # Set the new text
              `echo '#{lContent.join("\n").gsub(/'/,'\\\\\'')}' | php #{@MediaWikiInstallationDir}/maintenance/edit.php -u #{iUserID} -s 'Automatic addition upon ping' Tester_Log`

              return nil
            end

          end

        end

      end

    end

  end

end
