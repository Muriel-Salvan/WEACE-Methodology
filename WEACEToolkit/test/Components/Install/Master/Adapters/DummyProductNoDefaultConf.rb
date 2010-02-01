#--
# Copyright (c) 2010 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACEInstall

  module Master

    module Adapters

      class DummyProductNoDefaultConf

        # Check if we can install
        #
        # Return:
        # * _Exception_: An error, or nil in case of success
        def check
          if ($Variables[:DummyProductNoDefaultConf_Calls] == nil)
            $Variables[:DummyProductNoDefaultConf_Calls] = []
          end
          $Variables[:DummyProductNoDefaultConf_Calls] << [ 'check', [] ]

          return nil
        end

        # Install for real.
        # This is called only when check method returned no error.
        #
        # Return:
        # * _Exception_: An error, or nil in case of success
        def execute
          if ($Variables[:DummyProductNoDefaultConf_Calls] == nil)
            $Variables[:DummyProductNoDefaultConf_Calls] = []
          end
          $Variables[:DummyProductNoDefaultConf_Calls] << [ 'execute', [] ]

          return nil
        end

      end

    end

  end

end
