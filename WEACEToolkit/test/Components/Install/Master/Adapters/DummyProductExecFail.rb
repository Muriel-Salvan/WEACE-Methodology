#--
# Copyright (c) 2010 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACEInstall

  module Master

    module Adapters

      class DummyProductExecFail

        # Error thrown by check
        class ExecError < RuntimeError
        end

        # Check if we can install
        #
        # Return:
        # * _Exception_: An error, or nil in case of success
        def check
          if ($Variables[:DummyProductExecFail_Calls] == nil)
            $Variables[:DummyProductExecFail_Calls] = []
          end
          $Variables[:DummyProductExecFail_Calls] << [ 'check', [] ]

          return nil
        end

        # Install for real.
        # This is called only when check method returned no error.
        #
        # Return:
        # * _Exception_: An error, or nil in case of success
        def execute
          if ($Variables[:DummyProductExecFail_Calls] == nil)
            $Variables[:DummyProductExecFail_Calls] = []
          end
          $Variables[:DummyProductExecFail_Calls] << [ 'execute', [] ]

          return ExecError.new('Error during execute')
        end

        # Get the default configuration
        #
        # Return:
        # * _String_: The default configuration text to put in the configuration file.
        def getDefaultConfig
          if ($Variables[:DummyProductExecFail_Calls] == nil)
            $Variables[:DummyProductExecFail_Calls] = []
          end
          $Variables[:DummyProductExecFail_Calls] << [ 'getDefaultConfig', [] ]

          return "{}"
        end

      end

    end

  end

end
