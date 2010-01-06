#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  module Test

    module Master

      module Senders

        class Local < ::Test::Unit::TestCase

          include WEACE::Test::Master::Common

          # Test a normal run without any action to execute
          def testTest
            executeSender(
              'DummyUser',
              {},
              :DummySlaveClient => true
            ) do |iError|
              assert($Variables[:SlaveActions] != nil)
              assert_equal('DummyUser', $Variables[:SlaveActions][:UserID])
              lActions = $Variables[:SlaveActions][:ActionsToExecute]
              assert_equal({}, lActions)
            end
          end

        end

      end

    end

  end

end
