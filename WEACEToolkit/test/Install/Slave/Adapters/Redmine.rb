#--
# Copyright (c) 2010 - 2012 Muriel Salvan (muriel@x-aeon.com)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  module Test

    module Install

      module Slave

        module Adapters

          class Redmine < ::Test::Unit::TestCase

            include WEACE::Test::Install::Slave::SlaveProduct

            # Get the specificities of this test suite to be used by SlaveProduct module.
            # Here are the different properties to give:
            # * :InstallSlaveProductParameters (<em>list<String></em>): The parameters to give WEACEInstall. Only the Slave Product's specific ones.
            # * :InstallSlaveProductParametersShort (<em>list<String></em>): The parameters to give WEACEInstall in short version. Only the Slave Product's specific ones.
            # * :Repository (_String_): Name of the repository to use when installing this Component. [optional = 'Dummy/SlaveClientInstalled']
            # * :SlaveProductInstallInfo (<em>map<Symbol,Object></em>): The install info the SlaveProduct should register (without :InstallationDate, :InstallationParameters, :Product and :Type).
            # * :SlaveProductConfigInfo (<em>map<Symbol,Object></em>): The config info the SlaveProduct should register.
            # * :ProductRepositoryVirgin (_String_): Name of the Product repository to use when this SlaveProduct is not installed.
            # * :ProductRepositoryInstalled (_String_): Name of the Product repository to use when this SlaveProduct is installed.
            # * :ProductRepositoryInvalid (_String_): Name of the Product repository to use when this SlaveProduct cannot be installed [optional = nil].
            # * :CheckErrorClass (_class_): Class of the Check error thrown when installing on :ProductRepositoryInvalid [optional = nil]
            #
            # Return::
            # * <em>map<Symbol,Object></em>: The different properties
            def getSlaveProductTestSpecs
              return {
                :InstallSlaveProductParameters => [
                  '--redminedir', '%{ProductDir}/redmine-0.8.2',
                  '--mysql', '/usr/lib/mysql/lib',
                  '--rubymysql', '/usr/ruby-mysql'
                ],
                :InstallSlaveProductParametersShort => [
                  '-d', '%{ProductDir}/redmine-0.8.2',
                  '-m', '/usr/lib/mysql/lib',
                  '-r', '/usr/ruby-mysql'
                ],
                :SlaveProductInstallInfo => {
                  :Description => 'Redmine adapted to WEACE Slave.',
                  :Author => 'muriel@x-aeon.com'
                },
                :SlaveProductConfigInfo => {
                  :RedmineDir => '%{ProductDir}/redmine-0.8.2',
                  :RubyMySQLLibDir => '/usr/ruby-mysql',
                  :MySQLLibDir => '/usr/lib/mysql/lib',
                  :DBHost => 'mysql',
                  :DBUser => 'm12345_admin',
                  :DBPassword => 'Pass',
                  :DBName => 'm12345_redmine'
                },
                :ProductRepositoryVirgin => 'Redmine/Slave/Virgin',
                :ProductRepositoryInstalled => 'Redmine/Slave/Normal',
                :ProductRepositoryInvalid => 'Empty',
                :CheckErrorClass => WEACE::MissingFileError
              }
            end

          end

        end

      end

    end

  end

end
