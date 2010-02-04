#--
# Copyright (c) 2010 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACEInstall

  module Slave

    module Adapters

      class Mediawiki

        include WEACE::Toolbox

        # Check if we can install
        #
        # Return:
        # * _Exception_: An error, or nil in case of success
        def check
          checkVar(:MediawikiDir, '--mediawikidir')

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
  \# Directory where MediaWiki is installed
  :MediawikiDir => '#{@MediawikiDir}'
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
          # Modify the skin to add WEACE icon if not already present
          return modifyFile(
            "#{@MediawikiDir}/includes/Skin.php",
            /function getPoweredBy\(\) \{/,
            "    $img = $img.'<a title=\"Some content of this website can be modified by some WEACE processes. Click for explanations.\" href=\"#{@ProviderEnv[:WEACESlaveInfoURL]}#Adapters.Mediawiki\"><img src=\"http://weacemethod.sourceforge.net/wiki/images/9/95/WEACESlave.png\" alt=\"Some content of this website can be modified by some WEACE processes. Click for explanations.\"/></a>'; /* WEACE Slave Insert */\n",
            /return /,
            :CheckMatch => [
              /\/\* WEACE Slave Insert \*\//
            ],
            :ExtraLinesDuringMatch => true,
            :CommitModifications => iCommitModifications
          )
        end

      end

    end

  end

end
