# Usage: This file is used by other files.
# Do not call it directly.
#
# Check http://weacemethod.sourceforge.net for details.
#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

module WEACE

  module Test

    module Slave

      module Adapters

        module Redmine

          module TicketTracker

            class RejectDuplicate < ::Test::Unit::TestCase

              include WEACE::Test::Slave::Common

              # Test normal behaviour
              def testNormal
#                executeSlave(
#                  [
#                    '--user', 'DummyUser',
#                    '--tool', 'Redmine',
#                    '--action', 'RejectDuplicate'
#                  ],
#                  :Repository => 'DummyActionAvailable'
#                ) do |iError|
#
#                end
              end

            end

          end

        end

      end

    end

  end

end
