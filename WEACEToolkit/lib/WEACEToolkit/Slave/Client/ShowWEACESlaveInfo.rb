# Usage:
# ruby -w ShowWEACESlaveInfo.rb
# Dumps WEACE Slave info in an HTML page

require 'WEACEToolkit/WEACE_Common'
# Load the Platform dependent extensions
require 'rUtilAnts/Platform'
RUtilAnts::Platform::initializePlatform
require 'rUtilAnts/Misc'
RUtilAnts::Platform::initializeMisc

module WEACE

  module Slave
  
    class Dump_HTML
    
      include WEACE::Toolbox
  
      # Dump Client info
      def dumpSlaveClient_HTML
        # Get the installation info of the SlaveClient
        lSlaveClientInstallInfo = getComponentInstallInfo('SlaveClient')
        puts '<h1>WEACE Slave Client installed:</h1>'
        puts '<ul>'
        puts "  <li>Installed on #{lSlaveClientInstallInfo[:InstallationDate]}.</li>"
        # TODO: Check if version is useful
        #puts "  <li>Version: #{lDescription.Version}.</li>"
        puts "  <li>#{lSlaveClientInstallInfo[:Description]}</li>"
        puts "  <li>Author: #{lSlaveClientInstallInfo[:Author]}.</li>"
        puts '</ul>'
      end

      # Dump Adapters info
      def dumpInstalledSlaveAdapters_HTML
        # Get the list of installed Slave Products
        lInstalledSlaveProducts = getInstalledSlaveProducts
        # Get also SlaveClient configuration to know which one is active
        lSlaveClientConfigInfo = getComponentConfigInfo('SlaveClient')
        puts "<h1>#{lInstalledSlaveProducts.size} Products have been installed:</h1>"
        puts '<ul>'
        lInstalledSlaveProducts.each do |iProductName, iProductInfo|
          iProductInstallInfo, iTools = iProductInfo
          puts '  <li>Product:'
          puts "    <a name=\"Products.#{iProductName}\"><h2>#{iProductName}</h2></a>"
          puts '    <ul>'
          puts "      <li>Product type: #{iProductInstallInfo[:Product]}</li>"
          puts "      <li>Installed on #{iProductInstallInfo[:InstallationDate]}</li>"
          puts "      <li>Parameters: #{iProductInstallInfo[:InstallationParameters]}</li>"
          puts "      <li>#{iProductInstallInfo[:Description]}</li>"
          puts "      <li>Author: #{iProductInstallInfo[:Author]}</li>"
          puts '    </ul>'
          puts "    #{iTools.size} Tools for Product #{iProductName} have been installed:"
          puts '    <ul>'
          iTools.each do |iToolID, iToolInfo|
            iToolInstallInfo, iActions = iToolInfo
            puts '      <li>Tool:'
            puts "        <a name=\"Tools.#{iProductName}.#{iToolID}\"><h3>#{iProductName}.#{iToolID}</h3></a>"
            puts '        <ul>'
            puts "          <li>Installed on #{iToolInstallInfo[:InstallationDate]}</li>"
            puts "          <li>Parameters: #{iToolInstallInfo[:InstallationParameters]}</li>"
            puts "          <li>#{iToolInstallInfo[:Description]}</li>"
            puts "          <li>Author: #{iToolInstallInfo[:Author]}</li>"
            puts '        </ul>'
            puts "        #{iActions.size} Actions for Tool #{iProductName}.#{iToolID} installed:"
            puts '        <ul>'
            iActions.each do |iActionID, iActionInfo|
              iActionInstallInfo, iActive = iActionInfo
              puts '          <li>Action:'
              puts "            <a name=\"Actions.#{iProductName}.#{iToolID}.#{iActionID}\"><h4>#{iProductName}.#{iToolID}.#{iActionID}</h4></a>"
              puts '            <ul>'
              puts "              <li>Installed on #{iActionInstallInfo[:InstallationDate]}</li>"
              puts "              <li>Parameters: #{iActionInstallInfo[:InstallationParameters]}</li>"
              puts "              <li>#{iActionInstallInfo[:Description]}</li>"
              puts "              <li>Author: #{iActionInstallInfo[:Author]}.</li>"
              if ((lSlaveClientConfigInfo != nil) and
                  (lSlaveClientConfigInfo[iProductName] != nil) and
                  (lSlaveClientConfigInfo[iProductName][iToolID] != nil) and
                  (lSlaveClientConfigInfo[iProductName][iToolID].include?(iActionID)))
                puts '              <li>Active.</li>'
              else
                puts '              <li>Inactive.</li>'
              end
              puts '            </ul>'
              puts '          </li>'
            end
            puts '        </ul>'
            puts '      </li>'
          end
          puts '    </ul>'
          puts '  </li>'
        end
        puts '</ul>'
      end

      # Dump Listeners info
      def dumpInstalledSlaveListeners_HTML
        # Get the Listeners list
        lSlaveListeners = @PluginsManager.getPluginsDescriptions('Slave/Listeners')
        puts "<h1>#{lSlaveListeners.size} listeners are installed on this WEACE Slave Client:</h1>"
        puts '<ul>'
        lSlaveListeners.each do |iListenerID, iListenerInfo|
          puts '  <li>Listener:'
          puts "    <a name=\"Listeners.#{iListenerID}\"><h4>#{iListenerID}</h4></a>"
          puts '    <ul>'
          puts "      <li>Listener: #{iListenerID}.</li>"
          puts "      <li>Installed on #{iListenerInfo[:InstallationDate]}.</li>"
          puts "      <li>Parameters: #{iListenerInfo[:InstallationParameters]}</li>"
          puts "      <li>#{iListenerInfo[:Description]}</li>"
          puts "      <li>Author: #{iListenerInfo[:Author]}.</li>"
          puts '    </ul>'
          puts '  </li>'
        end
        puts '</ul>'
      end
      
      # Dump every info
      def dumpWEACESlaveInfo_HTML
        # First, get necessary variables for information to be retrieved
        setupWEACEDirs
        # Then, initialize the plugins
        setupInstallPlugins

        dumpHeader_HTML('WEACE Slave information of this provider')
        # Exception protected
        begin
          puts '<table align=center><tr><td><img src="http://weacemethod.sourceforge.net/wiki/images/9/95/WEACESlave.png"/></td></tr></table>'
          puts '<p><a href="http://weacemethod.sourceforge.net/wiki/index.php/WEACESlaveExplanation">More info about WEACE Slave Client</a></p>'
          dumpSlaveClient_HTML
          dumpInstalledSlaveAdapters_HTML
          dumpInstalledSlaveListeners_HTML
          puts '<table align=center><tr><td><img src="http://weacemethod.sourceforge.net/wiki/images/9/95/WEACESlave.png"/></td></tr></table>'
        rescue Exception
          begin
            lStrException = "Exception encountered while reading installed WEACE Slave information: #{$!}
Callstack:
#{$!.backtrace.join("\n")}
"
            require 'cgi'
            puts "<pre>#{CGI.escapeHTML(lStrException)}</pre>"
          rescue Exception
            # Handle the Exception without CGI
            puts "<p>Exception encountered while reading installed WEACE Slave information: #{$!}</p>"
            puts '<p>Callstack:</p>'
            puts '<p>'
            puts $!.backtrace.join("\n</p><p>")
            puts '</p>'
          end
        end
        dumpFooter_HTML
      end
      
    end

  end
  
end
