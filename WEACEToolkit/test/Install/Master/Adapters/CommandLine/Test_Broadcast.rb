# Usage: This file is used by other files.
# Do not call it directly.
#
# Check http://weacemethod.sourceforge.net for details.
#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

module WEACE

  module Test

    module Install

      module Master

        module Adapters

          class CommandLine

            class Test_Broadcast < ::Test::Unit::TestCase

              include WEACE::Test::Install::Master::MasterProcess

              # Get the specificities of this test suite to be used by MasterProcess module.
              # Here are the different properties to give:
              # * :InstallMasterProcessParameters (<em>list<String></em>): The parameters to give WEACEInstall. Only the Master Process' specific ones.
              # * :InstallMasterProcessParametersShort (<em>list<String></em>): The parameters to give WEACEInstall in short version. Only the Master Process' specific ones.
              # * :Repository (_String_): Name of WEACE repository to use for these installations.
              # * :MasterProcessInstallInfo (<em>map<Symbol,Object></em>): The install info the MasterProduct should register (without :InstallationDate, :InstallationParameters, :Product and :Type).
              # * :MasterProcessConfigInfo (<em>map<Symbol,Object></em>): The config info the MasterProduct should register.
              # * :ProductRepositoryVirgin (_String_): Name of the Product repository to use when this MasterProduct is not installed.
              # * :ProductRepositoryInstalled (_String_): Name of the Product repository to use when this MasterProduct is installed.
              # * :ProductRepositoryInvalid (_String_): Name of the Product repository to use when this MasterProduct cannot be installed [optional = nil].
              # * :CheckErrorClass (_class_): Class of the Check error thrown when installing on :ProductRepositoryInvalid [optional = nil]
              #
              # Return:
              # * <em>map<Symbol,Object></em>: The different properties
              def getMasterProcessTestSpecs
                return {
                  :InstallMasterProcessParameters => [],
                  :InstallMasterProcessParametersShort => [],
                  :Repository => 'MasterCommandLineInstalled',
                  :MasterProcessInstallInfo => {
                    :Description => 'This adapter is used to broadcast a Test Action to every one. This allows testing connections between Master and Slave Providers.',
                    :Author => 'murielsalvan@users.sourceforge.net'
                  },
                  :MasterProductConfigInfo => {},
                  :ProductRepositoryVirgin => 'CommandLine/Master/Test_Broadcast/Virgin',
                  :ProductRepositoryInstalled => 'CommandLine/Master/Test_Broadcast/Normal',
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

end
