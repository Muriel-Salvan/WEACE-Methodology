#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  module Slave

    module Adapters

      module DummyProduct

        module DummyTool

          class DummyAction

            # Execute the DummyAction
            #
            # Parameters:
            # * *iUserID* (_String_): User ID of the script adding this info
            # Return:
            # * _Exception_: An error, or nil in case of success
            def execute(iUserID)
              $Variables[:DummyAction_User] = iUserID
              $Variables[:DummyAction_ProductConfig] = @ProductConfig
              $Variables[:DummyAction_ToolConfig] = @ToolConfig
              $Variables[:DummyAction_ActionConfig] = @ActionConfig

              return nil
            end

          end

        end

      end

    end

  end

end