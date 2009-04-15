# Usage:
# ruby -w ShowInstalledSlaveAdapters.rb
# Dumps the installed slave adapters in an HTML page

# Get WEACE base directory, and add it to the LOAD_PATH
lOldDir = Dir.getwd
Dir.chdir("#{File.dirname(__FILE__)}/../..")
lWEACEToolkitDir = Dir.getwd
Dir.chdir(lOldDir)
$LOAD_PATH << lWEACEToolkitDir

require 'WEACE_Common.rb'

module WEACE

  module Slave
  
    # Dump HTML content of the installed adapters in STDOUT
    def self.dumpInstalledSlaveAdapters_HTML
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
        # Require the file registering WEACE Slave Adapters
        require 'Slave/Client/InstalledWEACESlaveAdapters.rb'
        
        # Get the list
        lInstalledAdapters = WEACE::Slave::getInstalledAdapters
       
        puts '<table align=center><tr><td><img src="http://weacemethod.sourceforge.net/wiki/images/9/95/WEACESlave.png"/></td></tr></table>'
        puts '<p><a href="http://weacemethod.sourceforge.net/wiki/index.php/WEACESlaveExplanation">More info about WEACE Slave Client</a></p>'
        puts "<h1>#{lInstalledAdapters.size} products have installed WEACE Slave Adapters:</h1>"
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
            puts "        #{iAdaptersForTool.size} Slave Adapters installed:"
            puts '        <ul>'
            lIdxAdapter = 0
            iAdaptersForTool.each do |iScriptID, iDescription|
              puts "          <li>Adapter n.#{lIdxProduct}.#{lIdxTool}.#{lIdxAdapter}:"
              puts "          <a name=\"#{iProductID}.#{iToolID}.#{iScriptID}\"><h4>#{iProductID}.#{iToolID}.#{iScriptID}</h4></a>"
              puts '          <ul>'
              puts "            <li>Script: #{iScriptID}.</li>"
              puts "            <li>Installed on #{iDescription.Date}.</li>"
              puts "            <li>Version: #{iDescription.Version}.</li>"
              puts "            <li>#{iDescription.Description}</li>"
              puts "            <li>Author: #{iDescription.Author}.</li>"
              puts '          </ul>'
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
        puts '<table align=center><tr><td><img src="http://weacemethod.sourceforge.net/wiki/images/9/95/WEACESlave.png"/></td></tr></table>'

      rescue Exception
        puts "<p>Exception encountered while reading installed WEACE Slave Adapters configuration: #{$!}</p>"
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
  WEACE::Slave::dumpInstalledSlaveAdapters_HTML
end
