# Usage: This file is used by other files.
# Do not call it directly.
#
# Check http://weacemethod.sourceforge.net for details.
#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

require 'Install/Master/Adapters/Redmine/Install_Redmine_Common.rb'

module WEACEInstall

  module Master
  
    module Adapters
  
      module Redmine
      
        module TicketTracker
        
          class Ticket_CloseDuplicate
          
            include WEACE::Logging
            include WEACEInstall::Common
            
            # Get options of this installer
            #
            # Parameters:
            # * *ioDescription* (_ComponentDescription_): The component's description to fill
            def getDescription(ioDescription)
              ioDescription.Version = '0.0.1.20090414'
              ioDescription.Description = 'This adapter is triggered when a Ticket is marked as duplicating another one.'
              ioDescription.Author = 'murielsalvan@users.sourceforge.net'
              ioDescription.addVarOption(:RedmineDir,
                '-d', '--redminedir <RedmineDir>', String,
                '<RedmineDir>: Redmine\'s installation directory.',
                'Example: /home/groups/m/my/myproject/redmine')
              ioDescription.addVarOption(:RubyPath,
                '-r', '--ruby <RubyPath>', String,
                '<RubyPath>: Ruby\'s path.',
                'Example: /usr/bin/ruby')
            end
            
            # Execute the installation
            #
            # Parameters:
            # * *iParameters* (<em>list<String></em>): Additional parameters to give the installer
            # * *iProviderEnv* (_ProviderEnv_): The Provider specific environment
            # Return:
            # * _Boolean_: Has the operation completed successfully ?
            def execute(iParameters, iProviderEnv)
              # First, modify common parts
              WEACEInstall::Master::Adapters::Redmine::CommonInstall.new.execute(@RedmineDir, iProviderEnv)
              # Modify the issue_relations view to add the WEACE icon
              log "Modify issue_relations view ..."
              lIssueRelationsViewFileName = "#{@RedmineDir}/app/views/issue_relations/_form.rhtml"
              lContent = []
              File.open(lIssueRelationsViewFileName, 'r') do |iFile|
                lContent = iFile.readlines
              end
              File.open(lIssueRelationsViewFileName, 'w') do |iFile|
                lIdxLine = 0
                lModified = false
                lContent.each do |iLine|
                  iFile << iLine
                  if ((!lModified) and
                      (iLine.match(/<%= toggle_link l\(:button_cancel\), 'new-relation-form'%>/) != nil))
                    # Check the next line if it was already inserted
                    if ((lContent[lIdxLine + 1] != nil) and
                        (lContent[lIdxLine + 1].match(/<a title=/) != nil))
                      # Already inserted
                      logWarn "The issue_relations view (#{lIssueRelationsViewFileName}) was already modified."
                    else
                      # Insert it
                      iFile << "<a title=\"In case of duplicates, this will trigger the WEACE process named Ticket_CloseDuplicate. Click for explanations.\" href=\"#{iProviderEnv.CGIURL}/WEACE/ShowInstalledMasterAdapters.cgi#Redmine.TicketTracker.Ticket_CloseDuplicate\"><img src=\"http://weacemethod.sourceforge.net/wiki/images/1/1e/MasterIcon.png\" alt=\"In case of duplicates, this will trigger the WEACE process named Ticket_CloseDuplicate. Click for explanations.\"/></a>\n"
                    end
                    lModified = true
                  end
                  lIdxLine += 1
                end
                if (!lModified)
                  logErr "The issue_relations view (#{lIssueRelationsViewFileName}) could not be modified: no line matched the pattern /<%= toggle_link l\(:button_cancel\), 'new-relation-form'%>/"
                end
              end
              # Modify the issue_relations controller
              log "Modify issue_relations controller ..."
              lIssueRelationsControllerFileName = "#{@RedmineDir}/app/controllers/issue_relations_controller.rb"
              lContent = []
              File.open(lIssueRelationsControllerFileName, 'r') do |iFile|
                lContent = iFile.readlines
              end
              File.open(lIssueRelationsControllerFileName, 'w') do |iFile|
                lIdxLine = 0
                lModified = false
                lContent.each do |iLine|
                  if (!lModified)
                    if (iLine.match(/@relation.save if request.post?/) != nil)
                      # Insert the modifications
                      iFile << "
    # === Changed by WEACE Master Adapter for Redmine/TicketTracker... ===
    if (request.post?)
      if (@relation.relation_type == IssueRelation::TYPE_DUPLICATES)
        # Call WEACE Master Server
        lCommand = \"cd #{$WEACEToolkitDir}/Master/Server; #{@RubyPath} -w WEACEMasterServer.rb Scripts_Validator Ticket_CloseDuplicate \#{@relation.issue_to_id} \#{@issue.id} 2>&1\"
        lOutput = `\#{lCommand}`
        lErrorCode = $?
        if (lErrorCode != 0)
          @relation.save
          logger.error(\"Call to WEACE Master Server failed (error code \#{lErrorCode}). Here is the command: \#{lCommand}. Here is its output: \#{lOutput}.\")
          flash[:warning] = l('Error while calling WEACE Master Server. Please check logs to get further details. The action has still be performed without notifying WEACE Master Server.')
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
"
                      lModified = true
                    elsif (iLine.match(/WEACE Master Adapter/) != nil)
                      logWarn "The issue_relations controller (#{lIssueRelationsControllerFileName}) was already modified."
                      lModified = true
                      iFile << iLine
                    else
                      iFile << iLine
                    end
                  else
                    iFile << iLine
                  end
                  lIdxLine += 1
                end
                if (!lModified)
                  logErr "The issue_relations controller (#{lIssueRelationsControllerFileName}) could not be modified: no line matched the pattern /@relation.save if request.post?/"
                end
              end
              log "Installation completed successfully."
              return true
            end
            
          end
          
        end
        
      end
      
    end
    
  end
  
end
