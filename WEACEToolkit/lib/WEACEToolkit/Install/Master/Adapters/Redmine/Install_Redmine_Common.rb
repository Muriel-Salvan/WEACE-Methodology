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
  
        module CommonInstall
          
          # Install the common part of every adapter for Redmine.
          #
          # Parameters:
          # * *iRedmineInstallationDir* (_String_): The redmine installation directory
          # * *iProviderEnv* (_ProviderEnv_): The provider environment
          def executeRedmineCommonInstall(iRedmineInstallationDir, iProviderEnv)
            # Modify the layouts/base view to add WEACE Master icon if not already present
            modifyFile("#{iRedmineInstallationDir}/app/views/layouts/base.rhtml",
              /Powered by <%= link_to Redmine/,
              "    <a title=\"Some actions on this website can trigger some WEACE processes. Click for explanations.\" href=\"#{iProviderEnv[:WEACEMasterInfoURL]}#Redmine\"><img src=\"http://weacemethod.sourceforge.net/wiki/images/f/f0/WEACEMaster.png\" alt=\"Some actions on this website can trigger some WEACE processes. Click for explanations.\"/></a>\n",
              /<\/div>/)
          end
          
        end
        
      end
      
    end

  end

end
