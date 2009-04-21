# To change this template, choose Tools | Templates
# and open the template in the editor.

require 'test/unit' 

# Get WEACE base directory (in absolute form), and add it to the LOAD_PATH
lOldDir = Dir.getwd
Dir.chdir("#{File.dirname(__FILE__)}/..")
$WEACEToolkitDir = Dir.getwd
Dir.chdir(lOldDir)
$LOAD_PATH << $WEACEToolkitDir

require 'Install/WEACE_InstallCommon.rb'
require 'Install/WEACE_InstallTest.rb'

module WEACEInstall

  # This class creates other classes for test cases
  class TestCreator

    include WEACE::Logging
    include WEACEInstall::Common

    # Create classes for given adapters
    #
    # Parameters:
    # * *iDirectory* (_String_): The directory in which we are looking for Adapters (Master|Slave)
    def createAdapterClasses(iDirectory)
      # Parse all test cases, and create classes/methods for each one of them
      eachAdapter(iDirectory) do |iProductID, iToolID, iScriptID|
        # Test that a test suite exists for this Adapter
        lTestFileName = "#{$WEACEToolkitDir}/Install/#{iDirectory}/Adapters/#{iProductID}/#{iToolID}/test/Test_Install_#{iScriptID}.rb"
        if (File.exists?(lTestFileName))
          # Require the test file
          begin
            log "Require test suite in #{lTestFileName}"
            require lTestFileName
          rescue Exception
            logErr "WEACE #{iDirectory} Adapter #{iProductID}.#{iToolID}.#{iScriptID} test suite (#{lTestFileName}) could not be required: #{$!}"
            logErr $!.backtrace.join("\n")
            logErr 'Ignoring this test suite.'
          end
        else
          logWarn "WEACE #{iDirectory} Adapter #{iProductID}.#{iToolID}.#{iScriptID} does not have any test suite."
        end
      end
    end

    # Create classes
    def createClasses
      createAdapterClasses('Master')
      createAdapterClasses('Slave')
    end

  end

end

$LogFile = nil
if ((ARGV.include?('--verbose')) or
    (ARGV.include?('-v')))
  $LogIO = $stdout
else
  $LogIO = nil
end
WEACEInstall::TestCreator.new.createClasses
