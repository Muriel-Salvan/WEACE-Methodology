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
        
          class Test_Ticket_CloseDuplicate < Test::Unit::TestCase

            include WEACEInstall::TestToolbox::Adapters

            # Test normal behaviour
            def testNormal
              setupRepository('Virgin') do |iRepositoryDir|
                executeAdapterInstallTest("--redminedir #{iRepositoryDir}/redmine-0.8.2 --ruby /usr/bin/ruby")
                compareWithRepository('Normal')
              end
            end

            # Test duplicate behaviour
            def testDuplicate
              setupRepository('Normal') do |iRepositoryDir|
                executeAdapterInstallTest("--redminedir #{iRepositoryDir}/redmine-0.8.2 --ruby /usr/bin/ruby")
                compareWithRepository('Normal')
              end
            end

          end
          
        end
        
      end
      
    end
    
  end
  
end
