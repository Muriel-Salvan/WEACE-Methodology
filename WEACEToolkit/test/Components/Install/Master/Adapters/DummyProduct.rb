#--
# Copyright (c) 2010 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACEInstall

  module Master

    module Adapters

      class DummyProduct

        # Check if we can install
        #
        # Return:
        # * _Exception_: An error, or nil in case of success
        def check
          if ($Variables[:DummyProduct_Calls] == nil)
            $Variables[:DummyProduct_Calls] = []
          end
          $Variables[:DummyProduct_Calls] << [ 'check', [] ]
          $Variables[:DummyProduct_AdditionalParams] = @AdditionalParameters

          return nil
        end

        # Install for real.
        # This is called only when check method returned no error.
        #
        # Return:
        # * _Exception_: An error, or nil in case of success
        def execute
          if ($Variables[:DummyProduct_Calls] == nil)
            $Variables[:DummyProduct_Calls] = []
          end
          $Variables[:DummyProduct_Calls] << [ 'execute', [] ]

          return nil
        end

        # Get the default configuration
        #
        # Return:
        # * _String_: The default configuration text to put in the configuration file.
        def getDefaultConfig
          if ($Variables[:DummyProduct_Calls] == nil)
            $Variables[:DummyProduct_Calls] = []
          end
          $Variables[:DummyProduct_Calls] << [ 'getDefaultConfig', [] ]

          return "{}"
        end

      end

    end

  end

end
