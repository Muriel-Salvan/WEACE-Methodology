# Usage:
# ruby -w Mediawiki_Wiki_AddCommitComment.rb <MediawikiDir> <BranchName> <UserLogin> <CommitID> <CommitUser> <CommitComment>
# Example: ruby -w Mediawiki_Wiki_AddCommitComment.rb /home/groups/m/my/myproject/htdocs/wiki trunk Scripts_Developer 123 msalvan 'Committed a new change'
#
# Check http://weacemethod.sourceforge.net for details.
#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

require 'date'

module Mediawiki

  module Wiki
  
    class AddCommitComment
    
      # Add the commit information to the wiki
      #
      # Parameters:
      # * *iMediaWikiInstallationDir* (_String_): The Mediawiki installation directory
      # * *iBranchName* (_String_): Name of the branch receiving the commit
      # * *iUserID* (_String_): User ID of the script adding this info
      # * *iCommitID* (_String_): The commit ID
      # * *iCommitUser* (_String_): The commit user
      # * *iCommitComment* (_String_): The commit comment
      def self.execute(iMediaWikiInstallationDir, iBranchName, iUserID, iCommitID, iCommitUser, iCommitComment)
        # Get the existing text
        lContent = `php Mediawiki_getContent.php #{iMediaWikiInstallationDir} Changelog_#{iBranchName}`.split("\n")
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
        # Set the new text
        `echo '#{lContent.join("\n").gsub(/'/,'\\\\\'')}' | php #{iMediaWikiInstallationDir}/maintenance/edit.php -u #{iUserID} -s 'Automatic addition upon commit #{iCommitID} by #{iCommitUser}' Changelog_#{iBranchName}`
      end
      
    end
  
  end

end

# If we were invoked directly
if (__FILE__ == $0)
  # Parse command line arguments, check them, and call the main function
  lMediaWikiInstallationDir, lBranchName, lUserID, lCommitID, lCommitUser, lCommitComment = ARGV
  if ((lMediaWikiInstallationDir == nil) or
      (lBranchName == nil) or
      (lUserID == nil) or
      (lCommitID == nil) or
      (lCommitUser == nil) or
      (lCommitComment == nil))
    # Print some usage
    puts 'Usage:'
    puts 'ruby -w Mediawiki_Wiki_AddCommitComment.rb <MediawikiDir> <BranchName> <UserLogin> <CommitID> <CommitUser> <CommitComment>'
    puts 'Example: ruby -w Mediawiki_Wiki_AddCommitComment.rb /home/groups/m/my/myproject/htdocs/wiki trunk Scripts_Developer 123 msalvan \'Committed a new change\''
    puts ''
    puts 'Check http://weacemethod.sourceforge.net for details.'
    exit 1
  else
    # Execute
    Mediawiki::Wiki::AddCommitComment::execute(lMediaWikiInstallationDir, lBranchName, lUserID, lCommitID, lCommitUser, lCommitComment)
    exit 0
  end
end
