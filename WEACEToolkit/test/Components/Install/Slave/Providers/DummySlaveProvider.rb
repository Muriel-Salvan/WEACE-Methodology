# Usage: This file is used by other files.
# Do not call it directly.
#
# Check http://weacemethod.sourceforge.net for details.
#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

module WEACEInstall

  module Slave

    module Providers

      class DummySlaveProvider

        # Get the environment specifics to this provider type.
        # Please check http://weacemethod.sourceforge.net to know every possible value.
        #
        # Return:
        # * <em>map<Symbol,Object></em>: The map of options
        def getRuntimeWEACESlaveClientEnvironment
          return {}
        end

      end

    end

  end

end

