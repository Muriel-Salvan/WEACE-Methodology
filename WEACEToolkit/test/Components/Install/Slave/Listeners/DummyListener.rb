# Usage: This file is used by other files.
# Do not call it directly.
#
# Check http://weacemethod.sourceforge.net for details.
#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

module WEACEInstall

  module Slave
  
    module Listeners
  
      class DummyListener
          
        include WEACE::Test::Install::GenericComponentTestBody
        
      end
        
    end
    
  end

end
