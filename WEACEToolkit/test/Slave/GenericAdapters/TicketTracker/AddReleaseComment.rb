#--
# Copyright (c) 2010 - 2011 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  module Test

    module Slave

      module GenericAdapters

        module TicketTracker

          # Define test cases that are common to any Product adapting TicketTracker/AddReleaseComment.
          # This module is meant to be included by any test suite of a SlaveAction testing TicketTracker/AddReleaseComment.
          module AddReleaseComment

            include WEACE::Test::Slave::GenericAdapters::Common

            # Get the arity of the execute function
            #
            # Return:
            # * _Integer_: The execute's arity
            def getExecuteArity
              return 6
            end

            # Test normal case
            def testNormal
              execTest(
                'DummyUserID',
                [ '123', 'DummyBranchName', '0.0.1.20100112', 'DummyReleaseUser', 'DummyReleaseComment' ]
              )
            end

          end

        end

      end

    end

  end

end
