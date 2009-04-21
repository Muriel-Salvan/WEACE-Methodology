# Usage: This file is used by other files.
# Do not call it directly.
#
# Check http://weacemethod.sourceforge.net for details.
#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

require 'Install/Slave/Adapters/Redmine/Install_Redmine_Common.rb'

module WEACEInstall

  module Slave
  
    module Adapters
  
      module Redmine
      
        module TicketTracker
        
          class Ticket_RejectDuplicate
          
            include WEACE::Toolbox
            include WEACE::Logging
            include WEACEInstall::Slave::Adapters::Redmine::CommonInstall
          
            # Get options of this installer
            #
            # Parameters:
            # * *ioDescription* (_ComponentDescription_): The component's description to fill
            def getDescription(ioDescription)
              ioDescription.Version = '0.0.1.20090414'
              ioDescription.Description = 'This adapter creates a relation between a master and a slave tickets, and reject the slave as a duplicate of the master.'
              ioDescription.Author = 'murielsalvan@users.sourceforge.net'
              ioDescription.addVarOption(:RedmineDir,
                '-d', '--redminedir <RedmineDir>', String,
                '<RedmineDir>: Redmine\'s installation directory.',
                'Example: /home/groups/m/my/myproject/redmine')
              ioDescription.addVarOption(:RubyGemsLibDir,
                '-r', '--rubygemslib <RubyGemsPath>', String,
                '<RubyGemsPath>: Path to the directory containing rubygems.rb.',
                'Example: /home/groups/m/my/myproject/rubygems/lib')
              ioDescription.addVarOption(:GemsDir,
                '-g', '--gems <GemsPath>', String,
                '<GemsPath>: Path to the directory containing the Gems repository.',
                'Example: /home/groups/m/my/myproject/rubygems/mygems')
              ioDescription.addVarOption(:MySQLLibDir,
                '-m', '--mysql <MySQLLibPath>', String,
                '<MySQLLibPath>: Path to the directory containing the MySQL (C-Connector) library.',
                'Example: /home/groups/m/my/myproject/mysql/lib')
            end
            
            # Execute the installation
            #
            # Parameters:
            # * *iParameters* (<em>list<String></em>): Additional parameters to give the installer
            # * *iProviderEnv* (_ProviderEnv_): The Provider specific environment
            def execute(iParameters, iProviderEnv)
              # Modify common parts
              installRedmineWEACESlaveLink(iProviderEnv)
              generateDBEnv
            end
            
          end
            
        end
        
      end
      
    end
    
  end
  
end
