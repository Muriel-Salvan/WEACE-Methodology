# This file is used by the WEACE Master Adapters installers.
# Do not use it directly.
#
# Check http://weacemethod.sourceforge.net for details.
#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

module WEACEInstall

  module Master
  
    module Adapters
    
      module Redmine
  
        class CommonInstall
          
          include WEACE::Logging
          
          # Install the common part of every adapter for Redmine.
          #
          # Parameters:
          # * *iRedmineInstallationDir* (_String_): The redmine installation directory
          # * *iProviderEnv* (_ProviderEnv_): The provider environment
          def execute(iRedmineInstallationDir, iProviderEnv)
            # Modify the layouts/base view to add WEACE Master icon if not already present
            log "Modify layouts/base view ..."
            lLayoutsBaseViewFileName = "#{iRedmineInstallationDir}/app/views/layouts/base.rhtml"
            lContent = []
            File.open(lLayoutsBaseViewFileName, 'r') do |iFile|
              lContent = iFile.readlines
            end
            File.open(lLayoutsBaseViewFileName, 'w') do |iFile|
              lIdxLine = 0
              lModified = false
              lContent.each do |iLine|
                iFile << iLine
                if ((!lModified) and
                    (iLine.match(/Powered by <%= link_to Redmine/) != nil))
                  # Check the next 2 lines if it was already inserted
                  if (((lContent[lIdxLine + 1] != nil) and
                       (lContent[lIdxLine + 1].match(/ShowInstalledMasterAdapters/) != nil)) or
                      ((lContent[lIdxLine + 2] != nil) and
                       (lContent[lIdxLine + 2].match(/ShowInstalledMasterAdapters/) != nil)))
                    # Already inserted
                    logWarn "The layouts/base view (#{lLayoutsBaseViewFileName}) was already modified. This is normal if this is not the first time a WEACE Master Adapter is installed on it."
                  else
                    # Insert it
                    iFile << "<a title=\"Some actions on this website can trigger some WEACE processes. Click for explanations.\" href=\"#{iProviderEnv.CGIURL}/WEACE/ShowInstalledMasterAdapters.cgi#Redmine\"><img src=\"http://weacemethod.sourceforge.net/wiki/images/f/f0/WEACEMaster.png\" alt=\"Some actions on this website can trigger some WEACE processes. Click for explanations.\"/></a>\n"
                  end
                  lModified = true
                end
                lIdxLine += 1
              end
              if (!lModified)
                logErr "The layouts/base view (#{lIssueRelationsViewFileName}) could not be modified: no line matched the pattern /Powered by <%= link_to Redmine/"
              end
            end
            
          end
          
        end
        
      end
      
    end

  end

end
