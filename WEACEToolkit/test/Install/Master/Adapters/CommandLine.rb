#--
# Copyright (c) 2010 - 2011 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  module Test

    module Install

      module Master

        module Adapters

          class CommandLine < ::Test::Unit::TestCase

            include WEACE::Test::Install::Master::MasterProduct

            # Get the specificities of this test suite to be used by MasterProduct module.
            # Here are the different properties to give:
            # * :InstallMasterProductParameters (<em>list<String></em>): The parameters to give WEACEInstall. Only the Master Product's specific ones.
            # * :InstallMasterProductParametersShort (<em>list<String></em>): The parameters to give WEACEInstall in short version. Only the Master Product's specific ones.
            # * :Repository (_String_): Name of the repository to use when installing this Component. [optional = 'Dummy/MasterServerInstalled']
            # * :MasterProductInstallInfo (<em>map<Symbol,Object></em>): The install info the MasterProduct should register (without :InstallationDate, :InstallationParameters, :Product and :Type).
            # * :MasterProductConfigInfo (<em>map<Symbol,Object></em>): The config info the MasterProduct should register.
            # * :ProductRepositoryVirgin (_String_): Name of the Product repository to use when this MasterProduct is not installed.
            # * :ProductRepositoryInstalled (_String_): Name of the Product repository to use when this MasterProduct is installed.
            # * :ProductRepositoryInvalid (_String_): Name of the Product repository to use when this MasterProduct cannot be installed [optional = nil].
            # * :CheckErrorClass (_class_): Class of the Check error thrown when installing on :ProductRepositoryInvalid [optional = nil]
            #
            # Return:
            # * <em>map<Symbol,Object></em>: The different properties
            def getMasterProductTestSpecs
              return {
                :InstallMasterProductParameters => [],
                :InstallMasterProductParametersShort => [],
                :Repository => 'Dummy/MasterServerInstalledWithShell',
                :MasterProductInstallInfo => {
                  :Description => 'WEACE Master processes that are accessible from a terminal.',
                  :Author => 'murielsalvan@users.sourceforge.net'
                },
                :MasterProductConfigInfo => {},
                :ProductRepositoryVirgin => 'CommandLine/Master/Normal',
                :ProductRepositoryInstalled => 'CommandLine/Master/Normal',
                :ProductRepositoryInvalid => 'Empty',
                :CheckErrorClass => WEACE::MissingDirError
              }
            end

          end

        end

      end

    end

  end

end
