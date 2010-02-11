#--
# Copyright (c) 2010 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  module Test

    module Install

      module Slave

        # This module is meant to be included in any test suite on Slave Products
        module SlaveProduct

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
            lSpecs = replaceObjectVars(getSlaveProductTestSpecs)
            lRepository = lSpecs[:Repository]
            if (lRepository == nil)
              lRepository = 'Dummy/SlaveClientInstalled'
            end
            return {
              :InstallParameters => [
                '--install', 'SlaveProduct',
                '--product', @ProductID,
                '--as', 'RegProduct'
              ],
              :InstallComponentParameters => lSpecs[:InstallSlaveProductParameters],
              :InstallParametersShort => [
                '-i', 'SlaveProduct',
                '-r', @ProductID,
                '-s', 'RegProduct'
              ],
              :InstallComponentParametersShort => lSpecs[:InstallSlaveProductParametersShort],
              :Repository => lRepository,
              :ComponentName => 'RegProduct',
              :ComponentInstallInfo => lSpecs[:SlaveProductInstallInfo].merge( {
                  :Product => @ProductID,
                  :Type => 'Slave'
                } ),
              :ComponentConfigInfo => lSpecs[:SlaveProductConfigInfo],
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
