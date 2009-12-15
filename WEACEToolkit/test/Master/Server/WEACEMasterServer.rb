#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  module Test

    module Master

      module Server

        class WEACEMasterServer < ::Test::Unit::TestCase

          # Test command line option listing Processes
          def testCommandLineList
            require 'bin/WEACEExecute'
            lError = WEACE::execute(
              [
                'MasterServer',
                '--list'
              ]
            )
            assert_equal(nil, lError)
          end

        end

      end

    end

  end

end
