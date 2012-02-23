#--
# Copyright (c) 2009 - 2012 Muriel Salvan  (muriel@x-aeon.com)
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
            # Parameters::
            # * *iUserID* (_String_): User ID of the script adding this info
            # * *iParam1* (_Object_): First parameter
            # * *iParam2* (_Object_): Second parameter
            # Return::
            # * _Exception_: An error, or nil in case of success
            def execute(iUserID, iParam1, iParam2)
              $Variables[:DummyActionWithParams_User] = iUserID
              $Variables[:DummyActionWithParams_Params] = [ iParam1, iParam2 ]

              return nil
            end

            # Log an operation in the adapted Product
            #
            # Parameters::
            # * *iUserID* (_String_): User ID initiating the log.
            # * *iProductName* (_String_): Product name to log
            # * *iProductID* (_String_): Product ID to log
            # * *iToolID* (_String_): Tool ID to log
            # * *iActionID* (_String_): Action ID to log
            # * *iError* (_Exception_): The error to log, can be nil in case of success
            # * *iParameters* (<em>list<String></em>): The parameters given to the operation
            # Return::
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