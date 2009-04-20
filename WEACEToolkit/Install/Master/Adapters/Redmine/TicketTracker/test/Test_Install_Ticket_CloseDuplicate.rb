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
  
      module Redmine
      
        module TicketTracker
        
          class Test_Ticket_CloseDuplicate

            # Test normal behaviour
            #
            # Parameters:
            # * *iRepository* (_String_): The directory where the test repository has been created
            def test_Normal(iRepository)
              executeTest("--redminedir #{iRepository}/redmine-0.8.2 --ruby /usr/bin/ruby", 'Normal')
            end

            # Test duplicate behaviour
            #
            # Parameters:
            # * *iRepository* (_String_): The directory where the test repository has been created
            def test_Duplicate(iRepository)
              executeTest("--redminedir #{iRepository}/redmine-0.8.2 --ruby /usr/bin/ruby", 'Normal')
            end

          end
          
        end
        
      end
      
    end
    
  end
  
end
