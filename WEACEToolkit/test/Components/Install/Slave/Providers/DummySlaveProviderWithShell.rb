# Usage: This file is used by other files.
# Do not call it directly.
#
# Check http://weacemethod.sourceforge.net for details.
#--
# Copyright (c) 2009 - 2011 Muriel Salvan  (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

module WEACEInstall

  module Slave

    module Providers

      class DummySlaveProviderWithShell

        # Get the environment specifics to this provider type.
        # Please check http://weacemethod.sourceforge.net to know every possible value.
        #
        # Return:
        # * <em>map<Symbol,Object></em>: The map of options
        def getProviderEnvironment
          return {
            :Shell => {
              :InternalDirectory => @ShellDir
            }
          }
        end

      end

    end

  end

end

