#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

require 'tmpdir'
require 'fileutils'
require 'bin/WEACEInstall'

module WEACE

  module Test

    module Common

      # Initialization of every test case.
      # This method can then be used in setup or in single execution methods.
      # It ensures that logging mechanism will be correctly initialized and finalized
      #
      # Parameters:
      # * _CodeBlock_: Code executed once the test case has been initialized
      def initTestCase
        # The possible variables replaced in regression test files (command lines, repositories...)
        #   map< Symbol, Object >
        @ContextVars = {}
        # Mute any output except for terminal output.
        setLogErrorsStack([])
        setLogMessagesStack([])
        # Clear variables set in tests
        $Variables = {}

        begin
          yield
        rescue Exception
          setLogFile(nil)
          raise
        end
        setLogFile(nil)
      end

      # Replace variables that can be used in lines of test files.
      # Use @ContextVars to decide which variables to replace.
      # Replace alse '%%' with '%'
      # Don't replace anything if @ContextVars is not defined.
      #
      # Parameters:
      # * *iLine* (_String_): The line containing variables
      # Return:
      # * _String_: The line with variables replaced
      def replaceVars(iLine)
        rResult = iLine.clone

        if (defined?(@ContextVars))
          @ContextVars.each do |iVariable, iValue|
            rResult.gsub!("%{#{iVariable}}", iValue)
          end
          rResult.gsub!('%%', '%')
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

      # Create a temporary directory as a copy of another directory, and ensure it will be deleted after some code has been executed.
      # The temporary directory is not the exact image of the source one: files can be altered by using @ContextVars.
      #
      # Parameters:
      # * *iSrcDir* (_String_): Source directory to copy from
      # * *iBaseName* (_String_): Name to be used in the temporary directory [optional = nil]
      # * _CodeBlock_: The code called once the temporary has been created:
      # ** *iTmpDir* (_String_): Name of the temporary directory, image of the source one.
      def setupTmpDir(iSrcDir, iBaseName = nil)
        # Find a good temporary directory name
        lTmpDir = nil
        if (!defined?(@@UniqueCounter))
          @@UniqueCounter = 0
        end
        if (iBaseName == nil)
          lTmpDir = "#{Dir.tmpdir}/WEACERegression/Dir_#{@@UniqueCounter}"
        else
          lTmpDir = "#{Dir.tmpdir}/WEACERegression/#{iBaseName}_#{@@UniqueCounter}"
        end
        @@UniqueCounter += 1
        # Copy the directories
        logDebug "-> Create image of #{iSrcDir} in #{lTmpDir}"
        # Clean first if already present
        if (File.exists?(lTmpDir))
          FileUtils::rm_rf(lTmpDir)
        end
        copyDir(iSrcDir, lTmpDir)
        # Call the code (protected)
        begin
          yield(lTmpDir)
        ensure
          # Delete the temporary directory
          FileUtils::rm_rf(lTmpDir)
        end
      end

    end

  end

end
