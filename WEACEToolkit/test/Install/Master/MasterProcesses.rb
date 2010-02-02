#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  module Test

    module Install

      module Master

        # Test everything related to installing Master Processes.
        # Don't test each Master Product here. Just the generic functionalities with Dummy MasterProcesses.
        class MasterProcesses < ::Test::Unit::TestCase

          include WEACE::Test::Install::Common

          # Test basic Component installation workflow
          include WEACE::Test::Install::GenericComponent

          # Get the specificities of this test suite to be used by GenericComponent
          # Here are the different properties to give:
          # * :InstallParameters (<em>list<String></em>): The parameters to give WEACEInstall.
          # * :InstallParametersShort (<em>list<String></em>): The parameters to give WEACEInstall in short version.
          # * :ComponentName (_String_): Name of the Component to check once installed.
          # * :ComponentInstallInfo (<em>map<Symbol,Object></em>): The install info the Component should register (without :InstallationDate and :InstallationParameters).
          # * :RepositoryNormal (_String_): Name of the repository to use when installing this Component.
          # * :RepositoryInstalled (_String_): Name of the repository to use when this Component should already be installed.
          # * :RepositoryConfigured (_String_): Name of the repository to use when this Component should already be configured.
          #
          # Return:
          # * <em>map<Symbol,Object></em>: The different properties
          def getComponentTestSpecs
            return {
              :InstallParameters => [ '--install', 'MasterProcess', '--process', 'DummyProcess', '--on', 'RegProduct' ],
              :InstallParametersShort => [ '-i', 'MasterProcess', '-c', 'DummyProcess', '-o', 'RegProduct' ],
              :ComponentName => 'RegProduct.DummyProcess',
              :ComponentInstallInfo => {
                :Description => 'This Process is used for WEACE Regression only.',
                :Author => 'murielsalvan@users.sourceforge.net'
              },
              :RepositoryNormal => 'MasterProductInstalled',
              :RepositoryInstalled => 'MasterProcessInstalled',
              :RepositoryConfigured => 'MasterProcessConfigured'
            }
          end

          # Test installing a Master Process without the Master Product
          def testMasterProcessWithoutMasterProduct
            executeInstall(['--install', 'MasterProcess', '--process', 'DummyProcess', '--on', 'RegProduct'],
              :Repository => 'MasterServerInstalled',
              :Error => WEACEInstall::Installer::MissingMasterProductError,
              :AddRegressionMasterAdapters => true
            ) do |iError|
              assert_equal(nil, $Variables[:DummyProduct_DummyProcess_Calls])
            end
          end

          # Test installing a Master Process without --process option
          def testMasterProcessWithoutProcess
            executeInstall(['--install', 'MasterProcess', '--on', 'RegProduct'],
              :Repository => 'MasterProductInstalled',
              :AddRegressionMasterAdapters => true,
              :Error => WEACEInstall::CommandLineError
            ) do |iError|
              assert_equal(nil, $Variables[:DummyProduct_DummyProcess_Calls])
            end
          end

          # Test installing a Master Process without --process argument
          def testMasterProcessWithoutProcessArg
            executeInstall(['--install', 'MasterProcess', '--on', 'RegProduct', '--process'],
              :Repository => 'MasterProductInstalled',
              :AddRegressionMasterAdapters => true,
              :Error => OptionParser::MissingArgument
            ) do |iError|
              assert_equal(nil, $Variables[:DummyProduct_DummyProcess_Calls])
            end
          end

          # Test installing a Master Process without --on option
          def testMasterProcessWithoutOn
            executeInstall(['--install', 'MasterProcess', '--process', 'DummyProcess'],
              :Repository => 'MasterProductInstalled',
              :AddRegressionMasterAdapters => true,
              :Error => WEACEInstall::CommandLineError
            ) do |iError|
              assert_equal(nil, $Variables[:DummyProduct_DummyProcess_Calls])
            end
          end

          # Test installing a Master Process without --on argument
          def testMasterProcessWithoutOnArg
            executeInstall(['--install', 'MasterProcess', '--process', 'DummyProcess', '--on'],
              :Repository => 'MasterProductInstalled',
              :AddRegressionMasterAdapters => true,
              :Error => OptionParser::MissingArgument
            ) do |iError|
              assert_equal(nil, $Variables[:DummyProduct_DummyProcess_Calls])
            end
          end

        end

      end

    end

  end

end
