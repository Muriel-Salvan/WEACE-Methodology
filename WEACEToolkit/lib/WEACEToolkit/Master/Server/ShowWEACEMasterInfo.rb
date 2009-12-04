# Usage:
# ruby -w ShowWEACEMasterInfo.rb
# Dumps WEACE Master info in an HTML page

# Get WEACE base directory, and add it to the LOAD_PATH
lOldDir = Dir.getwd
Dir.chdir("#{File.dirname(__FILE__)}/../..")
lWEACEToolkitDir = Dir.getwd
Dir.chdir(lOldDir)
$LOAD_PATH << lWEACEToolkitDir

require 'WEACE_Common.rb'

module WEACE

  module Master
  
    class Dump_HTML
    
      include WEACE::Toolbox
  
       Dump Server info
      def dumpMasterServer_HTML
         Require the file containing WEACE Master Info
        require 'Master/Server/InstalledWEACEMasterComponents.rb'
         Get the info
        lDescription = WEACE::Master::getInstallationDescription
        puts '<h1>WEACE Master Server installed:</h1>'
        puts '<ul>'
        puts "  <li>Installed on #{lDescription.Date}.</li>"
        puts "  <li>Version: #{lDescription.Version}.</li>"
        puts "  <li>#{lDescription.Description}</li>"
        puts "  <li>Author: #{lDescription.Author}.</li>"
        puts '</ul>'
      end

      # Dump Adapters info
      def dumpInstalledMasterAdapters_HTML
        # Require the file registering WEACE Master Adapters
        require 'Master/Server/InstalledWEACEMasterComponents.rb'
        # Get the list
        lInstalledAdapters = WEACE::Master::getInstalledAdapters
        puts "<h1>#{lInstalledAdapters.size} products have installed WEACE Master Adapters:</h1>"
        puts '<ul>'
        lIdxProduct = 0
        lInstalledAdapters.each do |iProductID, iAdaptersForProduct|
          puts "  <li>Product n.#{lIdxProduct}:"
          puts "    <a name=\"#{iProductID}\"><h2>#{iProductID}</h2></a>"
          puts "    #{iAdaptersForProduct.size} tools of this product have some adapters:"
          puts '    <ul>'
          lIdxTool = 0
          iAdaptersForProduct.each do |iToolID, iAdaptersForTool|
            puts "      <li>Tool n.#{lIdxProduct}.#{lIdxTool}:"
            puts "        <a name=\"#{iProductID}.#{iToolID}\"><h3>#{iProductID}.#{iToolID}</h3></a>"
            puts "        #{iAdaptersForTool.size} Master Adapters installed:"
            puts '        <ul>'
            lIdxAdapter = 0
            iAdaptersForTool.each do |iScriptID, iDescription|
              puts "          <li>Adapter n.#{lIdxProduct}.#{lIdxTool}.#{lIdxAdapter}:"
              puts "            <a name=\"#{iProductID}.#{iToolID}.#{iScriptID}\"><h4>#{iProductID}.#{iToolID}.#{iScriptID}</h4></a>"
              puts '            <ul>'
              puts "              <li>Script: #{iScriptID}.</li>"
              puts "              <li>Installed on #{iDescription.Date}.</li>"
              puts "              <li>Version: #{iDescription.Version}.</li>"
              puts "              <li>#{iDescription.Description}</li>"
              puts "              <li>Author: #{iDescription.Author}.</li>"
              puts "              <li><a href=\"http://weacemethod.sourceforge.net/wiki/index.php/#{iScriptID}\">Detailed process of #{iScriptID}</a></li>"
              puts '            </ul>'
              puts '          </li>'
              lIdxAdapter += 1
            end
            puts '        </ul>'
            puts '      </li>'
            lIdxTool += 1
          end
          puts '    </ul>'
          puts '  </li>'
        end
        puts '</ul>'
      end
      
      # Dump known clients info
      def dumpKnownSlaveClients_HTML
        # Require the WEACE Master Server
        require 'Master/Server/WEACEMasterServer.rb'
        # Require the WEACE Master Server configuration
        require 'Master/Server/config/Config.rb'
        # Get config
        lConfig = WEACE::Master::Config.new
        WEACE::Master::getWEACEMasterServerConfig(lConfig)
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
      end
      
      # Dump every info
      def dumpWEACEMasterInfo_HTML
        dumpHeader_HTML('WEACE Master information of this provider')
        # Exception protected
        begin
          puts '<table align=center><tr><td><img src="http://weacemethod.sourceforge.net/wiki/images/f/f0/WEACEMaster.png"/></td></tr></table>'
          puts '<p><a href="http://weacemethod.sourceforge.net/wiki/index.php/WEACEMasterExplanation">More info about WEACE Master Server</a></p>'
          dumpMasterServer_HTML
          dumpInstalledMasterAdapters_HTML
          dumpKnownSlaveClients_HTML
          puts '<table align=center><tr><td><img src="http://weacemethod.sourceforge.net/wiki/images/f/f0/WEACEMaster.png"/></td></tr></table>'
        rescue Exception
          puts "<p>Exception encountered while reading installed WEACE Master information: #{$!}</p>"
          puts '<p>Callstack:</p>'
          puts '<p>'
          puts $!.backtrace.join("\n</p><p>")
          puts '</p>'
        end
        dumpFooter_HTML
      end
      
    end
    
  end
  
end

# If we were invoked directly
if (__FILE__ == $0)
  WEACE::Master::Dump_HTML.new.dumpWEACEMasterInfo_HTML
end
