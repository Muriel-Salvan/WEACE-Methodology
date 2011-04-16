# Usage:
# ruby -w InstallFCGIForRubySF.rb <FCGIDevelTarBall> <ProjectUnixName> <FCGILibSubPath> [ -rubygems <RubyGemsTarBall> ] [ -dryrun ]
#   -dryrun: Print commands, without executing them.
# Example: ruby -w InstallFCGIForRubySF.rb fcgi-2.4.4.tar.gz myproject fcgi -rubygems rubygems-1.3.1.tgz
#
# Check http://weacemethod.sourceforge.net/wiki/index.php/FCGIForRubySF.NET for details.
#--
# Copyright (c) 2009 - 2011 Muriel Salvan  (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

require 'fileutils'

module FCGIForRubyInstaller

  # Those methods are copied/pasted between all scripts.
  # This is lame, but it avoids having another CommonFunctions.rb file hanging around when people just want to install 1 of the scripts (RubyGems only for example).
  # There is no naming conflicts thanks to each module's namespace.

  # Set a new step
  #
  # Parameters:
  # * *iName* (_String_): The name of the step to execute
  # * *CodeBlock*: The code of this step
  def self.step(iName)
    puts "# #{'=' * $StepDepth} #{iName} ..."
    $StepDepth += 1
    yield
    $StepDepth -= 1
    puts "# #{'=' * $StepDepth} ... OK"
    puts ''
  end

  # Execute a command, and log any possible error it finds
  #
  # Parameters:
  # * *iCmd* (_String_): The command to execute
  # * *iExpectedErrorCode* (_Integer_): The expected error code [optional = 0]
  def self.execCmd(iCmd, iExpectedErrorCode = 0)
    if ($DryRunOption)
      puts iCmd
    else
      puts "#{Dir.getwd}> #{iCmd}"
      begin
        lResult = system(iCmd)
        lErrorCode = $?
      rescue
        raise RuntimeError, "Executing command '#{iCmd}' resulted in an exception: #{$!}"
      end
      if (iExpectedErrorCode == 0)
        if (!lResult)
          raise RuntimeError, "Unable to execute command '#{iCmd}'. Returned error code: #{$?}."
        end
      elsif (lResult)
        raise RuntimeError, "Command '#{iCmd}' should have returned error code #{iExpectedErrorCode}, but in fact it succeeded."
      elsif (lErrorCode != iExpectedErrorCode)
        raise RuntimeError, "Command '#{iCmd}' returned an error code #{lErrorCode}, whereas it should have been #{iExpectedErrorCode}."
      end
    end
  end

  # Extract the file name from a tarball.
  # Remove extension .tar.gz or .tgz
  #
  # Parameters:
  # * *iTarBallName* (_String_): The tarball name
  # Return:
  # * _String_: The file name
  def self.getFileNameFromTarBall(iTarBallName)
    if (iTarBallName[-4..-1] == '.tgz')
      return iTarBallName[0..-5]
    elsif (iTarBallName[-7..-1] == '.tar.gz')
      return iTarBallName[0..-8]
    else
      raise RuntimeError, "Unable to determine tarball extension of #{iTarBallName}"
    end
  end
  
  # Basic checks.
  # * Check the existence of the tarball
  # * Check the existence of the project's directory
  #
  # Parameters:
  # * *iTarBallName* (_String_): Name of the tarball
  # * *iProjectUnixName* (_String_): Unix name of the project to install to
  # Return:
  # * _String_: The complete project's root path
  def self.checkBasics(iTarBallName, iProjectUnixName)
    rProjectRootPath = nil
    
    step('Checking existence of files and directories') do
      if (!File.exists?(iTarBallName))
        raise RuntimeError, "File #{iTarBallName} missing."
      end
      rProjectRootPath = "/home/groups/#{iProjectUnixName[0..0]}/#{iProjectUnixName[0..1]}/#{iProjectUnixName}"
      if (!File.exists?(rProjectRootPath))
        raise RuntimeError, "Directory #{rProjectRootPath} missing."
      end
    end
    
    return rProjectRootPath
  end
  
  # Execute some code once moved in a given directory, and get back to the original directory after.
  #
  # Parameters:
  # * *iDir* (_String_): The directory to move into
  # * *CodeBlock*: The code to execute
  def self.cdir(iDir)
    lOldDir = Dir.getwd
    if ($DryRunOption)
      puts "cd #{iDir}"
    else
      Dir.chdir(iDir)
    end
    yield
    if ($DryRunOption)
      puts "cd #{lOldDir}"
    else
      Dir.chdir(lOldDir)
    end
  end
  
  # Untar a tarball in a directory, and return the untared directory name
  #
  # Parameters:
  # * *iTarBallName* (_String_): Name of the tarball
  # * *iDirectory* (_String_): Name of the directory to untar into
  # Return:
  # * _String_: The complete path of the untared directory
  def self.untar(iTarBallName, iDirectory)
    rTarBallDir = "#{iDirectory}/#{getFileNameFromTarBall(iTarBallName)}"
    
    step("Untar the tarball in a temporary location (#{rTarBallDir})") do
      lOldDir = Dir.getwd
      cdir(iDirectory) do
        if (iTarBallName[0..0] == '/')
          # Absolute path
          execCmd("tar xzf #{iTarBallName}")
        else
          # Relative path
          execCmd("tar xzf #{lOldDir}/#{iTarBallName}")
        end
      end
    end
    
    return rTarBallDir
  end
  
  # Set an environment variable to a given value
  #
  # Parameters:
  # * *iVariableName* (_String_): The name of the variable
  # * *iValue* (_String_): The value
  def self.setEnv(iVariableName, iValue)
    if ($DryRunOption)
      puts "export #{iVariableName}='#{iValue}'"
    else
      ENV[iVariableName] = iValue
    end
  end
  
  # Modify a file content
  #
  # Parameters:
  # * *iFileName* (_String_): The name of the file to modify
  # * *iMatchLinePattern* (_RegExp_): The regular expression matching the line to modify
  # * *CodeBlock(iFile, ioLine)*: The code block called for the line matching the pattern
  def self.modifyFile(iFileName, iMatchLinePattern)
    if ($DryRunOption)
      puts "# !!! Modify #{iFileName} on the line matching pattern #{iMatchLinePattern.inspect}."
    else
      lFileContent = nil
      File.open(iFileName, 'r') do |iFile|
        lFileContent = iFile.readlines
      end
      lModified = false
      File.open(iFileName, 'w') do |iFile|
        lFileContent.each do |iLine|
          if (iLine.match(iMatchLinePattern) != nil)
            if (lModified)
              raise RuntimeError, "Pattern #{iMatchLinePattern.inspect} matches several lines of file #{iFileName}."
            end
            yield(iFile, iLine)
            lModified = true
          else
            iFile << iLine
          end
        end
      end
      if (!lModified)
        raise RuntimeError, "Unable to modify #{iFileName} file (pattern #{iMatchLinePattern.inspect} did not match any line of the file)."
      end
    end
  end
  
  # Test that RubyGems is up and running in our environment
  #
  # Return:
  # * _Boolean_: Is RubyGems working ?
  def self.testRubyGems
    rRubyGemsOK = true
    # First test the ruby library
    begin
      require 'rubygems'
    rescue LoadError
      puts "# !!! Requiring 'rubygems' library in Ruby ended with an exception: #{$!}"
      rRubyGemsOK = false
    end
    if (rRubyGemsOK)
      # Then test the binary in the path
      begin
        lResult = system('gem -v >/dev/null')
        lErrorCode = $?
        if (!lResult)
          puts '# !!! Unable to invoke the \'gem\' binary'
          rRubyGemsOK = false
        elsif (lErrorCode != 0)
          puts "# !!! Invoking 'gem -v' returned error code #{lErrorCode}"
          rRubyGemsOK = false
        end
      rescue
        puts "# !!! Invoking 'gem -v' ended with an exception: #{$!}"
        rRubyGemsOK = false
      end
      if (rRubyGemsOK)
        # Then test the GEM_HOME environment variable
        if (!ENV.has_key?('GEM_HOME'))
          puts '# !!! Environment variable \'GEM_HOME\' is not set'
          rRubyGemsOK = false
        else
          # Then test that the GEM_HOME directory indeed exists
          lGemHomeDir = ENV['GEM_HOME']
          if (!File.exists?(lGemHomeDir))
            puts "# !!! Environment variable 'GEM_HOME' is pointing to a missing directory: #{lGemHomeDir}"
            rRubyGemsOK = false
          end
        end
      end
    end
    
    return rRubyGemsOK
  end
  
  # Add a value to an environment variable
  #
  # Parameters:
  # * *iVariableName* (_String_): The name of the variable
  # * *iValue* (_String_): The value to add
  def self.addEnv(iVariableName, iValue)
    if (ENV[iVariableName] == nil)
      setEnv(iVariableName, iValue)
    elsif ($DryRunOption)
      puts "export #{iVariableName}=${#{iVariableName}}:#{iValue}"
    else
      ENV[iVariableName] = "#{ENV[iVariableName]}:#{iValue}"
    end
  end
  
  # Ensure that RubyGems is setup in our environment
  # 1. Checks for RubyGems
  # 2. If it is not OK:
  # 2.1. Install it by calling the corresponding script
  # 2.2. Modify the environment to set it up
  #
  # Parameters:
  # * *iRubyGemsTarBall* (_String_): The RubyGems tarball (can be nil if not given)
  # * *iProjectUnixName* (_String_): Unix name of the project to install to
  # * *iRubyGemsSubPath* (_String_): Sub-path to install RubyGems
  # * *iGemsSubPath* (_String_): Sub-path to install Gems
  def self.ensureRubyGemsEnvironment(iRubyGemsTarBall, iProjectUnixName, iRubyGemsSubPath, iGemsSubPath)
    step('Check that RubyGems is setup correctly in our environment') do
      # First test it
      if (!testRubyGems)
        # Check that we can install it
        if (iRubyGemsTarBall == nil)
          raise RuntimeError, 'RubyGems environment is not setup correctly, and no RubyGems tarball has been specified. Use \'-rubygems <RubyGemsTarBall>\' to set it up.'
        end
        begin
          require 'InstallRubyGemsSF.rb'
        rescue LoadError
          raise RuntimeError, 'Unable to require InstallRubyGemsSF.rb to install RubyGems. You have to download InstallRubyGemsSF.rb in the same place as this script to make it work. You can download it from http://weacemethod.sourceforge.net/wiki/index.php/RubyGemsSF.NET'
        end
        # Install it
        lRubyGemsBinDir, lRubyGemsLibDir, lGemsHomeDir = RubyGemsInstaller::installRubyGems(iRubyGemsTarBall, iProjectUnixName, iRubyGemsSubPath, iGemsSubPath)
        # Setup the environment
        setEnv('GEM_HOME', lGemsHomeDir)
        addEnv('PATH', lRubyGemsBinDir)
        addEnv('RUBYLIB', lRubyGemsLibDir)
        $LOAD_PATH << lRubyGemsLibDir
      end
    end
  end

  # The main method
  #
  # Parameters:
  # * *iFCGITarBall* (_String_): Name of the tarball
  # * *iProjectUnixName* (_String_): Unix name of the project to install to
  # * *iFCGILibSubPath* (_String_): Sub-path to install FCGI-devel's library
  # * *iRubyGemsTarBall* (_String_): The RubyGems tarball (can be nil if not given)
  def self.installFCGIForRuby(iFCGITarBall, iProjectUnixName, iFCGILibSubPath, iRubyGemsTarBall)
    puts ''
    step("Install FCGI For Ruby from the fcgi gem, using the FCGI-devel library from #{iFCGITarBall}, for project #{iProjectUnixName} in sub-directory #{iFCGILibSubPath}") do
      puts ''
      # Check basics
      lProjectRootPath = checkBasics(iFCGITarBall, iProjectUnixName)
      # Ensure RubyGems is setup
      ensureRubyGemsEnvironment(iRubyGemsTarBall, iProjectUnixName, "#{iFCGILibSubPath}/vendor/rubygems", "#{iFCGILibSubPath}/vendor/rubygems/mygems")
      # Untar the tarball
      lTarBallDir = untar(iFCGITarBall, lProjectRootPath)
      # Build the library
      lFCGIDevelLibDir = "#{lProjectRootPath}/#{iFCGILibSubPath}"
      step("Build FCGI-devel library in #{lFCGIDevelLibDir}") do
        cdir(lTarBallDir) do
          execCmd("./configure --prefix=#{lFCGIDevelLibDir}")
          execCmd('make')
          execCmd('make install')
        end
      end
      # First attempt to install the gem
      step('First try to install the FCGI Gem (should end with an error)') do
        execCmd('gem install fcgi', 256)
      end
      step('Create link for missing headers') do
        if ($DryRunOption)
          puts "# !!! Find the FCGI directory and link its include directory: ln -s #{lFCGIDevelLibDir}/include $GEM_HOME/gems/fcgi-*/ext/fcgi/fastcgi"
        else
          lFCGIGemDir = Dir.glob("#{ENV['GEM_HOME']}/gems/fcgi-*")[0]
          if (lFCGIGemDir == nil)
            raise RuntimeError, "Unable to find the fcgi directory in '#{ENV['GEM_HOME']}/gems/fcgi-*'"
          end
          execCmd("ln -s #{lFCGIDevelLibDir}/include #{lFCGIGemDir}/ext/fcgi/fastcgi")
        end
      end
      lFCGIDevelLibLibDir = "#{lFCGIDevelLibDir}/lib"
      step("Adding FCGI-devel library directory (#{lFCGIDevelLibLibDir}) to LIBRARY_PATH environment variable") do
        addEnv('LIBRARY_PATH', lFCGIDevelLibLibDir)
      end
      # Second attempt to install the gem
      step('Second try to install the FCGI Gem (should end with success)') do
        execCmd('gem install fcgi')
      end
      step("Remove untared directory #{lTarBallDir}") do
        rm_rf(lTarBallDir)
      end
    end
    puts '# Don\'t forget to set RubyGems environment correctly to use Ruby\'s FCGI library.'
  end

