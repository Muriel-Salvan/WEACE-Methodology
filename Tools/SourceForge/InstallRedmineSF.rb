# Usage:
# ruby -w InstallRedmineSF.rb <RedmineTarBall> <ProjectUnixName> <ProjectID> <DatabaseName> <DatabaseAdminPassword> <RedmineSubPath> <RedmineSubURL> [ -cgionly ] [ -rubygems <RubyGemsTarBall> ] [ -rake <RakeTarBall> ] [ -fcgi <FCGIdevelTarBall> ] [ -dryrun ]
#   -dryrun: Print commands, without executing them.'
# Example: ruby -w InstallRedmineSF.rb redmine-0.8.2.tar.gz myproject 12345 redminedb myDBADMINpassword redmine redmine -rubygems rubygems-1.3.1.tgz -rake rake-0.8.4.tgz -fcgi fcgi-2.4.4.tar.gz
#
# Check http://weacemethod.sourceforge.net/wiki/index.php/RedmineSF.NET for details.
#--
# Copyright (c) 2009 - 2012 Muriel Salvan  (muriel@x-aeon.com)
# Licensed under BSD LICENSE. No warranty is provided.
#++

require 'fileutils'

module RedmineInstaller

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
  
  # Modify a file content
  #
  # Parameters::
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
  # Return::
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
  # Parameters::
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
  # Parameters::
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

  # Test that Rake is up and running in our environment
  #
  # Return::
  # * _Boolean_: Is Rake working ?
  def self.testRake
    rRakeOK = true
    # First test the ruby library
    begin
      require 'rake'
    rescue LoadError
      puts "# !!! Requiring 'rake' library in Ruby ended with an exception: #{$!}"
      rRakeOK = false
    end
    if (rRakeOK)
      # Then test the binary in the path
      begin
        lResult = system('rake --version >/dev/null')
        lErrorCode = $?
        if (!lResult)
          puts '# !!! Unable to invoke the \'rake\' binary'
          rRakeOK = false
        elsif (lErrorCode != 0)
          puts "# !!! Invoking 'rake --version' returned error code #{lErrorCode}"
          rRakeOK = false
        end
      rescue
        puts "# !!! Invoking 'rake --version' ended with an exception: #{$!}"
        rRakeOK = false
      end
    end
    
    return rRakeOK
  end
  
  # Ensure that Rake is setup in our environment
  # 1. Checks for Rake
  # 2. If it is not OK:
  # 2.1. Install it by calling the corresponding script
  # 2.2. Modify the environment to set it up
  #
  # Parameters::
  # * *iRakeTarBall* (_String_): The Rake tarball (can be nil if not given)
  # * *iProjectUnixName* (_String_): Unix name of the project to install to
  # * *iRakeBinSubPath* (_String_): Sub-path to install Rake's binary
  # * *iRakeLibSubPath* (_String_): Sub-path to install Rake's library
  def self.ensureRakeEnvironment(iRakeTarBall, iProjectUnixName, iRakeBinSubPath, iRakeLibSubPath)
    step('Check that Rake is setup correctly in our environment') do
      # First test it
      if (!testRake)
        # Check that we can install it
        if (iRakeTarBall == nil)
          raise RuntimeError, 'Rake environment is not setup correctly, and no Rake tarball has been specified. Use \'-rake <RakeTarBall>\' to set it up.'
        end
        begin
          require 'InstallRakeSF.rb'
        rescue LoadError
          raise RuntimeError, 'Unable to require InstallRakeSF.rb to install Rake. You have to download InstallRakeSF.rb in the same place as this script to make it work. You can download it from http://weacemethod.sourceforge.net/wiki/index.php/RakeSF.NET'
        end
        # Install it
        lRakeBinDir, lRakeLibDir = RakeInstaller::installRake(iRakeTarBall, iProjectUnixName, iRakeBinSubPath, iRakeLibSubPath)
        # Setup the environment
        addEnv('PATH', lRakeBinDir)
        addEnv('RUBYLIB', lRakeLibDir)
        $LOAD_PATH << lRakeLibDir
      end
    end
  end

  # Test that FCGI for Ruby is up and running in our environment.
  # Prerequisite: RubyGem is up and running in our environment.
  #
  # Return::
  # * _Boolean_: Is FCGI for Ruby working ?
  def self.testFCGIForRuby
    rFCGIForRubyOK = true
    # Test the ruby library
    begin
      require 'rubygems'
      require 'fcgi'
    rescue LoadError
      puts "# !!! Requiring 'fcgi' library in Ruby ended with an exception: #{$!}"
      rFCGIForRubyOK = false
    end
    
    return rFCGIForRubyOK
  end
  
  # Ensure that FCGI library for Ruby is setup in our environment
  # 1. Checks for FCGI library
  # 2. If it is not OK:
  # 2.1. Install it by calling the corresponding script
  # 2.2. Modify the environment to set it up
  #
  # Parameters::
  # * *iFCGITarBall* (_String_): The FCGI-devel tarball (can be nil if not given)
  # * *iProjectUnixName* (_String_): Unix name of the project to install to
  # * *iFCGISubPath* (_String_): Sub-path to install FCGI
  # * *iRubyGemsTarBall* (_String_): The RubyGems tarball (can be nil if not given)
  def self.ensureFCGIForRubyEnvironment(iFCGITarBall, iProjectUnixName, iFCGISubPath, iRubyGemsTarBall)
    step('Check that FCGI library for Ruby is setup correctly in our environment') do
      # First test it
      if (!testFCGIForRuby)
        # Check that we can install it
        if (iFCGITarBall == nil)
          raise RuntimeError, 'FCGI environment is not setup correctly, and no FCGI tarball has been specified. Use \'-fcgi <FCGITarBall>\' to set it up, or \'-cgionly\' to deactivate FCGI support.'
        end
        begin
          require 'InstallFCGIForRubySF.rb'
        rescue LoadError
          raise RuntimeError, 'Unable to require InstallFCGIForRubySF.rb to install Ruby\'s FCGI library. You have to download InstallFCGIForRubySF.rb in the same place as this script to make it work. You can download it from http://weacemethod.sourceforge.net/wiki/index.php/FCGIForRubySF.NET'
        end
        # Install it
        if ($DryRunOption)
          # Give the RubyGems tarball as if it was not installed, the FCGI installer will require it
          FCGIForRubyInstaller::installFCGIForRuby(iFCGITarBall, iProjectUnixName, iFCGISubPath, iRubyGemsTarBall)
        else
          FCGIForRubyInstaller::installFCGIForRuby(iFCGITarBall, iProjectUnixName, iFCGISubPath, nil)
        end
        # No environment to setup, as it is the goal of rubygems
      end
    end
  end

  # The main method
  #
  # Parameters::
  # * *iRedmineTarBall* (_String_): Name of the tarball
  # * *iProjectUnixName* (_String_): Unix name of the project to install to
  # * *iProjectID* (_String_): SourceForge.net's project ID
  # * *iDatabaseName* (_String_): Name of the database to be used by Redmine
  # * *iDatabasePassword* (_String_): Password of the admin user of the Redmine's database. It will ONLY be used to create database.yaml file.
  # * *iRedmineSubPath* (_String_): The sub-path in which Redmine will be installed
  # * *iRedmineSubURL* (_String_): The part of the URL where Redmine has to be accessed after http://<myproject>.sourceforge.net.
  # * *iRubyGemsTarBall* (_String_): The RubyGems tarball (can be nil if not given)
  # * *iRakeTarBall* (_String_): The Rake tarball (can be nil if not given)
  # * *iFCGITarBall* (_String_): The FCGI tarball (can be nil if not given)
  # * *iCGIOnlyOption* (_Boolean_): Do we choose to use CGI instead of FCGI ?
  # * *iSSSOption* (_Boolean_): Do we choose to generate a session store secret ?
  def self.installRedmine(iRedmineTarBall, iProjectUnixName, iProjectID, iDatabaseName, iDatabasePassword, iRedmineSubPath, iRedmineSubURL, iRubyGemsTarBall, iRakeTarBall, iFCGITarBall, iCGIOnlyOption, iSSSOption)
    lCGIExtension = iCGIOnlyOption ? 'cgi' : 'fcgi'
    puts ''
    step("Install Redmine from #{iRedmineTarBall}, for project #{iProjectUnixName} (ID=#{iProjectID}, in sub-directory #{iRedmineSubPath}, using database named #{iDatabaseName}, and URL 'http://#{iProjectUnixName}.sourceforge.net/#{iRedmineSubURL}' (Use #{lCGIExtension} support)") do
      puts ''
      # Check basics
      lProjectRootPath = checkBasics(iRedmineTarBall, iProjectUnixName)
      lRedmineCompletePath = "#{lProjectRootPath}/#{iRedmineSubPath}"
      step("Test that Redmine directory (#{lRedmineCompletePath}) does not exist yet") do
        if (File.exists?(lRedmineCompletePath))
          raise RuntimeError, "Redmine directory (#{lRedmineCompletePath}) already exists. Please remove it before installing Redmine here."
        end
      end
      # Untar the tarball
      lTarBallDir = untar(iRedmineTarBall, lProjectRootPath)
      # Move it to where we want
      step("Move untared directory #{lTarBallDir} to #{lRedmineCompletePath}") do
        lSplittedRedmineCompletePath = lRedmineCompletePath.split('/')
        mkdir_p(lSplittedRedmineCompletePath[0..-2].join('/'))
        mv(lTarBallDir, lRedmineCompletePath)
      end
      # Ensure RubyGems is setup
      ensureRubyGemsEnvironment(iRubyGemsTarBall, iProjectUnixName, "#{iRedmineSubPath}/vendor/rubygems", "#{iRedmineSubPath}/vendor/rubygems/mygems")
      # Ensure Rake is setup
      ensureRakeEnvironment(iRakeTarBall, iProjectUnixName, "#{iRedmineSubPath}/vendor/rake/bin", "#{iRedmineSubPath}/vendor/rake/lib")
      # Ensure FCGI is setup if needed
      if (!iCGIOnlyOption)
        ensureFCGIForRubyEnvironment(iFCGITarBall, iProjectUnixName, "#{iRedmineSubPath}/vendor/fcgi", iRubyGemsTarBall)
      end
      # Generate config/database.yml
      step("Generate file #{lRedmineCompletePath}/config/database.yml") do
        if ($DryRunOption)
          puts "# !!! Write file #{lRedmineCompletePath}/config/database.yml with correct parameters."
        else
          File.open("#{lRedmineCompletePath}/config/database.yml",'w') do |iFile|
            iFile << "production:\n"
            iFile << "  adapter: mysql\n"
            iFile << "  database: #{iProjectUnixName[0..0]}#{iProjectID}_#{iDatabaseName}\n"
            iFile << "  host: mysql-#{iProjectUnixName[0..0]}\n"
            iFile << "  username: #{iProjectUnixName[0..0]}#{iProjectID}admin\n"
            iFile << "  password: #{iDatabasePassword}\n"
          end
        end
      end
      # Create the database structure
      step('Create database structure for production') do
        cdir(lRedmineCompletePath) do
          execCmd('rake db:migrate RAILS_ENV="production"')
        end
      end
      # Insert default configuration data in database
      step('Insert default configuration data in database') do
        cdir(lRedmineCompletePath) do
          execCmd('rake redmine:load_default_data RAILS_ENV="production"')
        end
      end
      # Generate a session store secret
      # This step will fail for Redmine revision < 2493
      if (iSSSOption)
        step('Generate a session store secret') do
          cdir(lRedmineCompletePath) do
            execCmd('rake config/initializers/session_store.rb')
          end
        end
      end
      # Move writeable dirs
      lRedminePersistentDir = "#{lProjectRootPath}/persistent/#{iRedmineSubPath}"
      step("Move writeable directories #{lRedmineCompletePath}/{files|log|tmp|public/plugin_assets} to #{lRedminePersistentDir}") do
        mkdir_p(lRedminePersistentDir)
        mkdir_p("#{lRedminePersistentDir}/public")
        cp_r("#{lRedmineCompletePath}/files", lRedminePersistentDir)
        cp_r("#{lRedmineCompletePath}/log", lRedminePersistentDir)
        cp_r("#{lRedmineCompletePath}/tmp", lRedminePersistentDir)
        cp_r("#{lRedmineCompletePath}/public/plugin_assets", "#{lRedminePersistentDir}/public")
        rm_rf("#{lRedmineCompletePath}/files")
        rm_rf("#{lRedmineCompletePath}/log")
        rm_rf("#{lRedmineCompletePath}/tmp")
        rm_rf("#{lRedmineCompletePath}/public/plugin_assets")
      end
      # Create links to those dirs
      step('Create symbolic links to those directories back') do
        execCmd("ln -s #{lRedminePersistentDir}/files #{lRedmineCompletePath}/files")
        execCmd("ln -s #{lRedminePersistentDir}/log #{lRedmineCompletePath}/log")
        execCmd("ln -s #{lRedminePersistentDir}/tmp #{lRedmineCompletePath}/tmp")
        execCmd("ln -s #{lRedminePersistentDir}/public/plugin_assets #{lRedmineCompletePath}/public/plugin_assets")
      end
      # Give all permissions
      step('Give all permissions on the writeable directories') do
        execCmd("chmod 0777 #{lRedminePersistentDir}/files")
        execCmd("chmod 0777 #{lRedminePersistentDir}/log")
        execCmd("chmod 0777 #{lRedminePersistentDir}/tmp")
        execCmd("chmod 0777 #{lRedminePersistentDir}/tmp/*")
        execCmd("chmod 0777 #{lRedminePersistentDir}/public/plugin_assets")
      end
      # Touch log file
      step("Create log file #{lRedminePersistentDir}/log/production.log") do
        execCmd("touch #{lRedminePersistentDir}/log/production.log")
        execCmd("chmod 0666 #{lRedminePersistentDir}/log/production.log")
      end
      # Create symbolic link for URL
      lRedmineHTDocsDir = "#{lProjectRootPath}/htdocs/#{iRedmineSubURL}"
      step("Create symbolic link for the correct URL (#{lRedmineHTDocsDir})") do
        mkdir_p(lRedmineHTDocsDir.split('/')[0..-2].join('/'))
        execCmd("ln -s #{lRedmineCompletePath}/public #{lRedmineHTDocsDir}")
      end
      # Copy the correct dispatch script
      lOriginalScriptName = "#{lRedmineCompletePath}/public/dispatch.#{lCGIExtension}.example"
      lRedmineCGIDir = "#{lProjectRootPath}/cgi-bin/#{iRedmineSubURL}"
      lDispatchScriptName = "#{lRedmineCGIDir}/dispatch.#{lCGIExtension}"
      step("Copy the dispatch script #{lOriginalScriptName} to #{lDispatchScriptName}") do
        mkdir_p(lRedmineCGIDir)
        cp(lOriginalScriptName, lDispatchScriptName)
      end
      # Modify dispatch script
      step("Modify #{lDispatchScriptName}") do
        # First search for the path from $LOAD_PATH that contains rubygems.rb
        lRubyGemsLoadPath = nil
        if (!$DryRunOption)
          $LOAD_PATH.each do |iDir|
            if ((File.exists?("#{iDir}/rubygems.rb")) and
                (iDir[0..lProjectRootPath.size-1] == lProjectRootPath))
              lRubyGemsLoadPath = iDir
            end
          end
          if (lRubyGemsLoadPath == nil)
            raise RuntimeError, 'Unable to get which path from $LOAD_PATH contains rubygems.rb. Please make sure that rubygems.rb is among one of the $RUBYLIB paths, and that it is in your project\'s path (#{lProjectRootPath}).'
          end
        end
        # Then modify dispatch.[f]cgi
        modifyFile(lDispatchScriptName, /config\/environment/) do |iFile, iLine|
          iFile << "# Add the RubyGems library location in the Ruby library paths\n"
          iFile << "$LOAD_PATH << '#{lRubyGemsLoadPath}'\n"
          iFile << "\n"
          iFile << "# Add the RubyOnRails library location in the Ruby library paths\n"
          iFile << "$LOAD_PATH << '#{lRedmineCompletePath}/vendor/rails/railties/lib'\n"
          iFile << "\n"
          iFile << "# Set the RubyGems repository\n"
          iFile << "ENV['GEM_HOME']='#{ENV['GEM_HOME']}'\n"
          iFile << "\n"
          iFile << "# Make RubyOnRails believe that the dispatch.#{lCGIExtension} script was called from its original location (that is the path from htdocs/)\n"
          iFile << "ENV['SCRIPT_NAME'] = '/#{iRedmineSubURL}/dispatch.#{lCGIExtension}'\n"
          iFile << " \n"
          iFile << "require '#{lRedmineCompletePath}/config/environment'\n"
        end
      end
      # Modify config/environment.rb
      lEnvironmentFile = "#{lRedmineCompletePath}/config/environment.rb"
      step("Modify #{lEnvironmentFile}") do
        modifyFile(lEnvironmentFile, /# ENV\['RAILS_ENV'\]/) do |iFile, iLine|
          iFile << "ENV['RAILS_ENV'] ||= 'production'\n"
        end
      end
      # Rewrite completely .htaccess file
      lHTAccessFile = "#{lRedmineCompletePath}/public/.htaccess"
      step("Rewrite #{lHTAccessFile}") do
        if ($DryRunOption)
          puts "# !!! Write file #{lHTAccessFile} with correct options."
        else
          File.open(lHTAccessFile, 'w') do |iFile|
            iFile << "# General Apache options\n"
            iFile << "# Here we use only FastCGI\n"
            if (iCGIOnlyOption)
              iFile << "AddHandler cgi-script .cgi\n"
            else
              iFile << "AddHandler fastcgi-script .fcgi\n"
            end
            iFile << "Options +FollowSymLinks +ExecCGI\n"
            iFile << "\n"
            iFile << "# If you don't want Rails to look in certain directories,\n"
            iFile << "# use the following rewrite rules so that Apache won't rewrite certain requests\n"
            iFile << "# \n"
            iFile << "# Example:\n"
            iFile << "#   RewriteCond %{REQUEST_URI} ^/notrails.*\n"
            iFile << "#   RewriteRule .* - [L]\n"
            iFile << "\n"
            iFile << "# Redirect all requests not available on the filesystem to Rails\n"
            iFile << "# By default the cgi dispatcher is used which is very slow\n"
            iFile << "# \n"
            iFile << "# For better performance replace the dispatcher with the fastcgi one\n"
            iFile << "#\n"
            iFile << "# Example:\n"
            iFile << "#   RewriteRule ^(.*)$ dispatch.fcgi [QSA,L]\n"
            iFile << "RewriteEngine On\n"
            iFile << "\n"
            iFile << "# If your Rails application is accessed via an Alias directive,\n"
            iFile << "# then you MUST also set the RewriteBase in this htaccess file.\n"
            iFile << "#\n"
            iFile << "# Example:\n"
            iFile << "#   Alias /myrailsapp /path/to/myrailsapp/public\n"
            iFile << "#   RewriteBase /myrailsapp\n"
            iFile << "\n"
            iFile << "# As the script will be in cgi-bin, move the base of rules to the project's root\n"
            iFile << "RewriteBase #{lProjectRootPath}\n"
            iFile << "\n"
            iFile << "# If no file specified, use index.html, appending the options\n"
            iFile << "RewriteRule ^$ index.html [QSA]\n"
            iFile << "\n"
            iFile << "# If no extension specified, use .html, appending the options\n"
            iFile << "RewriteRule ^([^.]+)$ $1.html [QSA]\n"
            iFile << "\n"
            iFile << "# If the specified file does not exist,\n"
            iFile << "RewriteCond %{REQUEST_FILENAME} !-f\n"
            iFile << "# then call dispatch file, appending the options. This is the last rule.\n"
            iFile << "RewriteRule ^(.*)$ /cgi-bin/#{iRedmineSubPath}/dispatch.#{lCGIExtension} [QSA,L]\n"
            iFile << "\n"
            iFile << "# In case Rails experiences terminal errors\n"
            iFile << "# Instead of displaying this message you can supply a file here which will be rendered instead\n"
            iFile << "# \n"
            iFile << "# Example:\n"
            iFile << "#   ErrorDocument 500 /500.html\n"
            iFile << "\n"
            iFile << "ErrorDocument 500 \"<h2>Application error</h2>Rails application failed to start properly\"\n"
          end
        end
      end
    end
  end

end

# If we were invoked directly
if (__FILE__ == $0)
  # Parse command line arguments, check them, and call the main function
  lRedmineTarBall, lProjectUnixName, lProjectID, lDatabaseName, lDatabasePassword, lRedmineSubPath, lRedmineSubURL = ARGV[0..6]
  lRubyGemsTarBall = nil
  lRakeTarBall = nil
  lFCGITarBall = nil
  lCGIOnlyOption = nil
  lSSSOption = nil
  lInvalid = false
  $DryRunOption = false
  $StepDepth = 1
  if (ARGV.size > 7)
    # Parse remaining arguments
    lIdxARGV = 7
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
      when '-rake'
        lIdxARGV += 1
        lRakeTarBall = ARGV[lIdxARGV]
        if (lRakeTarBall == nil)
          lInvalid = true
        end
      when '-fcgi'
        lIdxARGV += 1
        lFCGITarBall = ARGV[lIdxARGV]
        if (lFCGITarBall == nil)
          lInvalid = true
        end
      when '-cgionly'
        lCGIOnlyOption = true
      when '-sessionstoresecret'
        lSSSOption = true
      else
        lInvalid = true
      end
      lIdxARGV += 1
    end
  end
  if ((lRedmineTarBall == nil) or
      (lProjectUnixName == nil) or
      (lProjectID == nil) or
      (lDatabaseName == nil) or
      (lDatabasePassword == nil) or
      (lRedmineSubPath == nil) or
      (lRedmineSubURL == nil) or
      (lInvalid))
    # Print some usage
    puts 'Usage:'
    puts 'ruby -w InstallRedmineSF.rb <RedmineTarBall> <ProjectUnixName> <ProjectID> <DatabaseName> <DatabaseAdminPassword> <RedmineSubPath> <RedmineSubURL> [ -cgionly ] [ -rubygems <RubyGemsTarBall> ] [ -rake <RakeTarBall> ] [ -fcgi <FCGIdevelTarBall> ] [ -dryrun ]'
    puts '  -dryrun: Print commands, without executing them.'
    puts 'Example: ruby -w InstallRedmineSF.rb redmine-0.8.2.tar.gz myproject 12345 redminedb myDBADMINpassword redmine redmine -rubygems rubygems-1.3.1.tgz -rake rake-0.8.4.tgz -fcgi fcgi-2.4.4.tar.gz'
    puts ''
    puts 'Check http://weacemethod.sourceforge.net/wiki/index.php/RedmineSF.NET for details.'
    exit 1
  else
    if ($DryRunOption)
      include FileUtils::DryRun
    else
      include FileUtils
    end
    RedmineInstaller::installRedmine(lRedmineTarBall, lProjectUnixName, lProjectID, lDatabaseName, lDatabasePassword, lRedmineSubPath, lRedmineSubURL, lRubyGemsTarBall, lRakeTarBall, lFCGITarBall, lCGIOnlyOption, lSSSOption)
    exit 0
  end
end
