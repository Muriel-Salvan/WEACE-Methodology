# Usage:
# ruby -w InstallRubyGemsSF.rb <RubyGemsTarBall> <ProjectUnixName> <RubyGemsSubPath> <GemsSubPath> [ -dryrun ]
#   -dryrun: Print commands, without executing them.
# Example: ruby -w InstallRubyGemsSF.rb rubygems-1.3.1.tgz myproject rubygems rubygems/mygems
#
# Check http://weacemethod.sourceforge.net/wiki/index.php/RubyGemsSF.NET for details.
#--
# Copyright (c) 2009 - 2012 Muriel Salvan  (muriel@x-aeon.com)
# Licensed under BSD LICENSE. No warranty is provided.
#++

require 'fileutils'

module RubyGemsInstaller

  # Those methods are copied/pasted between all scripts.
  # This is lame, but it avoids having another CommonFunctions.rb file hanging around when people just want to install 1 of the scripts (RubyGems only for example).
  # There is no naming conflicts thanks to each module's namespace.

  # Set a new step
  #
  # Parameters::
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
  # Parameters::
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
  # Parameters::
  # * *iTarBallName* (_String_): The tarball name
  # Return::
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
  # Parameters::
  # * *iTarBallName* (_String_): Name of the tarball
  # * *iProjectUnixName* (_String_): Unix name of the project to install to
  # Return::
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
  # Parameters::
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
  # Parameters::
  # * *iTarBallName* (_String_): Name of the tarball
  # * *iDirectory* (_String_): Name of the directory to untar into
  # Return::
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
  # Parameters::
  # * *iVariableName* (_String_): The name of the variable
  # * *iValue* (_String_): The value
  def self.setEnv(iVariableName, iValue)
    if ($DryRunOption)
      puts "export #{iVariableName}='#{iValue}'"
    else
      ENV[iVariableName] = iValue
    end
  end
  
  # The main method
  #
  # Parameters::
  # * *iRubyGemsTarBall* (_String_): Name of the tarball
  # * *iProjectUnixName* (_String_): Unix name of the project to install to
  # * *iRubyGemsSubPath* (_String_): Sub-path to install RubyGems
  # * *iGemsSubPath* (_String_): Sub-path to install Gems
  # Return::
  # * _String_: The path to the binary of RubyGems
  # * _String_: The path to the library of RubyGems
  # * _String_: The path to the repository of Gems
  def self.installRubyGems(iRubyGemsTarBall, iProjectUnixName, iRubyGemsSubPath, iGemsSubPath)
    rGemsCompletePath = nil
    lRubyGemsCompletePath = nil
    
    puts ''
    step("Install RubyGems from #{iRubyGemsTarBall} for project #{iProjectUnixName} in sub-directory #{iRubyGemsSubPath}, with Gems in sub-directory #{iGemsSubPath}") do
      puts ''
      # Check basics
      lProjectRootPath = checkBasics(iRubyGemsTarBall, iProjectUnixName)
      # Untar the tarball
      lTarBallDir = untar(iRubyGemsTarBall, lProjectRootPath)
      # Export the GEM_HOME variable
      rGemsCompletePath = "#{lProjectRootPath}/#{iGemsSubPath}"
      step("Setting GEM_HOME environment variable to #{rGemsCompletePath}") do
        setEnv('GEM_HOME', rGemsCompletePath)
      end
      # Install RubyGems
      lRubyGemsCompletePath = "#{lProjectRootPath}/#{iRubyGemsSubPath}"
      step("Installing RubyGems in directory #{lRubyGemsCompletePath}") do
        cdir(lTarBallDir) do
          execCmd("ruby setup.rb --prefix=#{lRubyGemsCompletePath}")
        end
      end
      step("Remove untared directory #{lTarBallDir}") do
        rm_rf(lTarBallDir)
      end
    end
    puts '# Don\'t forget to set the following when using RubyGems:'
    puts "#  * export GEM_HOME=#{rGemsCompletePath}"
    puts "#  * export PATH=$PATH:#{lRubyGemsCompletePath}/bin"
    puts "#  * export RUBYLIB=$RUBYLIB:#{lRubyGemsCompletePath}/lib"
    
    return "#{lRubyGemsCompletePath}/bin", "#{lRubyGemsCompletePath}/lib", rGemsCompletePath
  end

end

# If we were invoked directly
if (__FILE__ == $0)
  # Parse command line arguments, check them, and call the main function
  lRubyGemsTarBall, lProjectUnixName, lRubyGemsSubPath, lGemsSubPath = ARGV[0..3]
  $DryRunOption = nil
  $StepDepth = 1
  if (ARGV.size > 4)
    if (ARGV[4] == '-dryrun')
      $DryRunOption = true
    end
  else
    $DryRunOption = false
  end
  if ((lRubyGemsTarBall == nil) or
      (lProjectUnixName == nil) or
      (lRubyGemsSubPath == nil) or
      (lGemsSubPath == nil) or
      ($DryRunOption == nil))
    # Print some usage
    puts 'Usage:'
    puts 'ruby -w InstallRubyGemsSF.rb <RubyGemsTarBall> <ProjectUnixName> <RubyGemsSubPath> <GemsSubPath> [ -dryrun ]'
    puts '  -dryrun: Print commands, without executing them.'
    puts 'Example: ruby -w InstallRubyGemsSF.rb rubygems-1.3.1.tgz myproject rubygems rubygems/mygems'
    puts ''
    puts 'Check http://weacemethod.sourceforge.net/wiki/index.php/RubyGemsSF.NET for details.'
    exit 1
  else
    if ($DryRunOption)
      include FileUtils::DryRun
    else
      include FileUtils
    end
    RubyGemsInstaller::installRubyGems(lRubyGemsTarBall, lProjectUnixName, lRubyGemsSubPath, lGemsSubPath)
    exit 0
  end
end
