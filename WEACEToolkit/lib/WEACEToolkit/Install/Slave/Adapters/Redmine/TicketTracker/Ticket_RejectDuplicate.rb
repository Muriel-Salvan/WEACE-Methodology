# Usage: This file is used by other files.
# Do not call it directly.
#
# Check http://weacemethod.sourceforge.net for details.
#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

require 'WEACEToolkit/Install/Slave/Adapters/Redmine/Install_Redmine_Common'

module WEACEInstall

  module Slave
  
    module Adapters
  
      module Redmine
      
        module TicketTracker
        
          class Ticket_RejectDuplicate
          
            include WEACE::Toolbox
            include WEACEInstall::Slave::Adapters::Redmine::CommonInstall
          
            # Execute the installation
            #
            # Parameters:
            # * *iParameters* (<em>list<String></em>): Additional parameters to give the installer
            # * *iProviderEnv* (_ProviderEnv_): The Provider specific environment
            # Return:
            # * _Exception_: An error, or nil in case of success
            def execute(iParameters, iProviderEnv)
              # Modify common parts
              installRedmineWEACESlaveLink(iProviderEnv)
              generateDBEnv

              return nil
            end
            
          end
            
        end
        
      end
      
    end
    
  end
  
end
