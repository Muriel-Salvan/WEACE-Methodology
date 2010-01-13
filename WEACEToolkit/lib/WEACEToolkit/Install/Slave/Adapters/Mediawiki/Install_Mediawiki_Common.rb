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
    
      module Mediawiki
  
        module CommonInstall
          
          include WEACE::Toolbox

          # Install the common part of every Adapter for Mediawiki.
          def installMediawikiWEACESlaveLink
            # Modify the skin to add WEACE icon if not already present
            modifyFile(
              "#{@MediawikiDir}/includes/Skin.php",
              /function getPoweredBy\(\) \{/,
              "    $img = $img.'<a title=\"Some content of this website can be modified by some WEACE processes. Click for explanations.\" href=\"#{@ProviderConfig[:WEACESlaveInfoURL]}#Adapters.Mediawiki\"><img src=\"http://weacemethod.sourceforge.net/wiki/images/9/95/WEACESlave.png\" alt=\"Some content of this website can be modified by some WEACE processes. Click for explanations.\"/></a>'; /* WEACE Slave Insert */\n",
              /return /,
              :CheckMatch => [
                /\/\* WEACE Slave Insert \*\//
              ],
              :ExtraLinesDuringMatch => true
            )
          end

        end
        
      end
      
    end
    
  end
  
end
