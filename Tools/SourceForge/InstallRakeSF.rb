# Usage:
# ruby -w InstallRakeSF.rb <RakeTarBall> <ProjectUnixName> <RakeBinSubPath> <RakeLibSubPath> [ -dryrun ]
#   -dryrun: Print commands, without executing them.
# Example: ruby -w InstallRakeSF.rb rake-0.8.4.tgz myproject rake/bin rake/lib
#
# Check http://weacemethod.sourceforge.net/wiki/index.php/RakeSF.NET for details.
#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

require 'fileutils'

module RakeInstaller

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
  
  # The main method
  #
  # Parameters:
  # * *iRakeTarBall* (_String_): Name of the tarball
  # * *iProjectUnixName* (_String_): Unix name of the project to install to
  # * *iRakeBinSubPath* (_String_): Sub-path to install Rake's binary
  # * *iRakeLibSubPath* (_String_): Sub-path to install Rake's library
  # Return:
  # * _String_: The Rake binary directory
  # * _String_: The Rake library directory
  def self.installRake(iRakeTarBall, iProjectUnixName, iRakeBinSubPath, iRakeLibSubPath)
    rCompleteRakeLibDir = nil
    rCompleteRakeBinDir = nil
    
    puts ''
    step("Install Rake from #{iRakeTarBall} for project #{iProjectUnixName} in sub-directory #{iRakeBinSubPath}, with its library in sub-directory #{iRakeLibSubPath}") do
      puts ''
      # Check basics
      lProjectRootPath = checkBasics(iRakeTarBall, iProjectUnixName)
      # Untar the tarball
      lTarBallDir = untar(iRakeTarBall, lProjectRootPath)
      # Modify the installer
      rCompleteRakeLibDir = "#{lProjectRootPath}/#{iRakeLibSubPath}"
      rCompleteRakeBinDir = "#{lProjectRootPath}/#{iRakeBinSubPath}"
      step("Modify Rake's installer #{lTarBallDir}/install.rb") do
        modifyFile("#{lTarBallDir}/install.rb", /rake_dest = File\.join/) do |iFile, iLine|
          # Modify the $sitedir and $bindir variables
          iFile << "$sitedir = '#{rCompleteRakeLibDir}'\n"
          iFile << "$bindir = '#{rCompleteRakeBinDir}'\n"
          iFile << iLine
        end
      end
      # Create the bin dir
      step("Create bin directory") do
        mkdir_p(rCompleteRakeBinDir)
      end
      # Install Rake
      step('Call modified Rake installer') do
        cdir(lTarBallDir) do
          execCmd('ruby install.rb')
        end
      end
      step("Remove untared directory #{lTarBallDir}") do
        rm_rf(lTarBallDir)
      end
    end
    puts '# Don\'t forget to set the following when using Rake:'
    puts "#  * export PATH=$PATH:#{rCompleteRakeBinDir}"
    puts "#  * export RUBYLIB=$RUBYLIB:#{rCompleteRakeLibDir}"
    
    return rCompleteRakeBinDir, rCompleteRakeLibDir
  end

end

# If we were invoked directly
if (__FILE__ == $0)
  # Parse command line arguments, check them, and call the main function
  lRakeTarBall, lProjectUnixName, lRakeBinSubPath, lRakeLibSubPath = ARGV[0..3]
  $DryRunOption = nil
  $StepDepth = 1
  if (ARGV.size > 4)
    if (ARGV[4] == '-dryrun')
      $DryRunOption = true
    end
  else
    $DryRunOption = false
  end
  if ((lRakeTarBall == nil) or
      (lProjectUnixName == nil) or
      (lRakeBinSubPath == nil) or
      (lRakeLibSubPath == nil) or
      ($DryRunOption == nil))
    # Print some usage
    puts 'Usage:'
    puts 'ruby -w InstallRakeSF.rb <RakeTarBall> <ProjectUnixName> <RakeBinSubPath> <RakeLibSubPath> [ -dryrun ]'
    puts '  -dryrun: Print commands, without executing them.'
    puts 'Example: ruby -w InstallRakeSF.rb rake-0.8.4.tgz myproject rake/bin rake/lib'
    puts ''
    puts 'Check http://weacemethod.sourceforge.net/wiki/index.php/RakeSF.NET for details.'
    exit 1
  else
    if ($DryRunOption)
      include FileUtils::DryRun
    else
      include FileUtils
    end
    RakeInstaller::installRake(lRakeTarBall, lProjectUnixName, lRakeBinSubPath, lRakeLibSubPath)
    exit 0
  end
end
