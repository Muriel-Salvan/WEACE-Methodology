#--
# Copyright (c) 2010 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACEInstall

  module Master

    module Adapters

      class DummyProductWithParams

        # Check if we can install
        #
        # Return:
        # * _Exception_: An error, or nil in case of success
        def check
          if ($Variables[:DummyProductWithParams_Calls] == nil)
            $Variables[:DummyProductWithParams_Calls] = []
          end
          $Variables[:DummyProductWithParams_Calls] << [ 'check', [] ]
          if (defined?(@DummyFlag))
            $Variables[:DummyProductWithParams_DummyFlag] = @DummyFlag
          end

          return nil
        end

        # Install for real.
        # This is called only when check method returned no error.
        #
        # Return:
        # * _Exception_: An error, or nil in case of success
        def execute
          if ($Variables[:DummyProductWithParams_Calls] == nil)
            $Variables[:DummyProductWithParams_Calls] = []
          end
          $Variables[:DummyProductWithParams_Calls] << [ 'execute', [] ]

          return nil
        end

        # Get the default configuration
        #
        # Return:
        # * _String_: The default configuration text to put in the configuration file.
        def getDefaultConfig
          if ($Variables[:DummyProductWithParams_Calls] == nil)
            $Variables[:DummyProductWithParams_Calls] = []
          end
          $Variables[:DummyProductWithParams_Calls] << [ 'getDefaultConfig', [] ]

          return "{}"
        end

      end

    end

  end

end
