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
    
      class SourceForge
    
        # Get the environment specifics to this provider type.
        # Please check http://weacemethod.sourceforge.net to know every possible value.
        #
        # Return::
        # * <em>map<Symbol,Object></em>: The map of options
        def getProviderEnvironment
          lProjectDir = "/home/groups/#{@ProjectUnixName[0..0]}/#{@ProjectUnixName[0..1]}/#{@ProjectUnixName}"

          return {
            :CGI => {
              :InternalDirectory => "#{lProjectDir}/cgi-bin",
              :URL => "http://#{@ProjectUnixName}.sourceforge.net/cgi-bin"
            },
            :Shell => {
              :InternalDirectory => "#{lProjectDir}/WEACETools/Slave"
            },
            :PersistentDir => "#{lProjectDir}/persistent/WEACE"
          }
        end

      end
      
    end
    
  end

end

