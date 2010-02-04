#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  module Test

    module Install

      module Slave

        # Test everything related to installing Slave Listeners.
        # Don't test each Slave Listener here. Just the generic functionalities with Dummy MasterProcesses.
        class SlaveListeners < ::Test::Unit::TestCase

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
              :InstallParameters => [ '--install', 'SlaveListener', '--listener', 'DummyListener' ],
              :InstallParametersShort => [ '-i', 'SlaveListener', '-n', 'DummyListener' ],
              :ComponentName => 'DummyListener',
              :ComponentInstallInfo => {
                :Description => 'This listener is used for regression purposes only.',
                :Author => 'murielsalvan@users.sourceforge.net'
              },
              :RepositoryNormal => 'Dummy/SlaveClientInstalled',
              :RepositoryInstalled => 'Dummy/SlaveListenerInstalled',
              :RepositoryConfigured => 'Dummy/SlaveListenerConfigured',
              :ProviderEnv => {
                :WEACESlaveInfoURL => 'http://weacemethod.sourceforge.net'
              }
            }
          end

          # Test installing a Slave Listener without --listener option
          def testSlaveListenerWithoutListener
            executeInstall(['--install', 'SlaveListener'],
              :Repository => 'Dummy/SlaveClientInstalled',
              :AddRegressionSlaveListeners => true,
              :Error => WEACEInstall::CommandLineError
            ) do |iError|
              assert_equal(nil, $Variables[:ComponentInstall])
            end
          end

          # Test installing a Slave Listener without --listener argument
          def testSlaveListenerWithoutListenerArg
            executeInstall(['--install', 'SlaveListener', '--listener'],
              :Repository => 'Dummy/SlaveClientInstalled',
              :AddRegressionSlaveAdapters => true,
              :Error => OptionParser::MissingArgument
            ) do |iError|
              assert_equal(nil, $Variables[:ComponentInstall])
            end
          end

        end

      end

    end

  end

end
