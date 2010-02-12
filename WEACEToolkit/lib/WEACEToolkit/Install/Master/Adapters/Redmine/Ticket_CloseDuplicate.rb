# Usage: This file is used by other files.
# Do not call it directly.
#
# Check http://weacemethod.sourceforge.net for details.
#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

module WEACEInstall

  module Master
  
    module Adapters
  
      class Redmine
      
        class Ticket_CloseDuplicate

          include WEACE::Common

          # Check if we can install
          #
          # Return:
          # * _Exception_: An error, or nil in case of success
          def check
            return performModify(false)
          end

          # Install for real.
          # This is called only when check method returned no error.
          #
          # Return:
          # * _Exception_: An error, or nil in case of success
          def execute
            return performModify(true)
          end

          private

          # Perform modifications or simulate them
          #
          # Parameters:
          # * *iCommitModifications* (_Boolean_): Do we really perform the modifications ?
          # Return:
          # * _Exception_: An error, or nil in case of success
          def performModify(iCommitModifications)
            rError = nil

            # Modify the issue_relations view to add the WEACE icon
            rError = modifyFile("#{@ProductConfig[:RedmineDir]}/app/views/issue_relations/_form.rhtml",
              /<%= toggle_link l\(:button_cancel\), 'new-relation-form'%>/,
              "<a title=\"In case of duplicates, this will trigger the WEACE process named Ticket_CloseDuplicate. Click for explanations.\" href=\"#{@ProviderEnv[:WEACEMasterInfoURL]}#Redmine.TicketTracker.Ticket_CloseDuplicate\"><img src=\"http://weacemethod.sourceforge.net/wiki/images/1/1e/MasterIcon.png\" alt=\"In case of duplicates, this will trigger the WEACE process named Ticket_CloseDuplicate. Click for explanations.\"/></a>\n",
              /<\/p>/,
              :CommitModifications => iCommitModifications)
            if (rError == nil)
              # Modify the issue_relations controller
              rError = modifyFile("#{@ProductConfig[:RedmineDir]}/app/controllers/issue_relations_controller.rb",
                /@relation.issue_from = @issue/,
                  "
    # === Changed by WEACE Master Adapter for Redmine/TicketTracker... ===
    if (request.post?)
      if (@relation.relation_type == IssueRelation::TYPE_DUPLICATES)
        # Call WEACE Master Server
        lCommand = \"#{@ProviderEnv[:WEACEExecuteCmd]} MasterServer Scripts_Validator Ticket_CloseDuplicate \#{@relation.issue_to_id} \#{@issue.id} 2>&1\"
        lOutput = `\#{lCommand}`
        lErrorCode = $?
        if (lErrorCode != 0)
          @relation.save
          logger.error(\"Call to WEACE Master Server failed (error code \#{lErrorCode}). Here is the command: \#{lCommand}. Here is its output: \#{lOutput}.\")
          flash[:warning] = l('Error while calling WEACE Master Server. Please check logs to get further details. The action was still performed as if WEACE Master Server was not installed.')
        else
          flash[:notice] = l('WEACE Master Server processed request successfully.')
        end
        render :update do |page|
          page.redirect_to(:controller => 'issues', :action => 'show', :id => @issue)
        end
        return
      else
        @relation.save
      end
    end
    # === ... End of change ===
",
                /respond_to do \|format\|/,
                :Replace => true,
                :CommitModifications => iCommitModifications)
            end

            return rError
          end

        end

      end

    end

  end

end
