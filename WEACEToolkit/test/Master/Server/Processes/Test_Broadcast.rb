#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  module Test

    module Master

      module Processes

        class Test_Broadcast < ::Test::Unit::TestCase
          
          include WEACE::Test::Master::Common

          # Test that getOptions return something correct
          def testGetOptions
            accessProcessPlugin do |iProcessPlugin|
              assert(!iProcessPlugin.respond_to?(:getOptions))
            end
          end

          # Test a nominal case
          def testNominal
            executeProcess([]) do |iError, iSlaveActions|
              assert_equal(
                {
                  Tools_All => {
                    Action_Test_Ping => [
                      []
                    ]
                  }
                },
                iSlaveActions
              )
            end
          end

        end

      end

    end

  end

end
