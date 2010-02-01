#--
# Copyright (c) 2010 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACEInstall

  module Master

    module Adapters

      class DummyProductWithParamsValues

        # Check if we can install
        #
        # Return:
        # * _Exception_: An error, or nil in case of success
        def check
          if ($Variables[:DummyProductWithParamsValues_Calls] == nil)
            $Variables[:DummyProductWithParamsValues_Calls] = []
          end
          $Variables[:DummyProductWithParamsValues_Calls] << [ 'check', [] ]
          if (defined?(@DummyVar))
            $Variables[:DummyProductWithParamsValues_DummyVar] = @DummyVar
          end

          return nil
        end

        # Install for real.
        # This is called only when check method returned no error.
        #
        # Return:
        # * _Exception_: An error, or nil in case of success
        def execute
          if ($Variables[:DummyProductWithParamsValues_Calls] == nil)
            $Variables[:DummyProductWithParamsValues_Calls] = []
          end
          $Variables[:DummyProductWithParamsValues_Calls] << [ 'execute', [] ]

          return nil
        end

        # Get the default configuration
        #
        # Return:
        # * _String_: The default configuration text to put in the configuration file.
        def getDefaultConfig
          if ($Variables[:DummyProductWithParamsValues_Calls] == nil)
            $Variables[:DummyProductWithParamsValues_Calls] = []
          end
          $Variables[:DummyProductWithParamsValues_Calls] << [ 'getDefaultConfig', [] ]

          return "{}"
        end

      end

    end

  end

end
