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
  
    module Adapters
  
      module Redmine
      
        module TicketTracker
        
          class Test_Ticket_RejectDuplicate < Test::Unit::TestCase

            include WEACEInstall::TestToolbox::Adapters

            # Test normal behaviour
            def testNormal
              executeTest('TestSample', "--redminedir %{Repository}/redmine-0.8.2 --rubygemslib %{Repository}/rubygems/lib --gems %{Repository}/rubygems/gems --mysql %{Repository}/mysql/lib", 'Normal')
            end

            # Test duplicate behaviour
            def testDuplicate
              executeTest('Normal', "--redminedir %{Repository}/redmine-0.8.2  --rubygemslib %{Repository}/rubygems/lib --gems %{Repository}/rubygems/gems --mysql %{Repository}/mysql/lib", 'Normal')
            end

          end
          
        end
        
      end
      
    end
    
  end
  
end
