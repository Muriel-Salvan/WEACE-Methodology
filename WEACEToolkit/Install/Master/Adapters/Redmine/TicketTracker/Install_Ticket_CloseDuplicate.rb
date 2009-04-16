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
            include WEACE::Toolbox
            include WEACEInstall::Common
            include WEACEInstall::Master::Adapters::Redmine::CommonInstall
            
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
            def execute(iParameters, iProviderEnv)
              # First, modify common parts
              executeRedmineCommonInstall(@RedmineDir, iProviderEnv)
              # Modify the issue_relations view to add the WEACE icon
              modifyFile("#{@RedmineDir}/app/views/issue_relations/_form.rhtml",
                /<%= toggle_link l\(:button_cancel\), 'new-relation-form'%>/,
                "<a title=\"In case of duplicates, this will trigger the WEACE process named Ticket_CloseDuplicate. Click for explanations.\" href=\"#{iProviderEnv.CGIURL}/WEACE/ShowWEACEMasterInfo.cgi#Redmine.TicketTracker.Ticket_CloseDuplicate\"><img src=\"http://weacemethod.sourceforge.net/wiki/images/1/1e/MasterIcon.png\" alt=\"In case of duplicates, this will trigger the WEACE process named Ticket_CloseDuplicate. Click for explanations.\"/></a>\n",
                /<\/p>/)
              # Modify the issue_relations controller
              modifyFile("#{@RedmineDir}/app/controllers/issue_relations_controller.rb",
                /@relation.issue_from = @issue/,
                "
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
                :Replace => true)
            end
            
          end
          
        end
        
      end
      
    end
    
  end
  
end
