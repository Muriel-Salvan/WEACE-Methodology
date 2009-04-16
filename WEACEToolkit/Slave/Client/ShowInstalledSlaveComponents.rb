# Usage:
# ruby -w ShowInstalledSlaveComponents.rb
# Dumps the installed slave components in an HTML page

# Get WEACE base directory, and add it to the LOAD_PATH
lOldDir = Dir.getwd
Dir.chdir("#{File.dirname(__FILE__)}/../..")
lWEACEToolkitDir = Dir.getwd
Dir.chdir(lOldDir)
$LOAD_PATH << lWEACEToolkitDir

require 'WEACE_Common.rb'

module WEACE

  module Slave
  
    # Dump HTML content of the installed components in STDOUT
    def self.dumpInstalledSlaveComponents_HTML
      puts '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">'
      puts '<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">'
      puts '  <title>WEACE Slave Adapters installed in this provider</title>'
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
      puts '      font-size:1.2em;'
      puts '    }'
      puts '    h3 {'
      puts '      font-size:1.0em;'
      puts '    }'
      puts '    h4 {'
      puts '      font-size:0.9em;'
      puts '    }'
      puts '    p {' 
      puts '      font-size:0.8em;' 
      puts '    }' 
      puts '  </style>' 
      puts '<body>' 
      
      # Exception protected
      begin
        puts '<table align=center><tr><td><img src="http://weacemethod.sourceforge.net/wiki/images/9/95/WEACESlave.png"/></td></tr></table>'
        puts '<p><a href="http://weacemethod.sourceforge.net/wiki/index.php/WEACESlaveExplanation">More info about WEACE Slave Client</a></p>'

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

        puts '<table align=center><tr><td><img src="http://weacemethod.sourceforge.net/wiki/images/9/95/WEACESlave.png"/></td></tr></table>'

      rescue Exception
        puts "<p>Exception encountered while reading installed WEACE Slave Components configuration: #{$!}</p>"
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
  WEACE::Slave::dumpInstalledSlaveComponents_HTML
end
