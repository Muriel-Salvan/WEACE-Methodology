#--
# Copyright (c) 2009 - 2011 Muriel Salvan  (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  module Test

    module Install

      module Master

        # Test everything related to installing Master Processes.
        # Don't test each Master Process here. Just the generic functionalities with Dummy MasterProcesses.
        class MasterProcesses < ::Test::Unit::TestCase

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
          # * :ProviderEnv (<em>map<Symbol,Object></em>): The Provider's environment that should be given the plugin
          # * :ProductConfig (<em>map<Symbol,Object></em>): The Product's configuration that should be given the plugin if applicable [optional = nil]
          # * :ToolConfig (<em>map<Symbol,Object></em>): The Tool's configuration that should be given the plugin if applicable [optional = nil]
          # * :RepositoryProductConfig (_String_): Name of the repository to use when testing Product config, if :ProductConfig is specified [optional = nil]
          # * :RepositoryToolConfig (_String_): Name of the repository to use when testing Tool config, if :ToolConfig is specified [optional = nil]
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
              :RepositoryNormal => 'Dummy/MasterProductInstalled',
              :RepositoryInstalled => 'Dummy/MasterProcessInstalled',
              :RepositoryConfigured => 'Dummy/MasterProcessConfigured',
              :ProviderEnv => {
                :WEACEExecuteCmd => '/usr/bin/ruby -w WEACEExecute.rb',
                :WEACEMasterInfoURL => 'http://weacemethod.sourceforge.net'
              },
              :ProductConfig => {
                :MasterProductConfAttr => 'MasterProductConfValue'
              },
              :RepositoryProductConfig => 'Dummy/MasterProductInstalledWithProductConfig'
            }
          end

          # Test installing a Master Process without the Master Product
          def testMasterProcessWithoutMasterProduct
            executeInstall(['--install', 'MasterProcess', '--process', 'DummyProcess', '--on', 'RegProduct'],
              :Repository => 'Dummy/MasterServerInstalled',
              :Error => WEACEInstall::Installer::MissingMasterProductError,
              :AddRegressionMasterAdapters => true
            ) do |iError|
              assert_equal(nil, $Variables[:DummyProduct_DummyProcess_Calls])
            end
          end

          # Test installing a Master Process without --process option
          def testMasterProcessWithoutProcess
            executeInstall(['--install', 'MasterProcess', '--on', 'RegProduct'],
              :Repository => 'Dummy/MasterProductInstalled',
              :AddRegressionMasterAdapters => true,
              :Error => WEACEInstall::CommandLineError
            ) do |iError|
              assert_equal(nil, $Variables[:DummyProduct_DummyProcess_Calls])
            end
          end

          # Test installing a Master Process without --process argument
          def testMasterProcessWithoutProcessArg
            executeInstall(['--install', 'MasterProcess', '--on', 'RegProduct', '--process'],
              :Repository => 'Dummy/MasterProductInstalled',
              :AddRegressionMasterAdapters => true,
              :Error => OptionParser::MissingArgument
            ) do |iError|
              assert_equal(nil, $Variables[:DummyProduct_DummyProcess_Calls])
            end
          end

          # Test installing a Master Process without --on option
          def testMasterProcessWithoutOn
            executeInstall(['--install', 'MasterProcess', '--process', 'DummyProcess'],
              :Repository => 'Dummy/MasterProductInstalled',
              :AddRegressionMasterAdapters => true,
              :Error => WEACEInstall::CommandLineError
            ) do |iError|
              assert_equal(nil, $Variables[:DummyProduct_DummyProcess_Calls])
            end
          end

          # Test installing a Master Process without --on argument
          def testMasterProcessWithoutOnArg
            executeInstall(['--install', 'MasterProcess', '--process', 'DummyProcess', '--on'],
              :Repository => 'Dummy/MasterProductInstalled',
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
