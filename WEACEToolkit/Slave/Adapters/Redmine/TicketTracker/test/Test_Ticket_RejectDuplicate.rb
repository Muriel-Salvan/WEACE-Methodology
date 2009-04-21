# Usage: This file is used by other files.
# Do not call it directly.
#
# Check http://weacemethod.sourceforge.net for details.
#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

module WEACE

  module Slave
  
    module Adapters
  
      module Redmine
      
        module TicketTracker
        
          class Test_Ticket_RejectDuplicate < Test::Unit::TestCase

            include WEACE::TestToolbox::Adapters

            # Test normal behaviour
            def testNormal
              setupRepository('Virgin') do |iRepositoryDir|
                setupMySQL('Virgin') do |iDBHost, iDBName, iDBUser, iDBPassword|
                  executeSlaveAdapterTest({
                      :RedmineDir => "#{iRepositoryDir}/redmine-0.8.2",
                      :DBHost => iDBHost,
                      :DBName => iDBName,
                      :DBUser => iDBUser,
                      :DBPassword => iDBPassword
                    },
                    '1',
                    '2')
                  compareWithMySQL('Normal')
                end
                compareWithRepository('Virgin')
              end
            end

          end
          
        end
        
      end
      
    end
    
  end
  
end
