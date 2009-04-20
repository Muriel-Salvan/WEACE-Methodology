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

    # Create classes
    def createClasses
      # Parse all test cases, and create classes/methods for each one of them
      eachAdapter('Master') do |iProductID, iToolID, iScriptID|
        # Test that a test suite exists for this Adapter
        lTestFileName = "#{$WEACEToolkitDir}/Install/Master/Adapters/#{iProductID}/#{iToolID}/test/Test_Install_#{iScriptID}.rb"
        if (File.exists?(lTestFileName))
          # Require the test file
          begin
            log "Require test suite in #{lTestFileName}"
            require lTestFileName
          rescue Exception
            logErr "WEACE Master Adapter #{iProductID}.#{iToolID}.#{iScriptID} test suite (#{lTestFileName}) could not be required: #{$!}"
            logErr $!.backtrace.join("\n")
            logErr 'Ignoring this test suite.'
          end
        else
          logWarn "WEACE Master Adapter #{iProductID}.#{iToolID}.#{iScriptID} does not have any test suite."
        end
      end
    end

  end

end

$LogFile = nil
WEACEInstall::TestCreator.new.createClasses