end

# If we were invoked directly
if (__FILE__ == $0)
  # Parse command line arguments, check them, and call the main function
  lFCGITarBall, lProjectUnixName, lFCGILibSubPath = ARGV[0..2]
  lRubyGemsTarBall = nil
  lInvalid = false
  $DryRunOption = false
  $StepDepth = 1
  if (ARGV.size > 3)
    # Parse remaining arguments
    lIdxARGV = 3
    while (ARGV[lIdxARGV] != nil)
      case ARGV[lIdxARGV]
      when '-dryrun'
        $DryRunOption = true
      when '-rubygems'
        lIdxARGV += 1
        lRubyGemsTarBall = ARGV[lIdxARGV]
        if (lRubyGemsTarBall == nil)
          lInvalid = true
        end
      else
        lInvalid = true
      end
      lIdxARGV += 1
    end
  end
  if ((lFCGITarBall == nil) or
      (lProjectUnixName == nil) or
      (lFCGILibSubPath == nil) or
      (lInvalid))
    # Print some usage
    puts 'Usage:'
    puts 'ruby -w InstallFCGIForRubySF.rb <FCGIDevelTarBall> <ProjectUnixName> <FCGILibSubPath> [ -rubygems <RubyGemsTarBall> ] [ -dryrun ]'
    puts '  -dryrun: Print commands, without executing them.'
    puts 'Example: ruby -w InstallFCGIForRubySF.rb fcgi-2.4.4.tar.gz myproject fcgi -rubygems rubygems-1.3.1.tgz'
    puts ''
    puts 'Check http://weacemethod.sourceforge.net/wiki/index.php/FCGIForRubySF.NET for details.'
    exit 1
  else
    if ($DryRunOption)
      include FileUtils::DryRun
    else
      include FileUtils
    end
    FCGIForRubyInstaller::installFCGIForRuby(lFCGITarBall, lProjectUnixName, lFCGILibSubPath, lRubyGemsTarBall)
    exit 0
  end
end
