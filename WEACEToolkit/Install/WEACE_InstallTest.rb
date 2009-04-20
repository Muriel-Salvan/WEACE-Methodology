# Usage: This file is used by other files.
# Do not call it directly.
#
# Check http://weacemethod.sourceforge.net for details.
#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

require 'WEACE_Common.rb'
require 'fileutils'
require 'tmpdir'

module WEACEInstall

  # This module contains every tool needed for test cases
  module TestToolbox

    module Adapters

      include WEACE::Toolbox
      include WEACE::Logging

      class DummyProviderEnv

        attr_accessor :ProviderType
        attr_accessor :CGIURL

      end

      # Replace variables that can be used in lines of test files
      # Current replacements:
      # '%{WEACEToolkitDir}' => $WEACEToolkitDir
      # '%{ProviderCGIURL}' => 'http://mytest.com/cgi'
      # '%%' => '%'
      #
      # Parameters:
      # * *iLine* (_String_): The line containing variables
      # Return:
      # * _String_: The line with variables replaced
      def replaceVars(iLine)
        rResult = iLine.gsub('%{WEACEToolkitDir}', $WEACEToolkitDir)

        rResult.gsub!('%{ProviderCGIURL}', 'http://mytest.com/cgi')
        rResult.gsub!('%%', '%')

        return rResult
      end

      # Compare 2 files contents.
      # This is used for testing purposes. It compares each file (replacing variables and matching regexps if needed).
      # The second file is considered the reference, and is the only one who can contain regexps.
      # Regexps are identified like this, from the beginning of the line:
      # %/<RegExp>/
      #
      # Parameters:
      # * *iFile1* (_String_): First directory
      # * *iFile2* (_String_): Second directory
      # Return:
      # * _Boolean_: Are files the same ?
      def compareFiles(iFile1, iFile2)
        rResult = false

        lContent1 = nil
        File.open(iFile1, 'r') do |iFile|
          lContent1 = iFile.readlines
        end
        lContent2 = nil
        File.open(iFile2, 'r') do |iFile|
          lContent2 = iFile.readlines
        end
        if (lContent1.size == lContent2.size)
          rResult = true
          (0..lContent1.size-1).each do |iIdx|
            # Replace variables in lContent1 and lContent2
            lReference = lContent2[iIdx].gsub('%{WEACEToolkitDir}', $WEACEToolkitDir)
            lReference.gsub!('%{ProviderCGIURL}', 'http://mytest.com/cgi')
            lReference.gsub!('%%', '%')
            # Look for a regexp
            if (lContent2[iIdx][0..1] == '%/')
              # Remove the %/ .. / characters
              lReference = lReference[2..-2]
              # Regexp
              if (lContent1[iIdx].match(lReference) == nil)
                # A difference
                logErr "Files #{iFile1} and #{iFile2} differ on line #{iIdx}: '#{lContent1[iIdx]}' should match /#{lReference}/."
                rResult = false
                break
              end
              # String comparison
            elsif (lContent1[iIdx] != lReference)
              # A difference
              logErr "Files #{iFile1} and #{iFile2} differ on line #{iIdx}: '#{lContent1[iIdx]}' should be '#{lReference}'."
              rResult = false
              break
            end
          end
        else
          logErr "Number of lines differ from #{iFile1} (#{lContent1.size} lines), and #{iFile2} (#{lContent2.size} lines)."
        end

        return rResult
      end

      # Compare 2 directories contents.
      # This is used for testing purposes. It compares each file (replacing variables and matching regexps if needed).
      # The second directory is taken as the reference.
      # Files whose extension is .WEACEBackup from the first directories are ignored.
      # Parameters:
      # * *iDir1* (_String_): First directory
      # * *iDir2* (_String_): Second directory
      # Return:
      # * _Boolean_: Are directories the same ?
      def compareDirs(iDir1, iDir2)
        rResult = false

        # First, the contents
        lDir1Content = []
        Dir.glob("#{iDir1}/*").each do |iFileName|
          if (iFileName[-12..-1] != '.WEACEBackup')
            lDir1Content << File.basename(iFileName)
          end
        end
        lDir2Content = []
        Dir.glob("#{iDir2}/*").each do |iFileName|
          lDir2Content << File.basename(iFileName)
        end
        if (lDir1Content.size == lDir2Content.size)
          # Get the list of files and directories
          rResult = true
          lFiles = []
          lDirs = []
          lDir2Content.each do |iFileName|
            if (lDir1Content.index(iFileName) == nil)
              # A difference
              logErr "File #{iFileName} exists in #{iDir2}, but not in #{iDir1}."
              rResult = false
              break
            end
          end
          lDir1Content.each do |iFileName|
            if (lDir2Content.index(iFileName) == nil)
              # A difference
              logErr "File #{iFileName} exists in #{iDir1}, but not in #{iDir2}."
              rResult = false
              break
            end
            if (File.directory?("#{iDir1}/#{iFileName}"))
              if (File.directory?("#{iDir2}/#{iFileName}"))
                lDirs << iFileName
              else
                # A difference
                logErr "Directory #{iFileName} from #{iDir1} is a file in #{iDir2}."
                rResult = false
                break
              end
            elsif (!File.directory?("#{iDir2}/#{iFileName}"))
              lFiles << iFileName
            else
              # A difference
              logErr "File #{iFileName} from #{iDir1} is a directory in #{iDir2}."
              rResult = false
              break
            end
          end
          if (rResult)
            # Now we compare each directory
            lDirs.each do |iDir|
              rResult = compareDirs("#{iDir1}/#{iDir}", "#{iDir2}/#{iDir}")
              if (!rResult)
                break
              end
            end
            if (rResult)
              # Now we compare each file
              lFiles.each do |iFile|
                rResult = compareFiles("#{iDir1}/#{iFile}", "#{iDir2}/#{iFile}")
                if (!rResult)
                  break
                end
              end
            end
          end
        else
          logErr "Number of files differ from #{iDir1} (#{lDir1Content.size} files), and #{iDir2} (#{lDir2Content.size} files)."
        end

        return rResult
      end

      # Copy a directory content into another, ignoring SVN files
      #
      # Parameters:
      # * *iSrcDir* (_String_): Source directory
      # * *iDstDir* (_String_): Destination directory
      def copyDir(iSrcDir, iDstDir)
        FileUtils.mkdir_p(iDstDir)
        Dir.glob("#{iSrcDir}/*").each do |iFileName|
          lBaseName = File.basename(iFileName)
          if (File.directory?(iFileName))
            # Ignore .svn directory
            if (lBaseName != '.svn')
              copyDir(iFileName, "#{iDstDir}/#{lBaseName}")
            end
          else
            # Copy a file, eventually replacing variables in it
            lContent = nil
            File.open(iFileName, 'r') do |iFile|
              lContent = iFile.readlines
            end
            File.open("#{iDstDir}/#{lBaseName}", 'w') do |iFile|
              lContent.each do |iLine|
                iFile << replaceVars(iLine)
              end
            end
          end
        end
      end

      # Execute a test.
      # This is called by test cases.
      #
      # Parameters:
      # * *iRepositoryName* (_String_): Name of the repository to use the script on.
      # * *iCmdLine* (_String_): The command line to give the installer to test.
      # * *iRepositoryReference* (_String_): Name of the repository to use as a reference.
      def executeTest(iRepositoryName, iCmdLine, iRepositoryReferenceName)
        # Get the ID of the test, based on its class name
        lMatchData = self.class.name.match(/^WEACEInstall::(.*)::Adapters::(.*)::(.*)::Test_(.*)$/)
        if (lMatchData == nil)
          logErr "Testing class (#{self.class.name}) is not of the form WEACEInstall::{Master|Slave}::Adapters::<ProductID>::<ToolID>::Test_<ScriptID>"
        else
          lType, lProductID, lToolID, lScriptID = lMatchData[1..4]
          lRepositoriesDir = "#{$WEACEToolkitDir}/Install/#{lType}/Adapters/#{lProductID}/#{lToolID}/test/#{lScriptID}"
          # 1. Copy the repository in a temporary folder to execute the test on
          # Get the test name
          lTestName = 'unknown'
          caller.each do |iLine|
            lMatch = iLine.match(/^.*\`test(.*)'$/)
            if (lMatch != nil)
              lTestName = lMatch[1]
            end
          end
          lRepositoryDir = "#{Dir.tmpdir}/WEACETesting/#{lType}/#{lProductID}/#{lToolID}/#{lScriptID}/test#{lTestName}"
          log "Create temporary repository in #{lRepositoryDir}"
          # Copy files without SVN contents
          copyDir("#{lRepositoriesDir}/#{iRepositoryName}", lRepositoryDir)
          # 2. Execute the testing
          lComponentName = "WEACE#{lType}Adapter.#{lProductID}.#{lToolID}.#{lScriptID}"
          log "Execute installation of component #{lComponentName}"
          require 'install.rb'
          lProviderEnv = DummyProviderEnv.new
          lProviderEnv.ProviderType = 'Test'
          lProviderEnv.CGIURL = 'http://mytest.com/cgi'
          lParameters = iCmdLine.gsub(/%\{Repository\}/, lRepositoryDir).split(' ')
          lFileName = "Install/Master/Adapters/#{lProductID}/#{lToolID}/Install_#{lScriptID}.rb"
          lClassName = "WEACEInstall::Master::Adapters::#{lProductID}::#{lToolID}::#{lScriptID}"
          lSuccess = true
          begin
            WEACEInstall::Installer.new.installComponentFromFile(lComponentName, lFileName, lClassName, lParameters, lProviderEnv)
          rescue Exception
            logErr "Exception while installing component #{lComponentName}: #{$!}"
            lSuccess = false
          end
          # 3. Compare the repository with the reference
          if (lSuccess)
            log "Compare repositories for component #{lComponentName} with reference #{iRepositoryReferenceName}"
            lSuccess = compareDirs(lRepositoryDir, "#{lRepositoriesDir}/#{iRepositoryReferenceName}")
          end
          # 4. Delete the temporary directory
          if (lSuccess)
            log "Delete temporary repository #{lRepositoryDir}"
            FileUtils.rm_rf(lRepositoryDir)
          else
            logWarn "Temporary repository #{lRepositoryDir} is not deleted for investigation purposes."
          end
          # 5. Give the result
          assert(lSuccess)
        end
      end

    end

  end

end
