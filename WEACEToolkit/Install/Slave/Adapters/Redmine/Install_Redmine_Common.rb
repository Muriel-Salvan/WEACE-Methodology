# This file is used by the WEACE Slave Adapters installers.
# Do not use it directly.
#
# Check http://weacemethod.sourceforge.net for details.
#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

module WEACEInstall

  module Slave
  
    module Adapters
    
      module Redmine
  
        class CommonInstall
          
          include WEACE::Logging
          include WEACE::Toolbox
          
          # Install the common part of every adapter for Redmine.
          #
          # Parameters:
          # * *iRedmineInstallationDir* (_String_): The redmine installation directory
          # * *iProviderEnv* (_ProviderEnv_): The provider environment
          def executeRedmineCommonInstall(iRedmineInstallationDir, iProviderEnv)
            # Modify the layouts/base view to add WEACE Master icon if not already present
            modifyFile("#{iRedmineInstallationDir}/app/views/layouts/base.rhtml",
              /Powered by <%= link_to Redmine/,
              "<a title=\"Some content of this website can be modified by some WEACE processes. Click for explanations.\" href=\"#{iProviderEnv.CGIURL}/WEACE/ShowInstalledSlaveAdapters.cgi#Redmine\"><img src=\"http://weacemethod.sourceforge.net/wiki/images/9/95/WEACESlave.png\" alt=\"Some content of this website can be modified by some WEACE processes. Click for explanations.\"/></a>\n",
              /<\/div>/)
            end
            
          end
          
        end
        
      end
      
    end
    
  end
  
end
