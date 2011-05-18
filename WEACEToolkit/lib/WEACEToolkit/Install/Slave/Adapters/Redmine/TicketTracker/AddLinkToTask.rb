# Usage: This file is used by other files.
# Do not call it directly.
#
# Check http://weacemethod.sourceforge.net for details.
#--
# Copyright (c) 2009 - 2011 Muriel Salvan  (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

module WEACEInstall

  module Slave
  
    module Adapters
  
      class Redmine
      
        class TicketTracker
        
          class AddLinkToTask

            # Install for real.
            # This is called only when check method returned no error.
            #
            # Return:
            # * _Exception_: An error, or nil in case of success
            def execute
              return nil
            end

          end
            
        end
        
      end
      
    end
    
  end
  
end
