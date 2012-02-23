# Usage: This file is used by other files.
# Do not call it directly.
#
# Check http://weacemethod.sourceforge.net for details.
#--
# Copyright (c) 2009 - 2012 Muriel Salvan  (muriel@x-aeon.com)
# Licensed under BSD LICENSE. No warranty is provided.
#++

module WEACEInstall

  module Slave

    module Providers

      class DummySlaveProviderWithCGI

        # Get the environment specifics to this provider type.
        # Please check http://weacemethod.sourceforge.net to know every possible value.
        #
        # Return::
        # * <em>map<Symbol,Object></em>: The map of options
        def getProviderEnvironment
          return {
            :CGI => {
              :URL => 'http://myserver.com/cgi',
              :InternalDirectory => "#{@RepositoryDir}/cgi"
            }
          }
        end

      end

    end

  end

end

