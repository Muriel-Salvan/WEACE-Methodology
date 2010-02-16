#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  module Slave

    module Adapters

      module DummyProduct2

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
              $Variables[:DummyAction4_DummyProduct2] = true

              return nil
            end

            # Log an operation in the adapted Product
            #
            # Parameters:
            # * *iUserID* (_String_): User ID initiating the log.
            # * *iProductName* (_String_): Product name to log
            # * *iProductID* (_String_): Product ID to log
            # * *iToolID* (_String_): Tool ID to log
            # * *iActionID* (_String_): Action ID to log
            # * *iError* (_Exception_): The error to log, can be nil in case of success
            # * *iParameters* (<em>list<String></em>): The parameters given to the operation
            # Return:
            # * _Exception_: An error, or nil if success
            def logProduct(iUserID, iProductName, iProductID, iToolID, iActionID, iError, iParameters)
              return nil
            end

          end

        end

      end

    end

  end

end