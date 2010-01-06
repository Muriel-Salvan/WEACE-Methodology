# Usage: This file is used by other files.
# Do not call it directly.
#
# Check http://weacemethod.sourceforge.net for details.
#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

module WEACE

  # This module contains every tool needed for test cases
  module Test

    module Install

      module Adapters

        include WEACE::Test::Install::Common

        include WEACE::Toolbox

        class DummyProviderEnv

          attr_accessor :ProviderType
          attr_accessor :CGIURL

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
                logErr "Files #{iFile1} and #{iFile2} differ on line #{iIdx}:\n'#{lContent1[iIdx]}'\nshould be\n'#{lReference}'."
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

        # Setup each test
        def setup
          @Type, @ProductID, @ToolID, @ScriptID, @TestName, @InstallTest = getTestDetails
          @ComponentName = "#{@Type}/Adapter/#{@ProductID}/#{@ToolID}/#{@ScriptID}"
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
        def setupRepository(iRepositoryName)
          if ((defined?(@ProductRepositoryDir)) and
              (@ProductRepositoryDir != nil))
            logErr "A repository has already been setup in this test case: #{@ProductRepositoryDir}. You can not cascade repository setups."
            raise RuntimeError, "A repository has already been setup in this test case: #{@ProductRepositoryDir}. You can not cascade repository setups."
          end
          if (@InstallTest)
            @RepositoriesDir = "#{$WEACETestBaseDir}/Install/#{@Type}/Adapters/#{@ProductID}/#{@ToolID}/#{@ScriptID}"
          else
            @RepositoriesDir = "#{$WEACETestBaseDir}/#{@Type}/Adapters/#{@ProductID}/#{@ToolID}/#{@ScriptID}"
          end
          setupTmpDir("#{@RepositoriesDir}/#{iRepositoryName}", @ProductID) do |iTmpDir|
            @ProductRepositoryDir = iTmpDir
            @ContextVars['Repository'] = @ProductRepositoryDir
            yield
            @ProductRepositoryDir = nil
          end
        end

        # Compare the current repository with a reference repository
        #
        # Parameters:
        # * *iRepositoryName* (_String_): Name of the repository to use as a reference.
        def compareWithRepository(iRepositoryName)
          if ((!defined?(@ProductRepositoryDir)) or
              (@ProductRepositoryDir == nil))
            logErr "You must first setup a repository using 'setupRepository' before calling 'compareWithRepository'."
            raise RuntimeError, "You must first setup a repository using 'setupRepository' before calling 'compareWithRepository'."
          end
          logDebug "Compare repositories for component #{@ComponentName} with reference #{iRepositoryName}"
          @TestSuccess = compareDirs(@ProductRepositoryDir, "#{@RepositoriesDir}/#{iRepositoryName}")
        end

        # Execute the WEACEInstall script with some given parameters, and check its error.
        # This is used with the current Adapter being tested.
        #
        # Parmeters:
        # * *iParameters* (<em>list<String></em>): The parameters to give the Adapter's installer
        # * *iOptions* (<em>map<Symbol,Object></em>): Additional options: [optional = {}]
        # ** *:Error* (_class_): The error class the installer is supposed to return [optional = nil]
        # ** *:Repository* (_String_): Name of the repository to be used [optional = 'MasterServerInstalled' or 'SlaveClientInstalled']
        # ** *:ProductRepository* (_String_): Name of the Product repository to use [optional = nil]
        # * _CodeBlock_: The code called once the installer was run: [optional = nil]
        # ** *iError* (_Exception_): The error returned by the installer, or nil in case of success
        def executeInstallAdapter(iParameters, iOptions = {}, &iCheckCode)
          # Parse options
          lExpectedError = iOptions[:Error]
          lRepositoryName = iOptions[:Repository]
          if (lRepositoryName == nil)
            # By default, make the main component installed, otherwise it will always fail with MasterServer/SlaveClient not being installed.
            if (@Type == 'Master')
              lRepositoryName = 'MasterServerInstalled'
            else
              lRepositoryName = 'SlaveClientInstalled'
            end
          end
          lProductRepositoryName = iOptions[:ProductRepository]

          # Initialize the Installer
          initInstaller(
            :Repository => lRepositoryName,
            # Always add the Providers, as otherwise it can't retrieve the Provider's config.
            :AddRegressionMasterProviders => (@Type == 'Master'),
            :AddRegressionSlaveProviders => (@Type == 'Slave')
          ) do
            # Setup the Product repository
            setupRepository(lProductRepositoryName) do
              # Replace variables in the parameters
              lReplacedParameters = []
              iParameters.each do |iParam|
                lReplacedParameters << replaceVars(iParam)
              end
              execInstaller([ '--install', "#{@Type}/Adapters/#{@ProductID}/#{@ToolID}/#{@ScriptID}", '--' ] + lReplacedParameters,
                :Error => lExpectedError
              ) do |iError|
                if (iCheckCode != nil)
                  iCheckCode.call(iError)
                end
              end
            end
          end
        end

      end

    end

  end

end
