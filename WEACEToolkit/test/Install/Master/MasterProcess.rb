#--
# Copyright (c) 2010 - 2012 Muriel Salvan (muriel@x-aeon.com)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  module Test

    module Install

      module Master

        # This module is meant to be included in any test suite on MasterProcesses
        module MasterProcess

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
          # Return::
          # * <em>map<Symbol,Object></em>: The different properties
          def getIndividualComponentTestSpecs
            lSpecs = replaceObjectVars(getMasterProcessTestSpecs)
            return {
              :InstallParameters => [
                '--install', 'MasterProcess',
                '--process', @ToolID,
                '--on', 'RegProduct'
              ],
              :InstallComponentParameters => lSpecs[:InstallMasterProcessParameters],
              :InstallParametersShort => [
                '-i', 'MasterProcess',
                '-c', @ToolID,
                '-o', 'RegProduct'
              ],
              :InstallComponentParametersShort => lSpecs[:InstallMasterProcessParametersShort],
              :Repository => lSpecs[:Repository],
              :ComponentName => "RegProduct.#{@ToolID}",
              :ComponentInstallInfo => lSpecs[:MasterProcessInstallInfo],
              :ComponentConfigInfo => lSpecs[:MasterProcessConfigInfo],
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
