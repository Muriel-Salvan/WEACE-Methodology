#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  module Test

    module Slave

      module Client

        class WEACESlaveClient < ::Test::Unit::TestCase

          include WEACE::Test::Slave::Common

          # Test command line option listing Actions
          def testCommandLineList
            executeSlave( [ '--list' ] )
          end

          # Test command line option listing Actions (short version)
          def testCommandLineListShort
            executeSlave( [ '-l' ] )
          end

          # Test command line option listing Actions in detail
          def testCommandLineDetailedList
            executeSlave( [ '--detailedlist' ] )
          end

          # Test command line option listing Processes in detail (short version)
          def testCommandLineDetailedListShort
            executeSlave( [ '-e' ] )
          end

          # Test command line option giving help
          def testCommandLineHelp
            executeSlave( [ '--help' ] )
          end

          # Test command line option giving help (short version)
          def testCommandLineHelpShort
            executeSlave( [ '-h' ] )
          end

          # Test command line option giving version
          def testCommandLineVersion
            executeSlave( [ '--version' ] )
          end

          # Test command line option giving version (short version)
          def testCommandLineVersionShort
            executeSlave( [ '-v' ] )
          end

          # Test command line option enabling debug
          def testCommandLineDebug
            executeSlave( [ '--debug' ] )
          end

          # Test command line option enabling debug (short version)
          def testCommandLineDebugShort
            executeSlave( [ '-d' ] )
          end

        end

      end

    end

  end

end
