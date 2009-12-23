#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  module Slave

    module Adapters

      module DummyProduct

        module DummyTool

          class DummyActionWithParams

            # Execute the DummyAction
            #
            # Parameters:
            # * *iUserID* (_String_): User ID of the script adding this info
            # * *iParam1* (_Object_): First parameter
            # * *iParam2* (_Object_): Second parameter
            # Return:
            # * _Exception_: An error, or nil in case of success
            def execute(iUserID, iParam1, iParam2)
              $Variables[:DummyActionWithParams_User] = iUserID
              $Variables[:DummyActionWithParams_Params] = [ iParam1, iParam2 ]

              return nil
            end

          end

        end

      end

    end

  end

end