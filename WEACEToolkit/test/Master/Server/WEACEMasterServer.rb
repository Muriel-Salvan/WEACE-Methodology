#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  module Test

    module Master

      module Server

        class WEACEMasterServer < ::Test::Unit::TestCase

          include WEACE::Test::Master::Common

          # Test command line option listing Processes
          def testCommandLineList
            executeMaster( [ '--list' ] )
          end

          # Test command line option listing Processes (short version)
          def testCommandLineListShort
            executeMaster( [ '-l' ] )
          end

          # Test command line option listing Processes in detail
          def testCommandLineDetailedList
            executeMaster( [ '--detailedlist' ] )
          end

          # Test command line option listing Processes in detail (short version)
          def testCommandLineDetailedListShort
            executeMaster( [ '-e' ] )
          end

          # Test command line option giving help
          def testCommandLineHelp
            executeMaster( [ '--help' ] )
          end

          # Test command line option giving help (short version)
          def testCommandLineHelpShort
            executeMaster( [ '-h' ] )
          end

          # Test command line option giving version
          def testCommandLineVersion
            executeMaster( [ '--version' ] )
          end

          # Test command line option giving version (short version)
          def testCommandLineVersionShort
            executeMaster( [ '-v' ] )
          end

        end

      end

    end

  end

end
