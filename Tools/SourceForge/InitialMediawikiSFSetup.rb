# Usage:
# ruby -w InitialMediawikiSFSetup.rb <MediawikiTarBall> <ProjectUNIXName> <ProjectID> <ProjectReadableName> <MediawikiSubPath> [ -dryrun ]
#   -dryrun: Make the script print everything it will do normally, without actually performing any action.
# Example:
#   ruby -w InitialMediawikiSFSetup.rb mediawiki-1.14.0.tar.gz myproject 12345 MyProject wiki
lMediaWikiTarBallName, lProjectName, lProjectID, lProjectReadableName, lMediawikiSubPath = ARGV[0..4]
lInvalidOption = false
$DryRunOption = false
if (ARGV.size > 5)
  if (ARGV[5] == '-dryrun')
    $DryRunOption = true
  else
    lInvalidOption = true
  end
end

if ((lMediaWikiTarBallName == nil) or
    (lProjectName == nil) or
    (lProjectID == nil) or
    (lProjectReadableName == nil) or
    (lMediawikiSubPath == nil) or
    (lInvalidOption))
  puts 'Usage: ruby -w InitialMediawikiSFSetup.rb <MediawikiTarBall> <ProjectUNIXName> <ProjectID> <ProjectReadableName> <MediawikiSubPath> [ -dryrun ]'
  puts '  -dryrun: Make the script print everything it will do normally, without actually performing any action.'
  puts 'Example:'
  puts '  ruby -w InitialMediawikiSFSetup.rb mediawiki-1.14.0.tar.gz myproject 12345 MyProject wiki'
  exit 1
end

if (!File.exist?(lMediaWikiTarBallName))
  puts "File #{lMediaWikiTarBallName} missing."
  exit 1
end

lProjectPath = "/home/groups/#{lProjectName[0..0]}/#{lProjectName[0..1]}/#{lProjectName}"
if (!File.exist?(lProjectPath))
  puts "Directory #{lProjectPath} missing."
  exit 1
end

puts "Environment seems to be ok."
puts ''

# Execute a command, and abort everything in case of an error
#
# Parameters::
# * *iMsg* (_String_): The message to display for the operation
# * *iCmd* (_String_): The command to execute
def execCmd(iMsg, iCmd)
  puts "# #{iMsg} ..."
  if ($DryRunOption)
    puts iCmd
  else
    lResult = system(iCmd)
    lErrorCode = $?
    if (!lResult)
      puts "# !!! Error while executing command \"#{iCmd}\"."
      exit 1
    end
    if (lErrorCode != 0)
      puts "# !!! Command \"#{iCmd}\" returned error code #{lErrorCode}."
      exit 1
    end
  end
  puts "# ... OK (#{iMsg})"
  puts ''
end

require 'fileutils'

if ($DryRunOption)
  include FileUtils::DryRun
else
  include FileUtils
end

lWikiPath = "#{lProjectPath}/htdocs/#{lMediawikiSubPath}"
lSubdirName = lMediaWikiTarBallName[0..-8]

execCmd("Untar Mediawiki archive in #{lProjectPath}/htdocs/#{lSubdirName}", "tar xzf #{lMediaWikiTarBallName} -C #{lProjectPath}/htdocs")

puts '# Create symbolic links to persistent directories ...'
lPersistentWikiPath = "#{lProjectPath}/persistent/#{lMediawikiSubPath}"
mv("#{lProjectPath}/htdocs/#{lSubdirName}", lWikiPath)
mv("#{lWikiPath}/images", "#{lWikiPath}/images_TOBEREPLACED")
mkdir_p("#{lPersistentWikiPath}/sessions")
ln_s("#{lPersistentWikiPath}/sessions", "#{lWikiPath}/sessions")
chmod(0777, "#{lPersistentWikiPath}/sessions")
mkdir_p("#{lPersistentWikiPath}/images")
ln_s("#{lPersistentWikiPath}/images", "#{lWikiPath}/images")
cp_r("#{lWikiPath}/images_TOBEREPLACED/.", "#{lWikiPath}/images")
rm_rf("#{lWikiPath}/images_TOBEREPLACED")
chmod(0777, "#{lPersistentWikiPath}/images")
puts '# ... OK'
puts ''

puts '# Prepare configuration of Mediawiki ...'
if ($DryRunOption)
  puts "# !!! Modify file #{lWikiPath}/config/index.php"
