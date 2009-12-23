#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  module Slave

    module Adapters

      module DummyProduct

        module DummyTool

          class DummyError < RuntimeError
          end

          class DummyActionError

            # Execute the DummyAction
            #
            # Parameters:
            # * *iUserID* (_String_): User ID of the script adding this info
            # Return:
            # * _Exception_: An error, or nil in case of success
            def execute(iUserID)
              $Variables[:DummyActionError_User] = iUserID

              return DummyError.new('DummyError')
            end

          end

        end

      end

    end

  end

end