#--
# Copyright (c) 2009 - 2011 Muriel Salvan  (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACEInstall

  module Master

    module Adapters

      class Redmine

        include WEACE::Common
        
        # Check if we can install
        #
        # Return:
        # * _Exception_: An error, or nil in case of success
        def check
          checkVar(:RedmineDir, '--redminedir')

          return performModify(false)
        end

        # Install for real.
        # This is called only when check method returned no error.
        #
        # Return:
        # * _Exception_: An error, or nil in case of success
        def execute
          return performModify(true)
        end

        # Get the default configuration
        #
        # Return:
        # * _String_: The default configuration text to put in the configuration file.
        def getDefaultConfig
          return "
{
  \# Directory where Redmine is installed
  :RedmineDir => '#{@RedmineDir}'
}
"
        end

        private

        # Perform modifications or simulate them
        #
        # Parameters:
        # * *iCommitModifications* (_Boolean_): Do we really perform the modifications ?
        # Return:
        # * _Exception_: An error, or nil in case of success
        def performModify(iCommitModifications)
          return modifyFile("#{@RedmineDir}/app/views/layouts/base.rhtml",
            /Powered by <%= link_to Redmine/,
            "    <a title=\"Some actions on this website can trigger some WEACE processes. Click for explanations.\" href=\"#{@ProviderEnv[:WEACEMasterInfoURL]}#Redmine\"><img src=\"http://weacemethod.sourceforge.net/wiki/images/f/f0/WEACEMaster.png\" alt=\"Some actions on this website can trigger some WEACE processes. Click for explanations.\"/></a>\n",
            /<\/div>/,
            :CommitModifications => iCommitModifications)
        end

      end

    end

  end

end
