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

          class Ping

            include WEACE::Slave::Adapters::Mediawiki::Common
            
            # Add the commit information to the wiki
            #
            # Parameters:
            # * *iUserID* (_String_): User ID of the script adding this info
            # * *iComment* (_String_): The Comment to associate to this Ping
            # Return:
            # * _Exception_: An error, or nil in case of success
            def execute(iUserID, iComment)
              return initMediawiki(iUserID) do
                next logMediawiki('Mediawiki/Wiki/Ping',
                  :UserID => iUserID,
                  :Comment => iComment)
              end
            end

          end

        end

      end

    end

  end

end
