# Usage: This file is used by other files.
# Do not call it directly.
#
# Check http://weacemethod.sourceforge.net for details.
#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

module WEACEInstall
  
  module Master
  
    module Providers
    
      class SourceForge
    
        include WEACEInstall::Common
    
        # Get options of this installer
        #
        # Parameters:
        # * *ioDescription* (_ComponentDescription_): The component's description to fill
        def getDescription(ioDescription)
          ioDescription.Version = '0.0.1.20090414'
          ioDescription.Description = 'The SourceForge.net environment specifics for WEACE Master Server/Adapters.'
          ioDescription.Author = 'murielsalvan@users.sourceforge.net'
          ioDescription.addVarOption(:ProjectUnixName,
            '-p', '--project <ProjectUnixName>', String,
            '<ProjectUnixName>: SourceForge.net\'s project name.',
            'Example: myproject')
        end
        
        # Set the environment specifics to this provider type
        #
        # Parameters:
        # * *ioProviderConfig* (_ProviderConfig_)" The provider configuration object to populate with our specifics
        def getRuntimeWEACEMasterServerEnvironment(ioProviderConfig)
          # Check parameters first
          lProjectDir = "/home/groups/#{@ProjectUnixName[0..0]}/#{@ProjectUnixName[0..1]}/#{@ProjectUnixName}"
          ioProviderConfig.CGIDir = "#{lProjectDir}/cgi-bin"
          ioProviderConfig.CGIURL = "http://#{@ProjectUnixName}.sourceforge.net/cgi-bin"
        end
    
      end
      
    end
    
  end

end

