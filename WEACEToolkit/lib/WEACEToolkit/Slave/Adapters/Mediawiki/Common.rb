# Usage:
# ruby -w Mediawiki_Wiki_AddCommitComment.rb <UserLogin> <MediawikiDir> <BranchName> <CommitID> <CommitUser> <CommitComment>
# Example: ruby -w Mediawiki_Wiki_AddCommitComment.rb Scripts_Developer /home/groups/m/my/myproject/htdocs/wiki trunk 123 msalvan 'Committed a new change'
#
# Check http://weacemethod.sourceforge.net for details.
#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

module WEACE

  module Slave

    module Adapters

      module Mediawiki

        module Common

          # Setup a Mediawiki session.
          # This will hide the fact we are in a web server transaction (as Mediawiki protects from this),
          # and will setup some instance variables used by further methods.
          #
          # Parameters:
          # * *iUserID* (_String_): The user ID that will perform operations on Mediawiki
          # * *CodeBlock*: The code called once Mediawiki is setup
          # * ** Return:
          # * ** _Exception_: The error to propagate, or nil if success
          # Return:
          # * _Exception_: An error, or nil in case of success
          def initMediawiki(iUserID)
            rError = nil

            # Check that Product is configured correctly
            lMediawikiDir = @ProductConfig[:MediawikiDir]
            if (lMediawikiDir == nil)
              rError = RuntimeError.new('Mediawiki Product\'s configuration is corrupted. Missing :MediawikiDir attribute.')
            else
              @UserID = iUserID
              # Hide the fact that we were invoked from a web server, as Mediawiki forbids it.
              # TODO: Check that this is harmless for security reasons.
              lOldRequestMethod = ENV['REQUEST_METHOD']
              ENV['REQUEST_METHOD'] = nil
              rError = yield
              ENV['REQUEST_METHOD'] = lOldRequestMethod
            end

            return rError
          end

          # Write an article.
          # Uses @ProductConfig[:MediawikiDir]
          # Uses @UserID
          #
          # Parameters:
          # * *iArticleName* (_String_): Name of the article to write
          # * *iContent* (<em>list<String></em>): Content to put in the article
          # * *iComment* (_String_): Comment to associate to this edit.
          # Return:
          # * _Exception_: An error, or nil if success
          def writeArticle(iArticleName, iContent, iComment)
            rError = nil

            lResult = `echo '#{iContent.join("\n").gsub(/'/,'\\\\\'')}' | php #{@ProductConfig[:MediawikiDir]}/maintenance/edit.php -u #{@UserID} -s '#{iComment}' #{iArticleName}`.split("\n")
            if (lResult[0] != 'Saving... done')
              rError = RuntimeError.new("Error while writing #{iArticleName}: #{lResult.join("\n")}")
            end

            return rError
          end

          # Get an article's content.
          # Uses @ProductConfig[:MediawikiDir]
          #
          # Parameters:
          # * *iArticleName* (_String_): Name of the article to write
          # Return:
          # * <em>list<String></em>: The article (can be empty)
          def readArticle(iArticleName)
            return `php ../Mediawiki_getContent.php #{@ProductConfig[:MediawikiDir]} #{iArticleName}`.split("\n")
          end

          # Log an operation in Mediawiki
          # Uses @ProductConfig[:MediawikiDir]
          # Uses @UserID
          #
          # Parameters:
          # * *iOperationName* (_String_): Name of the operation to log.
          # * *iParameters* (<em>map<Symbol,Object></em>): The parameters to give the operation [optional = {}]
          # Return:
          # * _Exception_: An error, or nil if success
          def logMediawiki(iOperationName, iParameters)
            rError = nil

            lContent = readArticle('WEACE_Toolkit_Log')
            logDebug "Retrieved last Log: #{lContent[-1]}"
            # Format parameters
            # list< String >
            lStrLstParams = []
            iParameters.each do |iParam, iValue|
              lStrLstParams << "** '''#{iParam}''': <nowiki>#{iValue.inspect}</nowiki>"
            end
            # Add a new entry at the end of the WEACE Log
            lContent << "* [''#{DateTime.now.strftime('%Y-%m-%d %H:%M:%S')}''] - #{iOperationName}: #{lStrLstParams.join("\n")}"
            # Set the new text
            rError = writeArticle('WEACE_Toolkit_Log', lContent, 'Automatic addition upon log')

            return rError
          end

        end

      end

    end

  end

end
