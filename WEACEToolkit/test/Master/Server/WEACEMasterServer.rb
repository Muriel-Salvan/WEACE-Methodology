#--
# Copyright (c) 2009 - 2012 Muriel Salvan  (muriel@x-aeon.com)
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

          # Test command line option activating send
          def testCommandLineSend
            executeMaster( [ '--send' ] )
          end

          # Test command line option activating send (short version)
          def testCommandLineSendShort
            executeMaster( [ '-s' ] )
          end

          # Test command line option enabling debug
          def testCommandLineDebug
            # Make sure we don't break debug
            lDebugMode = debug_activated?
            begin
              executeMaster( [ '--debug' ] )
            rescue Exception
              activate_log_debug(lDebugMode)
              raise
            end
            activate_log_debug(lDebugMode)
          end

          # Test command line option enabling debug (short version)
          def testCommandLineDebugShort
            # Make sure we don't break debug
            lDebugMode = debug_activated?
            begin
              executeMaster( [ '-d' ] )
            rescue Exception
              activate_log_debug(lDebugMode)
              raise
            end
            activate_log_debug(lDebugMode)
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
            executeMaster( [ '--process', 'DummyProcess', '--user', 'DummyUser' ], :AddRegressionProcesses => true ) do |iError|
              assert_equal([], $Variables[:ProcessParameters])
            end
          end

          # Test that Processes are called correctly with parameters
          def testProcessWithParameters
            executeMaster( [ '--process', 'DummyProcess', '--user', 'DummyUser', '--', 'Param1', 'Param2' ], :AddRegressionProcesses => true ) do |iError|
              assert_equal([ 'Param1', 'Param2' ], $Variables[:ProcessParameters])
            end
          end

        end

      end

    end

  end

end