else
  lFileContent = nil
  File.open("#{lWikiPath}/config/index.php", 'r') do |iFile|
    lFileContent = iFile.readlines
  end
  File.open("#{lWikiPath}/config/index.php", 'w') do |iFile|
    lSectionEntered = false
    lFound = false
    lFileContent.each do |lLine|
      if (lLine.match(/if\( !is_writable/) != nil)
        # We begin to enter the part to comment
        iFile << "/*\n"
        lSectionEntered = true
      end
      iFile << lLine
      if ((lSectionEntered) and
          (lLine.match(/\}/) != nil))
        # We end the section to comment
        iFile << "*/\n"
        lFound = true
        lSectionEntered = false
      end
    end
    if (!lFound)
      puts "# !!! Warning: Unable to find the section to comment in #{lWikiPath}/config/index.php."
    end
  end
end
puts '# ... OK'
puts ''

puts "# Now, visit http://#{lProjectName}.sourceforge.net/#{lMediawikiSubPath}"
puts '# Fill the following fields:'
puts "#    * Wiki name: #{lProjectReadableName}"
puts '#    * Contact e-mail: <YourMail>'
puts '#    * Admin username : WikiSysop'
puts '#    * Password : <WikiSysopPassword>'
puts '#    * E-mail (general): disabled'
puts "#    * mysql: mysql-#{lProjectName[0..0]}"
puts "#    * Database name: #{lProjectName[0..0]}#{lProjectID}_<DatabaseName>"
puts "#    * DB username : #{lProjectName[0..0]}#{lProjectID}admin"
puts "#    * DB password: <PasswordChosenFor_#{lProjectName[0..0]}#{lProjectID}admin>"
puts ''
puts '# Then, validate and copy paste the result of LocalSettings.php in this terminal, and finish it with a line containing only EOF'
puts '# ... waiting for LocalSettings.php content to be pasted ...'

if ($DryRunOption)
  puts "# !!! Paste the content of LocalSettings.php. The script will then change the memory limit and the session save path. It will then write LocalSettings.php with the result."
else
  lFinished = false
  lFileContent = []
  lFoundMemory = false
  lFoundBegin = false
  while (!lFinished) do
    lLine = $stdin.gets
    if (lLine == "EOF\n")
      lFinished = true
    else
      if (lLine.match(/ini_set\( 'memory_limit'/))
        # Change memory limit
        lLine = "ini_set( \'memory_limit\', \'32M\' );\n"
        lFoundMemory = true
      end
      lFileContent << lLine
      if (lLine == "<?php\n")
        # Add error detection, but commented
        lFileContent << "#error_reporting(E_ALL);\n"
        lFileContent << "#ini_set(\"display_errors\", 1);\n"
        lFoundBegin = true
      elsif (lLine.match(/ini_set\( 'memory_limit'/))
        # Add sessions directory
        lFileContent << "session_save_path(\"#{lWikiPath}/sessions/\");\n"
      end
    end
  end
  lFileContent << "$wgEnableUploads = true;\n"
  if (!lFoundBegin)
    puts '!!! Warning: Unable to find the beginning of php script.'
  end
  if (!lFoundMemory)
    puts '!!! Warning: Unable to find the memory setting (ini_set( \'memory_limit\')'
  end
  puts ''

  puts '# Write LocalSettings file ...'
  # Add uploads
  File.open("#{lWikiPath}/LocalSettings.php", 'w') do |iFile|
    iFile << lFileContent
  end
  puts '# ... OK'
end
puts ''

puts '# Remove config folder ...'
rm_rf("#{lWikiPath}/config")
puts '# ... OK'
puts ''

puts '# Add SF.NET logo in Skin.php ...'
if ($DryRunOption)
  puts "# !!! Modify file #{lWikiPath}/includes/Skin.php (getPoweredBy function)."
else
  lFileContent = nil
  File.open("#{lWikiPath}/includes/Skin.php", 'r') do |iFile|
    lFileContent = iFile.readlines
  end
  File.open("#{lWikiPath}/includes/Skin.php", 'w') do |iFile|
    lEnteredSection = false
    lFound = false
    lFileContent.each do |lLine|
      if (lLine.match(/getPoweredBy/) != nil)
        lEnteredSection = true
      elsif (lEnteredSection)
        if (lLine.match(/\}/) != nil)
          lEnteredSection = false
        elsif (lLine.match(/return/) != nil)
          # Insert the SF logo here
          iFile << "$sfimg  = \'<a href=\"http://sourceforge.net/projects/#{lProjectName}\"><img src=\"http://sflogo.sourceforge.net/sflogo.php?group_id=#{lProjectID}&amp;type=12\" width=\"88\" height=\"31\" border=\"0\" alt=\"Get #{lProjectReadableName} at SourceForge.net. Fast, secure and Free Open Source software downloads\" /></a>\';\n"
          lLine = "return $img.$sfimg;\n"
          lFound = true
        end
      end
      iFile << lLine
    end
    if (!lFound)
      puts "# !!! Warning: Unable to add the SF logo in #{lWikiPath}/includes/Skin.php."
    end
  end
end
puts '# ... OK'
puts ''

puts '# Initial setup complete.'
