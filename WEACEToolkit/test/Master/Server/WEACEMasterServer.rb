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

          # Test command line option enabling debug
          def testCommandLineDebug
            # Make sure we don't break debug
            lDebugMode = debugActivated?
            begin
              executeMaster( [ '--debug' ] )
            rescue Exception
              activateLogDebug(lDebugMode)
              raise
            end
            activateLogDebug(lDebugMode)
          end

          # Test command line option enabling debug (short version)
          def testCommandLineDebugShort
            # Make sure we don't break debug
            lDebugMode = debugActivated?
            begin
              executeMaster( [ '-d' ] )
            rescue Exception
              activateLogDebug(lDebugMode)
              raise
            end
            activateLogDebug(lDebugMode)
          end

          # Test command line option setting a Process ID and a User ID
          def testCommandLineProcess
            executeMaster( [ '--process', 'DummyProcess', '--user', 'DummyUser' ], :AddRegressionProcesses => true )
          end

          # Test command line option setting a Process ID and a User ID (short version)
          def testCommandLineProcessShort
            executeMaster( [ '-p', 'DummyProcess', '-u', 'DummyUser' ], :AddRegressionProcesses => true )
          end

          # Test command line option setting a Process ID without a User ID
          def testCommandLineProcessWithoutUser
            executeMaster( [ '--process', 'DummyProcess' ],
              :AddRegressionProcesses => true,
              :Error => WEACE::Master::Server::CommandLineError
            )
          end

          # Test that Processes are called correctly
          def testProcess
            executeMaster( [ '-p', 'DummyProcess', '-u', 'DummyUser' ], :AddRegressionProcesses => true ) do |iError|
              assert_equal([], $Variables[:ProcessParameters])
            end
          end

          # Test that Processes are called correctly with parameters
          def testProcessWithParameters
            executeMaster( [ '-p', 'DummyProcess', '-u', 'DummyUser', '--', 'Param1', 'Param2' ], :AddRegressionProcesses => true ) do |iError|
              assert_equal([ 'Param1', 'Param2' ], $Variables[:ProcessParameters])
            end
          end

        end

      end

    end

  end

end
