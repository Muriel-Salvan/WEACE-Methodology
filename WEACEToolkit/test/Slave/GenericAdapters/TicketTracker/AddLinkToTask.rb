#--
# Copyright (c) 2010 - 2012 Muriel Salvan (muriel@x-aeon.com)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  module Test

    module Slave

      module GenericAdapters

        module TicketTracker

          # Define test cases that are common to any Product adapting TicketTracker/AddLinkToTask.
          # This module is meant to be included by any test suite of a SlaveAction testing TicketTracker/AddLinkToTask.
          module AddLinkToTask

            include WEACE::Test::Slave::GenericAdapters::Common

            # Get the arity of the execute function
            #
            # Return::
            # * _Integer_: The execute's arity
            def getExecuteArity
              return 4
            end

            # Test normal case
            def testNormal
              execTest(
                'DummyUserID',
                [ '123', '456', 'DummyTaskName' ]
              )
            end

          end

        end

      end

    end

  end

end
