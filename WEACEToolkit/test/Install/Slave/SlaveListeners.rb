#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  module Test

    module Install

      module Slave

        # Test everything related to installing Slave Listeners.
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
              :RepositoryNormal => 'SlaveClientInstalled',
              :RepositoryInstalled => 'SlaveListenerInstalled',
              :RepositoryConfigured => 'SlaveListenerConfigured'
            }
          end

        end

      end

    end

  end

end
