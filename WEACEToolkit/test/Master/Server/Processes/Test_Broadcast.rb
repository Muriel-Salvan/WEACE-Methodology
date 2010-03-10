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
              lProcessOptions = iProcessPlugin.getOptions
              assert(lProcessOptions.kind_of?(OptionParser))
            end
          end
          
          # Test a nominal case
          def testNominal
            executeProcess(['--comment', 'DummyComment']) do |iError, iSlaveActions|
              assert_equal(
                {
                  Tools::All => {
                    Actions::All_Ping => [
                      [ 'DummyComment' ]
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
