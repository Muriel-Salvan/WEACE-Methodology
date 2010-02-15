# Usage:
# ruby -w Mediawiki_Wiki_AddCommitComment.rb <UserLogin> <MediawikiDir> <BranchName> <CommitID> <CommitUser> <CommitComment>
# Example: ruby -w Mediawiki_Wiki_AddCommitComment.rb Scripts_Developer /home/groups/m/my/myproject/htdocs/wiki trunk 123 msalvan 'Committed a new change'
#
# Check http://weacemethod.sourceforge.net for details.
#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

require 'WEACEToolkit/Slave/Adapters/Mediawiki/Common'
require 'date'

module WEACE

  module Slave

    module Adapters

      module Mediawiki

        module Wiki

          class AddCommitComment

            include WEACE::Slave::Adapters::Mediawiki::Common
            
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
            def execute(iUserID, iTicketID, iBranchName, iCommitID, iCommitUser, iCommitComment)
              return initMediawiki(iUserID) do
                rSubError = nil

                # Get the existing text
                lContent = readArticle("Changelog_#{iBranchName}")
                # Parse the Changelog to get to the end of the section named "=== Current ==="
                lIdxLine = 0
                lContent.each do |iLine|
                  if (iLine == "=== Current ===")
                    lIdxLine += 2
                    break
                  end
                  lIdxLine += 1
                end
                # If we did not get it, insert at the beginning
                if (lIdxLine == lContent.size)
                  lIdxLine = 0
                end
                # Get the lIdxLine first lines of the old content, then insert the new comment at line lIdxLine, and then copy the remaining lines
                lContent.insert(lIdxLine, "* <code><small>[#{DateTime.now.strftime('%Y-%m-%d %H:%M:%S')}]</small></code> - Commit #{iCommitID} by #{iCommitUser}: #{iCommitComment}")
                rSubError = writeArticle("Changelog_#{iBranchName}", lContent, "Automatic addition upon commit #{iCommitID} by #{iCommitUser}")
                if (rSubError == nil)
                  rSubError = logMediawiki('Mediawiki/Wiki/AddCommitComment',
                    :UserID => iUserID,
                    :TicketID => iTicketID,
                    :BranchName => iBranchName,
                    :CommitID => iCommitID,
                    :CommitUser => iCommitUser,
                    :CommitComment => iCommitComment)
                end

                next rSubError
              end
            end

          end

        end

      end

    end

  end

end
