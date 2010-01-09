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
  
      module DummyProduct
      
        module DummyTool
        
          class DummyAdapter
          
            # Execute the installation
            #
            # Parameters:
            # * *iParameters* (<em>list<String></em>): Additional parameters to give the installer
            # Return:
            # * _Exception_: An error, or nil in case of success
            def execute(iParameters)
              $Variables[:DummyAdapterInstall] = true
              
              return nil
            end
            
          end
          
        end
        
      end
      
    end
    
  end
  
end
