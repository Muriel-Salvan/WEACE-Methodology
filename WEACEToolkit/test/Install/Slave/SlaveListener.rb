# Usage: This file is used by other files.
# Do not call it directly.
#
# Check http://weacemethod.sourceforge.net for details.
#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

module WEACE

  # This module contains every tool needed for test cases
  module Test

    module Install

      module Slave

        # Module meant to be included in every test suite testing an individual Slave Listener.
        module SlaveListener

          include WEACE::Test::Install::IndividualComponent

          # Get the specificities of this test suite to be used by IndividualComponent
          # Here are the different properties to give:
          # * :InstallParameters (<em>list<String></em>): The parameters to give WEACEInstall.
          # * :InstallComponentParameters (<em>list<String></em>): The parameters to give WEACEInstall specific to the Component.
          # * :InstallParametersShort (<em>list<String></em>): The parameters to give WEACEInstall in short version.
          # * :InstallComponentParametersShort (<em>list<String></em>): The parameters to give WEACEInstall specific to the Component in short version.
          # * :ComponentName (_String_): Name of the Component to check
          # * :ComponentInstallInfo (<em>map<Symbol,Object></em>): The install info the Component should register (without :InstallationDate and :InstallationParameters).
          # * :ComponentConfigInfo (<em>map<Symbol,Object></em>): The config info the Component should register.
          # * :Repository (_String_): Name of the repository to use when installing this Component.
          # * :ProductRepositoryVirgin (_String_): Name of the Product repository to use when this Component is not installed.
          # * :ProductRepositoryInstalled (_String_): Name of the Product repository to use when this Component is installed.
          # * :ProductRepositoryInvalid (_String_): Name of the Product repository to use when this Component cannot be installed [optional = nil].
          # * :CheckErrorClass (_class_): Class of the Check error thrown when installing on :ProductRepositoryInvalid [optional = nil]
          #
          # Return:
          # * <em>map<Symbol,Object></em>: The different properties
          def getIndividualComponentTestSpecs
            lSpecs = replaceObjectVars(getSlaveListenerTestSpecs)
            lRepository = lSpecs[:Repository]
            if (lRepository == nil)
              lRepository = 'Dummy/SlaveClientInstalled'
            end
            return {
              :InstallParameters => [
                '--install', 'SlaveListener',
                '--listener', @ProductID
              ],
              :InstallComponentParameters => lSpecs[:InstallSlaveListenerParameters],
              :InstallParametersShort => [
                '-i', 'SlaveListener',
                '-n', @ProductID
              ],
              :InstallComponentParametersShort => lSpecs[:InstallSlaveListenerParametersShort],
              :Repository => lRepository,
              :ComponentName => @ProductID,
              :ComponentInstallInfo => lSpecs[:SlaveListenerInstallInfo],
              :ComponentConfigInfo => lSpecs[:SlaveListenerConfigInfo],
              :ProductRepositoryVirgin => lSpecs[:ProductRepositoryVirgin],
              :ProductRepositoryInstalled => lSpecs[:ProductRepositoryInstalled],
              :ProductRepositoryInvalid => lSpecs[:ProductRepositoryInvalid],
              :CheckErrorClass => lSpecs[:CheckErrorClass]
            }
          end

        end

      end

    end

  end

end
