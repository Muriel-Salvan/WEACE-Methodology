# Usage: This file is used by other files.
# Do not call it directly.
#
# Check http://weacemethod.sourceforge.net for details.
#--
# Copyright (c) 2009 - 2011 Muriel Salvan  (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

module WEACE

  module Test

    module Install

      module Slave

        module Adapters

          class Mediawiki < ::Test::Unit::TestCase

            class Wiki < ::Test::Unit::TestCase

              class Ping < ::Test::Unit::TestCase

                include WEACE::Test::Install::Slave::SlaveAction

                # Get the specificities of this test suite to be used by SlaveAction module.
                # Here are the different properties to give:
                # * :InstallSlaveActionParameters (<em>list<String></em>): The parameters to give WEACEInstall. Only the Slave Action's specific ones.
                # * :InstallSlaveActionParametersShort (<em>list<String></em>): The parameters to give WEACEInstall in short version. Only the Slave Action's specific ones.
                # * :Repository (_String_): Repository name to be used when installing this Slave Action.
                # * :SlaveActionInstallInfo (<em>map<Symbol,Object></em>): The install info the SlaveAction should register (without :InstallationDate, :InstallationParameters).
                # * :SlaveActionConfigInfo (<em>map<Symbol,Object></em>): The config info the SlaveProduct should register.
                # * :ProductRepositoryVirgin (_String_): Name of the Product repository to use when this SlaveProduct is not installed.
                # * :ProductRepositoryInstalled (_String_): Name of the Product repository to use when this SlaveProduct is installed.
                # * :ProductRepositoryInvalid (_String_): Name of the Product repository to use when this SlaveProduct cannot be installed [optional = nil].
                # * :CheckErrorClass (_class_): Class of the Check error thrown when installing on :ProductRepositoryInvalid [optional = nil]
                #
                # Return:
                # * <em>map<Symbol,Object></em>: The different properties
                def getSlaveActionTestSpecs
                  return {
                    :InstallSlaveActionParameters => [],
                    :InstallSlaveActionParametersShort => [],
                    :Repository => 'SlaveMediawikiWikiInstalled',
                    :SlaveActionInstallInfo => {
                      :Description => 'Ping Mediawiki as a Wiki. This is used by Testers.',
                      :Author => 'murielsalvan@users.sourceforge.net'
                    },
                    :SlaveProductConfigInfo => {},
                    :ProductRepositoryVirgin => 'Empty',
                    :ProductRepositoryInstalled => 'Empty'
                  }
                end

              end

            end

          end

        end

      end

    end

  end

end
