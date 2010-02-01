#--
# Copyright (c) 2010 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACEInstall

  module Master

    module Adapters

      class DummyProduct

        class DummyProcessNoDefaultConf

          # Check if we can install
          #
          # Return:
          # * _Exception_: An error, or nil in case of success
          def check
            if ($Variables[:DummyProduct_DummyProcessNoDefaultConf_Calls] == nil)
              $Variables[:DummyProduct_DummyProcessNoDefaultConf_Calls] = []
            end
            $Variables[:DummyProduct_DummyProcessNoDefaultConf_Calls] << [ 'check', [] ]

            return nil
          end

          # Install for real.
          # This is called only when check method returned no error.
          #
          # Return:
          # * _Exception_: An error, or nil in case of success
          def execute
            if ($Variables[:DummyProduct_DummyProcessNoDefaultConf_Calls] == nil)
              $Variables[:DummyProduct_DummyProcessNoDefaultConf_Calls] = []
            end
            $Variables[:DummyProduct_DummyProcessNoDefaultConf_Calls] << [ 'execute', [] ]

            return nil
          end

        end

      end

    end

  end

end
