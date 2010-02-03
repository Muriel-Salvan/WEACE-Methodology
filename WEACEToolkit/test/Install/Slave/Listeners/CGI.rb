#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  module Test

    module Install

      module Slave

        module Listeners

          class CGI < ::Test::Unit::TestCase

            include WEACE::Test::Install::Slave::SlaveListener

            # Get the specificities of this test suite to be used by SlaveListener module.
            # Here are the different properties to give:
            # * :InstallSlaveListenerParameters (<em>list<String></em>): The parameters to give WEACEInstall. Only the Slave Listener's specific ones.
            # * :InstallSlaveListenerParametersShort (<em>list<String></em>): The parameters to give WEACEInstall in short version. Only the Slave Listener's specific ones.
            # * :Repository (_String_): The repository to be used for these installations. [optional = 'Dummy/SlaveClientInstalled']
            # * :SlaveListenerInstallInfo (<em>map<Symbol,Object></em>): The install info the SlaveListener should register (without :InstallationDate, :InstallationParameters).
            # * :SlaveListenerConfigInfo (<em>map<Symbol,Object></em>): The config info the SlaveListener should register.
            # * :ProductRepositoryVirgin (_String_): Name of the Product repository to use when this SlaveListener is not installed.
            # * :ProductRepositoryInstalled (_String_): Name of the Product repository to use when this SlaveListener is installed.
            # * :ProductRepositoryInvalid (_String_): Name of the Product repository to use when this SlaveListener cannot be installed [optional = nil].
            # * :CheckErrorClass (_class_): Class of the Check error thrown when installing on :ProductRepositoryInvalid [optional = nil]
            #
            # Return:
            # * <em>map<Symbol,Object></em>: The different properties
            def getSlaveListenerTestSpecs
              return {
                :InstallSlaveListenerParameters => [],
                :InstallSlaveListenerParametersShort => [],
                :Repository => 'Dummy/SlaveClientInstalledWithCGI',
                :SlaveListenerInstallInfo => {
                  :Description => 'This listener creates a CGI script that routes actions to the WEACE Slave Client.',
                  :Author => 'murielsalvan@users.sourceforge.net'
                },
                :SlaveListenerConfigInfo => {},
                :ProductRepositoryVirgin => 'Empty',
                :ProductRepositoryInstalled => 'SlaveCGIListenerInstalled',
                :CheckErrorClass => WEACE::MissingFileError
              }
            end

          end

        end

      end

    end

  end

end
