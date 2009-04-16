# Usage:
# ruby -w ShowWEACESlaveInfo.rb
# Dumps WEACE Slave info in an HTML page

# Get WEACE base directory, and add it to the LOAD_PATH
lOldDir = Dir.getwd
Dir.chdir("#{File.dirname(__FILE__)}/../..")
lWEACEToolkitDir = Dir.getwd
Dir.chdir(lOldDir)
$LOAD_PATH << lWEACEToolkitDir

require 'WEACE_Common.rb'

module WEACE

  module Slave
  
    class Dump_HTML
    
      include WEACE::Toolbox
  
      # Dump Adapters info
      def dumpInstalledSlaveAdapters_HTML
        # Require the file registering WEACE Slave Components
        require 'Slave/Client/InstalledWEACESlaveComponents.rb'
        # Get the Adapters list
        lInstalledAdapters = WEACE::Slave::getInstalledAdapters
        puts "<h1>#{lInstalledAdapters.size} products have installed WEACE Slave Adapters:</h1>"
        puts '<ul>'
        lIdxProduct = 0
        lInstalledAdapters.each do |iProductID, iAdaptersForProduct|
          puts "  <li>Product n.#{lIdxProduct}:"
          puts "    <a name=\"Adapters.#{iProductID}\"><h2>#{iProductID}</h2></a>"
          puts "    #{iAdaptersForProduct.size} tools of this product have some adapters:"
          puts '    <ul>'
          lIdxTool = 0
          iAdaptersForProduct.each do |iToolID, iAdaptersForTool|
            puts "      <li>Tool n.#{lIdxProduct}.#{lIdxTool}:"
            puts "        <a name=\"Adapters.#{iProductID}.#{iToolID}\"><h3>#{iProductID}.#{iToolID}</h3></a>"
            puts "        #{iAdaptersForTool.size} Slave Adapters installed:"
            puts '        <ul>'
            lIdxAdapter = 0
            iAdaptersForTool.each do |iScriptID, iDescription|
              puts "          <li>Adapter n.#{lIdxProduct}.#{lIdxTool}.#{lIdxAdapter}:"
              puts "            <a name=\"Adapters.#{iProductID}.#{iToolID}.#{iScriptID}\"><h4>#{iProductID}.#{iToolID}.#{iScriptID}</h4></a>"
              puts '            <ul>'
              puts "              <li>Script: #{iScriptID}.</li>"
              puts "              <li>Installed on #{iDescription.Date}.</li>"
              puts "              <li>Version: #{iDescription.Version}.</li>"
              puts "              <li>#{iDescription.Description}</li>"
              puts "              <li>Author: #{iDescription.Author}.</li>"
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
        
      # Dump Listeners info
      def dumpInstalledSlaveListeners_HTML
        # Require the file registering WEACE Slave Components
        require 'Slave/Client/InstalledWEACESlaveComponents.rb'
        # Get the Listeners list
        lInstalledListeners = WEACE::Slave::getInstalledListeners
        puts "<h1>#{lInstalledListeners.size} listeners are installed on this WEACE Slave Client:</h1>"
        puts '<ul>'
        lIdxListener = 0
        lInstalledListeners.each do |iListenerID, iDescription|
          puts "  <li>Listener n.#{lIdxListener}:"
          puts "    <a name=\"Listeners.#{iListenerID}\"><h4>#{iListenerID}</h4></a>"
          puts '    <ul>'
          puts "      <li>Listener: #{iListenerID}.</li>"
          puts "      <li>Installed on #{iDescription.Date}.</li>"
          puts "      <li>Version: #{iDescription.Version}.</li>"
          puts "      <li>#{iDescription.Description}</li>"
          puts "      <li>Author: #{iDescription.Author}.</li>"
          puts '    </ul>'
          puts '  </li>'
          lIdxListener += 1
        end
        puts '</ul>'
      end
      
      # Dump every info
      def dumpWEACESlaveInfo_HTML
        dumpHeader_HTML('WEACE Slave information of this provider')
        # Exception protected
        begin
          puts '<table align=center><tr><td><img src="http://weacemethod.sourceforge.net/wiki/images/9/95/WEACESlave.png"/></td></tr></table>'
          puts '<p><a href="http://weacemethod.sourceforge.net/wiki/index.php/WEACESlaveExplanation">More info about WEACE Slave Client</a></p>'
          dumpInstalledSlaveAdapters_HTML
          dumpInstalledSlaveListeners_HTML
          puts '<table align=center><tr><td><img src="http://weacemethod.sourceforge.net/wiki/images/9/95/WEACESlave.png"/></td></tr></table>'
        rescue Exception
          puts "<p>Exception encountered while reading installed WEACE Slave information: #{$!}</p>"
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
  WEACE::Slave::Dump_HTML.new.dumpWEACESlaveInfo_HTML
end
