#--
# Copyright (c) 2010 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  module Test

    module Install

      module Slave

        module Adapters

          class Redmine < ::Test::Unit::TestCase

            class TicketTracker < ::Test::Unit::TestCase

              include WEACE::Test::Install::Slave::SlaveTool

              # Get the specificities of this test suite to be used by SlaveTool module.
              # Here are the different properties to give:
              # * :InstallSlaveToolParameters (<em>list<String></em>): The parameters to give WEACEInstall. Only the Slave Tool's specific ones.
              # * :InstallSlaveToolParametersShort (<em>list<String></em>): The parameters to give WEACEInstall in short version. Only the Slave Tool's specific ones.
              # * :Repository (_String_): Repository name to be used when installing this Slave Tool.
              # * :SlaveToolInstallInfo (<em>map<Symbol,Object></em>): The install info the SlaveTool should register (without :InstallationDate, :InstallationParameters).
              # * :SlaveToolConfigInfo (<em>map<Symbol,Object></em>): The config info the SlaveProduct should register.
              # * :ProductRepositoryVirgin (_String_): Name of the Product repository to use when this SlaveProduct is not installed.
              # * :ProductRepositoryInstalled (_String_): Name of the Product repository to use when this SlaveProduct is installed.
              # * :ProductRepositoryInvalid (_String_): Name of the Product repository to use when this SlaveProduct cannot be installed [optional = nil].
              # * :CheckErrorClass (_class_): Class of the Check error thrown when installing on :ProductRepositoryInvalid [optional = nil]
              #
              # Return:
              # * <em>map<Symbol,Object></em>: The different properties
              def getSlaveToolTestSpecs
                return {
                  :InstallSlaveToolParameters => [],
                  :InstallSlaveToolParametersShort => [],
                  :Repository => 'SlaveRedmineInstalled',
                  :SlaveToolInstallInfo => {
                    :Description => 'Redmine adapted to WEACE Slave as a Ticket Tracker.',
                    :Author => 'murielsalvan@users.sourceforge.net'
                  },
                  :SlaveProductConfigInfo => {},
                  :ProductRepositoryVirgin => 'Empty',
                  :ProductRepositoryInstalled => 'Empty',
                  :CheckErrorClass => WEACE::MissingFileError
                }
              end

            end

          end

        end

      end

    end

  end

end
