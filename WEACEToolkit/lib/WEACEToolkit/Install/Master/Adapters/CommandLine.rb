#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACEInstall

  module Master

    module Adapters

      class CommandLine

        include WEACE::Toolbox
        
        # Check if we can install
        #
        # Return:
        # * _Exception_: An error, or nil in case of success
        def check
          checkVar(:InstallDir, '--installdir')

          return nil
        end

        # Install for real.
        # This is called only when check method returned no error.
        #
        # Return:
        # * _Exception_: An error, or nil in case of success
        def execute
          # Create the directory if it does not exist
          require 'fileutils'
          FileUtils::mkdir_p(@InstallDir)

          return nil
        end

        # Get the default configuration
        #
        # Return:
        # * _String_: The default configuration text to put in the configuration file.
        def getDefaultConfig
          return "
{
  \# Directory where Tools are installed
  :InstallDir => '#{@InstallDir}'
}
"
        end

      end

    end

  end

end
