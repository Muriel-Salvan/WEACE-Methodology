# To change this template, choose Tools | Templates
# and open the template in the editor.

require 'test/unit' 

# Get WEACE base directory (in absolute form), and add it to the LOAD_PATH
lOldDir = Dir.getwd
Dir.chdir(File.dirname(__FILE__))
$WEACEToolkitDir = Dir.getwd
Dir.chdir(lOldDir)
$LOAD_PATH << $WEACEToolkitDir

module WEACEInstall

  # This class creates other classes for test cases
  class TestCreator

    # Create classes
    def createClasses
      # Parse all test cases, and create classes/methods for each one of them

    end

  end

end

WEACEInstall::TestCreator.new.createClasses
