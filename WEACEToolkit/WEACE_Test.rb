# Usage: This file is used by other files.
# Do not call it directly.
#
# Check http://weacemethod.sourceforge.net for details.
#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

require 'WEACEToolkit/WEACE_Common'
require 'fileutils'
require 'tmpdir'

module WEACE

  # This module contains every tool needed for test cases
  module TestToolbox

    module Adapters

      include WEACE::Toolbox

      class DummyProviderEnv

        attr_accessor :ProviderType
        attr_accessor :CGIURL

      end

      # Replace variables that can be used in lines of test files.
      # Use @ConstextVars to decide which variables to replace.
      # Replace alse '%%' with '%'
      #
      # Parameters:
      # * *iLine* (_String_): The line containing variables
      # Return:
      # * _String_: The line with variables replaced
      def replaceVars(iLine)
        rResult = iLine.clone

        @ContextVars.each do |iVariable, iValue|
          rResult.gsub!("%{#{iVariable}}", iValue)
        end
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
      # * *iVarContext* (<em>map<String,String></em>): The variables to be replaced
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
            lReference = replaceVars(lContent2[iIdx])
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
      
      # Get details about the test case currently running (based on the class name)
      #
      # Return:
      # * _String_: The type (Master|Slave)
      # * _String_: The Product ID
      # * _String_: The Tool ID
      # * _String_: The Script ID
      # * _String_: The test case name
      # * _Boolean_: Does this test case test installation scripts ?
      def getTestDetails
        rType = nil
        rProductID = nil
        rToolID = nil
        rScriptID = nil
        rTestName = 'unknown'
        rInstallTest = nil
        
        # Get the ID of the test, based on its class name
        lMatchData = self.class.name.match(/^WEACEInstall::(.*)::Adapters::(.*)::(.*)::Test_(.*)$/)
        if (lMatchData == nil)
          lMatchData = self.class.name.match(/^WEACE::(.*)::Adapters::(.*)::(.*)::Test_(.*)$/)
          if (lMatchData == nil)
            logErr "Testing class (#{self.class.name}) is not of the form WEACE[Install]::{Master|Slave}::Adapters::<ProductID>::<ToolID>::Test_<ScriptID>"
            raise RuntimeError, "Testing class (#{self.class.name}) is not of the form WEACE[Install]::{Master|Slave}::Adapters::<ProductID>::<ToolID>::Test_<ScriptID>"
          else
            rType, rProductID, rToolID, rScriptID = lMatchData[1..4]
            rInstallTest = false
          end
        else
          rType, rProductID, rToolID, rScriptID = lMatchData[1..4]
          rInstallTest = true
        end
        # Remove the beginning 'test' from the method name
        rTestName = @method_name[4..-1]
        
        return rType, rProductID, rToolID, rScriptID, rTestName, rInstallTest
      end
      
      # Setup each test
      def setup
        # The map of variables that will be replaced by their values in the test files and command lines
        #   map< Symbol, Object >
        @ContextVars = {
          # TODO: Remove usage of $WEACEToolkitDir
          'WEACEToolkitDir' => $WEACEToolkitDir,
          'ProviderCGIURL' => 'http://mytest.com/cgi'
        }
        @Type, @ProductID, @ToolID, @ScriptID, @TestName, @InstallTest = getTestDetails
        @ComponentName = "WEACE#{@Type}Adapter.#{@ProductID}.#{@ToolID}.#{@ScriptID}"
        @TestSuccess = true
        if (@InstallTest)
          logDebug "Running test for installation of #{@ComponentName}: Test #{@TestName}"
        else
          logDebug "Running test for #{@ComponentName}: Test #{@TestName}"
        end
      end
      
      # Finalize each test
      def teardown
        assert(@TestSuccess)
      end

      # Setup a temporary repository as an image of a given repository.
      # The repository is then deleted once the code block finishes.
      #
      # Parameters:
      # * *iRepositoryName* (_String_): Name of the repository to use as an image.
      # * *CodeBlock*: Code called once the repository is created.
      # ** *iRepositoryDir* (_String_): Directory to the created temporary repository
      def setupRepository(iRepositoryName)
        if ((defined?(@RepositoryDir)) and
            (@RepositoryDir != nil))
          logErr "A repository has already been setup in this test case: #{@RepositoryDir}. You can not cascade repository setups."
          raise RuntimeError, "A repository has already been setup in this test case: #{@RepositoryDir}. You can not cascade repository setups."
        end
        if (@InstallTest)
          @RepositoriesDir = "#{$WEACEToolkitDir}/Install/#{@Type}/Adapters/#{@ProductID}/#{@ToolID}/test/#{@ScriptID}"
          @RepositoryDir = "#{Dir.tmpdir}/WEACETesting/#{@Type}/#{@ProductID}/#{@ToolID}/#{@ScriptID}/testInstall#{@TestName}"
        else
          @RepositoriesDir = "#{$WEACEToolkitDir}/#{@Type}/Adapters/#{@ProductID}/#{@ToolID}/test/#{@ScriptID}"
          @RepositoryDir = "#{Dir.tmpdir}/WEACETesting/#{@Type}/#{@ProductID}/#{@ToolID}/#{@ScriptID}/test#{@TestName}"
        end
        @ContextVars['Repository'] = @RepositoryDir
        # Copy the repository in a temporary folder to execute the test on
        logDebug "Create temporary repository in #{@RepositoryDir}"
        # Copy files without SVN contents
        copyDir("#{@RepositoriesDir}/#{iRepositoryName}", @RepositoryDir)
        # Call the code block
        yield(@RepositoryDir)
        # Clean up if everything went ok
        if (@TestSuccess)
          logDebug "Delete temporary repository #{@RepositoryDir}"
          FileUtils.rm_rf(@RepositoryDir)
        else
          logWarn "Temporary repository #{@RepositoryDir} is not deleted for investigation purposes."
        end
        @RepositoryDir = nil
      end

      # Compare the current repository with a reference repository
      #
      # Parameters:
      # * *iRepositoryName* (_String_): Name of the repository to use as a reference.
      def compareWithRepository(iRepositoryName)
        if ((!defined?(@RepositoryDir)) or
            (@RepositoryDir == nil))
          logErr "You must first setup a repository using 'setupRepository' before calling 'compareWithRepository'."
          raise RuntimeError, "You must first setup a repository using 'setupRepository' before calling 'compareWithRepository'."
        end
        if (@TestSuccess)
          logDebug "Compare repositories for component #{@ComponentName} with reference #{iRepositoryName}"
          @TestSuccess = compareDirs(@RepositoryDir, "#{@RepositoriesDir}/#{iRepositoryName}")
        end
      end

      # Execute a test.
      # This is called by test cases of adapters' installation scripts.
      #
      # Parameters:
      # * *iCmdLine* (_String_): The command line to give the installer to test.
      def executeAdapterInstallTest(iCmdLine)
        logDebug "Execute installation of component #{@ComponentName}"
        require 'install.rb'
        lProviderEnv = DummyProviderEnv.new
        lProviderEnv.ProviderType = 'Test'
        lProviderEnv.CGIURL = @ContextVars['ProviderCGIURL']
        lParameters = replaceVars(iCmdLine).split(' ')
        lFileName = "Install/#{@Type}/Adapters/#{@ProductID}/#{@ToolID}/Install_#{@ScriptID}.rb"
        lClassName = "WEACEInstall::#{@Type}::Adapters::#{@ProductID}::#{@ToolID}::#{@ScriptID}"
        begin
          WEACEInstall::Installer.new.installComponentFromFile(@ComponentName, lFileName, lClassName, lParameters, lProviderEnv)
        rescue Exception
          logErr "Exception while installing component #{@ComponentName}: #{$!}"
          logErr $!.backtrace.join("\n")
          @TestSuccess = false
        end
      end

      # Execute a test.
      # This is called by test cases of normal WEACE Slave Adapters.
      #
      # Parameters:
      # * *iProductParameters* (<em>map<Symbol,Object></em>): The map of product parameters to give the Adapter
      # * *Parameters*: List of additional Action parameters
      def executeSlaveAdapterTest(iProductParameters, *iActionParameters)
        logDebug "Execute component #{@ComponentName}"
        # Require the correct adapter file for the given action
        begin
          require "WEACEToolkit/Slave/Adapters/#{@ProductID}/#{@ToolID}/#{@ProductID}_#{@ToolID}_#{@ScriptID}"
          begin
            lAdapter = eval("#{@ProductID}::#{@ToolID}::#{@ActionID}.new")
            instantiateVars(lAdapter, iProductParameters)
            lAdapter.execute(iUserScriptID, *iActionParameters)
          rescue Exception
            logErr "Error while executing Adapter #{@ProductID}/#{@ToolID}/#{@ProductID}_#{@ToolID}_#{@ScriptID}.rb: #{$!}."
            logErr $!.backtrace.join("\n")
            @TestSuccess = false
          end
        rescue RuntimeError
          logErr "Unable to load the Slave Adapter Slave/Adapters/#{@ProductID}/#{@ToolID}/#{@ProductID}_#{@ToolID}_#{@ScriptID}.rb: #{$!}."
          logErr $!.backtrace.join("\n")
          @TestSuccess = false
        end
      end

    end

  end

end
