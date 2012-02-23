#--
# Copyright (c) 2010 - 2012 Muriel Salvan (muriel@x-aeon.com)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACEInstall

  module Slave

    module Adapters

      class Redmine

        include WEACE::Common

        # Check if we can install
        #
        # Return::
        # * _Exception_: An error, or nil in case of success
        def check
          # TODO: Check that these checks are still relevant
          checkVar(:RedmineDir, '--redminedir')
          checkVar(:RubyMySQLLibDir, '--rubymysql')
          checkVar(:MySQLLibDir, '--mysql')

          return performModify(false)
        end

        # Install for real.
        # This is called only when check method returned no error.
        #
        # Return::
        # * _Exception_: An error, or nil in case of success
        def execute
          # TODO: Install Ruby/MySQL if the Provider does not give access to it natively.
          return performModify(true)
        end

        # Get the default configuration
        #
        # Return::
        # * _String_: The default configuration text to put in the configuration file.
        def getDefaultConfig
          return "
{
  \# Directory where Redmine is installed
  :RedmineDir => '#{@RedmineDir}',
  \# Directory containing Ruby's MySQL
  :RubyMySQLLibDir => '#{@RubyMySQLLibDir}',
  \# Directory containing MySQL C-connector library
  :MySQLLibDir => '#{@MySQLLibDir}',

  \# Database connection parameters
  :DBHost => 'mysql',
  :DBUser => 'm12345_admin',
  :DBPassword => 'Pass',
  :DBName => 'm12345_redmine'
}
"
        end

        private

        # Perform modifications or simulate them
        #
        # Parameters::
        # * *iCommitModifications* (_Boolean_): Do we really perform the modifications ?
        # Return::
        # * _Exception_: An error, or nil in case of success
        def performModify(iCommitModifications)
          return modifyFile("#{@RedmineDir}/app/views/layouts/base.rhtml",
            /Powered by <%= link_to Redmine/,
            "    <a title=\"Some content of this website can be modified by some WEACE processes. Click for explanations.\" href=\"#{@ProviderEnv[:WEACESlaveInfoURL]}#Adapters.Redmine\"><img src=\"http://weacemethod.sourceforge.net/wiki/images/9/95/WEACESlave.png\" alt=\"Some content of this website can be modified by some WEACE processes. Click for explanations.\"/></a>\n",
            /<\/div>/,
            :CommitModifications => iCommitModifications)
        end

        # TODO: Check if we keep this method. If so, adapt @RubyGemsLibDir...
        # Generate the file that sets DB environment to using MySQL inside Ruby
        def generateDBEnv
          # Generate the database environment file that will be used by the Adapter scripts
          lDBEnvFileName = "#{@RedmineDir}/DBEnv.sh"
          log_debug "Generate database environment file for Redmine (#{lDBEnvFileName}) ..."
          File.open(lDBEnvFileName, 'w') do |iFile|
            iFile << "
# This file has been generated by the installer of some Redmine's WEACE Slave Adapters.
# Do not modify it.
# It is used by some WEACE Slave Adapters scripts to get the environment necessary to access the underlying Redmine's database.

# The Ruby Gems library path
if [ -z ${RUBYLIB} ]
then
  export RUBYLIB=#{@RubyGemsLibDir}
else
  export RUBYLIB=${RUBYLIB}:#{@RubyGemsLibDir}
fi

# The Gems home
export GEM_HOME=#{@GemsDir}

# The MySQL library path
if [ -z ${LD_LIBRARY_PATH} ]
then
  export LD_LIBRARY_PATH=#{@MySQLLibDir}
else
  export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:#{@MySQLLibDir}
fi
"
          end
        end

      end

    end

  end

end
