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

            include WEACE::Common
            
            # Add the commit information to the wiki
            #
            # Parameters:
            # * *iUserID* (_String_): User ID of the script adding this info
            # * *iComment* (_String_): The Comment to associate to this Ping
            # Return:
            # * _Exception_: An error, or nil in case of success
            def execute(iUserID, iComment)
              rError = nil

              lMediawikiDir = @ProductConfig[:MediawikiDir]
              if (lMediawikiDir == nil)
                rError = RuntimeError.new('Mediawiki Product\'s configuration is corrupted. Missing :MediawikiDir attribute.')
              else
                # Get the existing text
                lContent = `php ../Mediawiki_getContent.php #{lMediawikiDir} Tester_Log`.split("\n")
                # Add a new entry at the end of the Tester Log
                lContent << "* [#{DateTime.now.strftime('%Y-%m-%d %H:%M:%S')}] - Ping Mediawiki/Wiki: #{iComment}"
                # Set the new text
                `echo '#{lContent.join("\n").gsub(/'/,'\\\\\'')}' | php #{lMediawikiDir}/maintenance/edit.php -u #{iUserID} -s 'Automatic addition upon ping' Tester_Log`
              end

              return rError
            end

          end

        end

      end

    end

  end

end
