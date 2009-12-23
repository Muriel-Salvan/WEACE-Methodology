#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  module Slave

    module Adapters

      module DummyProduct

        module DummyTool4

          class DummyAction4

            # Execute the DummyAction
            #
            # Parameters:
            # * *iUserID* (_String_): User ID of the script adding this info
            # Return:
            # * _Exception_: An error, or nil in case of success
            def execute(iUserID)
              $Variables[:DummyAction4_User] = iUserID
              $Variables[:DummyAction4_DummyProduct] = true

              return nil
            end

          end

        end

      end

    end

  end

end