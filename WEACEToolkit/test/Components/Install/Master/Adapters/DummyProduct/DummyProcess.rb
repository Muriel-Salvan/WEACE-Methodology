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
  
      class DummyProduct
      
        class DummyProcess

          # Check if we can install
          #
          # Return:
          # * _Exception_: An error, or nil in case of success
          def check
            if ($Variables[:DummyProduct_DummyProcess_Calls] == nil)
              $Variables[:DummyProduct_DummyProcess_Calls] = []
            end
            $Variables[:DummyProduct_DummyProcess_Calls] << [ 'check', [] ]

            return nil
          end

          # Install for real.
          # This is called only when check method returned no error.
          #
          # Return:
          # * _Exception_: An error, or nil in case of success
          def execute
            if ($Variables[:DummyProduct_DummyProcess_Calls] == nil)
              $Variables[:DummyProduct_DummyProcess_Calls] = []
            end
            $Variables[:DummyProduct_DummyProcess_Calls] << [ 'execute', [] ]

            return nil
          end

          # Get the default configuration
          #
          # Return:
          # * _String_: The default configuration text to put in the configuration file.
          def getDefaultConfig
            if ($Variables[:DummyProduct_DummyProcess_Calls] == nil)
              $Variables[:DummyProduct_DummyProcess_Calls] = []
            end
            $Variables[:DummyProduct_DummyProcess_Calls] << [ 'getDefaultConfig', [] ]

            return "{}"
          end

        end

      end

    end

  end

end
