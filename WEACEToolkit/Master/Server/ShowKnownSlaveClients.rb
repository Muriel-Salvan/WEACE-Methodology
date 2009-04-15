# Usage:
# ruby -w ShowKnownSlaveClients.rb
# Dumps the known clients in an HTML page

# Get WEACE base directory, and add it to the LOAD_PATH
lOldDir = Dir.getwd
Dir.chdir("#{File.dirname(__FILE__)}/../..")
lWEACEToolkitDir = Dir.getwd
Dir.chdir(lOldDir)
$LOAD_PATH << lWEACEToolkitDir

require 'WEACE_Common.rb'

module WEACE

  module Master
  
    # Dump HTML content of the slave clients in STDOUT
    def self.dumpKnownSlaveClients_HTML
      puts '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">'
      puts '<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">'
      puts '  <title>WEACE Slave Clients registered in this provider</title>'
      puts '  <style>'
      puts '    body {'
      puts '      font-family: Trebuchet MS,Georgia,"Times New Roman",serif;'
      puts '      color:#303030;'
      puts '      margin:10px;'
      puts '    }'
      puts '    h1 {'
      puts '      font-size:1.5em;'
      puts '    }'
      puts '    h2 {'
      puts '      font-size:1.0em;'
      puts '    }'
      puts '    p {' 
      puts '      font-size:0.8em;' 
      puts '    }' 
      puts '  </style>' 
      puts '<body>' 
      
      # Exception protected
      begin
        # Require the WEACE Master Server
        require 'Master/Server/WEACEMasterServer.rb'
        # Require the WEACE Master Server configuration
        require 'Master/Server/config/Config.rb'
        
        # Get config
        lConfig = WEACE::Master::Config.new
        WEACE::Master::getWEACEMasterServerConfig(lConfig)
       
        puts '<table align=center><tr><td><img src="http://weacemethod.sourceforge.net/wiki/images/f/f0/WEACEMaster.png"/></td></tr></table>'
        puts '<p><a href="http://weacemethod.sourceforge.net/wiki/index.php/WEACEMasterExplanation">More info about WEACE Master Server</a></p>'
        puts "<h1>#{lConfig.RegisteredClients.size} clients registered in this WEACE Master provider:</h1>"
        puts '<ul>'
        lIdx = 0
        lConfig.RegisteredClients.each do |iSlaveClientInfo|
          iClientType, iClientTools, iClientParameters = iSlaveClientInfo
          puts "  <li>Client n.#{lIdx}:"
          puts '    <ul>'
          puts "      <li>Type: #{iClientType}</li>"
          # Don't display parameters, as they can contain passwords
          # puts "      <li>Parameters: #{iClientParameters.inspect}</li>"
          puts "      <li>#{iClientTools.size} tools are installed on this client:"
          puts '        <ul>'
          iClientTools.each do |iToolID|
            puts "          <li>#{iToolID}</li>"
          end
          puts '        </ul>'
          puts '      </li>'
          puts '    </ul>'
          puts '  </li>'
          lIdx += 1
        end
        puts '</ul>'
        puts '<table align=center><tr><td><img src="http://weacemethod.sourceforge.net/wiki/images/f/f0/WEACEMaster.png"/></td></tr></table>'

      rescue Exception
        puts "<p>Exception encountered while reading WEACE Master Server configuration: #{$!}</p>"
        puts '<p>Callstack:</p>'
        puts '<p>'
        puts $!.backtrace.join("\n</p><p>")
        puts '</p>'
      end

      puts '</body>'
      puts '</html>'
      
    end
    
  end
  
end

# If we were invoked directly
if (__FILE__ == $0)
  WEACE::Master::dumpKnownSlaveClients_HTML
end
