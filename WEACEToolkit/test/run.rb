# To change this template, choose Tools | Templates
# and open the template in the editor.

require 'test/unit'

# This path is then used to access repositories
$WEACETestBaseDir = File.expand_path(File.dirname(__FILE__))

require 'rUtilAnts/Logging'
RUtilAnts::Logging::initializeLogging(File.expand_path("#{$WEACETestBaseDir}/.."), 'http://sourceforge.net/tracker/?group_id=254463&atid=1218055')
# If activated, the testNoParameter tests will fail as they will have the --debug flag given to them.
activateLogDebug(false)

$LOAD_PATH << File.dirname(__FILE__)

require 'Common'
require 'Install/Common'
require 'Install/Adapters'
require 'Install/Master/MasterProcess'
require 'Install/Master/MasterProduct'
require 'Install/Slave/Listeners'
require 'Install/Providers'
require 'Master/Common'
require 'Slave/Common'
require 'Slave/Adapters/Common'
(
  Dir.glob("#{File.dirname(__FILE__)}/Install/Global/**/*.rb") +
  Dir.glob("#{File.dirname(__FILE__)}/Install/Master/Server/*.rb") +
  Dir.glob("#{File.dirname(__FILE__)}/Install/Master/Providers/*.rb") +
  Dir.glob("#{File.dirname(__FILE__)}/Install/Master/Adapters/**/*.rb") +
  Dir.glob("#{File.dirname(__FILE__)}/Install/Slave/Client/*.rb") +
  Dir.glob("#{File.dirname(__FILE__)}/Install/Slave/Providers/*.rb") +
  Dir.glob("#{File.dirname(__FILE__)}/Install/Slave/Adapters/*.rb") +
  Dir.glob("#{File.dirname(__FILE__)}/Install/Slave/Adapters/*/*.rb") +
  Dir.glob("#{File.dirname(__FILE__)}/Install/Slave/Adapters/*/*/*.rb") +
  Dir.glob("#{File.dirname(__FILE__)}/Install/Slave/Listeners/*.rb") +
  Dir.glob("#{File.dirname(__FILE__)}/Master/Server/*.rb") +
  Dir.glob("#{File.dirname(__FILE__)}/Master/Server/Processes/*.rb") +
  Dir.glob("#{File.dirname(__FILE__)}/Master/Server/Senders/*.rb") +
  Dir.glob("#{File.dirname(__FILE__)}/Slave/Client/*.rb") +
  Dir.glob("#{File.dirname(__FILE__)}/Slave/Adapters/*/*/*.rb")
).each do |iFileName|
  require iFileName
end

#require 'WEACE_Common.rb'
#require 'WEACE_Test.rb'

module WEACE

  # This class creates other classes for test cases
  class TestCreator

#    include WEACE::Toolbox

    # Create classes for given adapters
    #
    # Parameters:
    # * *iDirectory* (_String_): The directory in which we are looking for Adapters (Master|Slave)
    # * *iInstallDir* (_Boolean_): Do we parse the installation directory ?
    def createAdapterClasses(iDirectory, iInstallDir)
      lRootDir = $WEACEToolkitDir
      lScriptPrefix = ''
      lAddedMessage = ''
      if (iInstallDir)
        lRootDir = "#{$WEACEToolkitDir}/Install"
        lScriptPrefix = 'Install_'
        lAddedMessage = 'installation '
      end
      # Parse all test cases, and create classes/methods for each one of them
      eachAdapter(iDirectory, iInstallDir) do |iProductID, iToolID, iScriptID|
        # Test that a test suite exists for this Adapter
        lTestFileName = "#{lRootDir}/#{iDirectory}/Adapters/#{iProductID}/#{iToolID}/test/Test_#{lScriptPrefix}#{iScriptID}.rb"
        if (File.exists?(lTestFileName))
          # Require the test file
          logDebug "Require test suite in #{lTestFileName}"
          begin
            require lTestFileName
          rescue Exception
            logErr "WEACE #{iDirectory} Adapter #{iProductID}.#{iToolID}.#{iScriptID} #{lAddedMessage}test suite (#{lTestFileName}) could not be required: #{$!}"
            logErr $!.backtrace.join("\n")
            logErr "Ignoring this #{lAddedMessage}test suite."
          end
        else
          logWarn "WEACE #{iDirectory} Adapter #{iProductID}.#{iToolID}.#{iScriptID} does not have any #{lAddedMessage}test suite."
        end
      end
    end

    # Create classes
    def createClasses
      createAdapterClasses('Master', true)
      createAdapterClasses('Slave', true)
      createAdapterClasses('Slave', false)
    end

  end

end

#WEACE::TestCreator.new.createClasses
