#--
# Copyright (c) 2009 - 2012 Muriel Salvan  (muriel@x-aeon.com)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  module Test

    module Install

      module Global

        # Test everything related to command line parsing of the WEACEInstall.rb script.
        # We don't test each option's functionnality. Just that each command line option is recognized correctly.
        class CommandLine < ::Test::Unit::TestCase
          
          include WEACE::Test::Install::Common

          # Test when no parameter has been given the installer
          def testNoParameter
            executeInstall([], :Error => WEACEInstall::CommandLineError)
          end

          # Test when an unknown parameter has been given the installer
          def testUnknownParameter
            executeInstall(['--unknown_parameter_for_test'], :Error => OptionParser::InvalidOption)
          end

          # Test displaying version
          def testVersion
            executeInstall(['--version'])
          end

          # Test displaying version (short version)
          def testVersionShort
            executeInstall(['-v'])
          end

          # Test displaying help
          def testHelp
            executeInstall(['--help'])
          end

          # Test displaying help (short version)
          def testHelpShort
            executeInstall(['-h'])
          end

          # Test debug flag
          def testDebug
            # Make sure we don't break debug
            lDebugMode = debug_activated?
            begin
              executeInstall(['--debug'])
            rescue Exception
              activate_log_debug(lDebugMode)
              raise
            end
            activate_log_debug(lDebugMode)
          end

          # Test debug flag (short version)
          def testDebugShort
            # Make sure we don't break debug
            lDebugMode = debug_activated?
            begin
              executeInstall(['-d'])
            rescue Exception
              activate_log_debug(lDebugMode)
              raise
            end
            activate_log_debug(lDebugMode)
          end

          # Test list flag
          def testList
            executeInstall(['--list'])
          end

          # Test list flag (short version)
          def testListShort
            executeInstall(['-l'])
          end

          # Test detailed list flag
          def testDetailedList
            executeInstall(['--detailedlist'])
          end

          # Test detailed list flag (short version)
          def testDetailedListShort
            executeInstall(['-e'])
          end

          # Test install a component with a missing component name
          def testInstallMissingComponent
            executeInstall(['--install'], :Error => OptionParser::MissingArgument)
          end

          # Test install a component with a missing component name (short version)
          def testInstallMissingComponentShort
            executeInstall(['-i'], :Error => OptionParser::MissingArgument)
          end

          # Test install an unknown component
          def testInstallUnknownComponent
            executeInstall(['--install','UnknownComponentNameForTest'], :Error => WEACEInstall::Installer::UnknownComponentError)
          end

          # Test install an unknown component with force option
          def testInstallUnknownComponentWithForce
            executeInstall(['--install','UnknownComponentNameForTest','--force'], :Error => WEACEInstall::Installer::UnknownComponentError)
          end

          # Test install an unknown component with force option (short version)
          def testInstallUnknownComponentWithForceShort
            executeInstall(['--install','UnknownComponentNameForTest','-f'], :Error => WEACEInstall::Installer::UnknownComponentError)
          end

        end

      end

    end

  end

end
