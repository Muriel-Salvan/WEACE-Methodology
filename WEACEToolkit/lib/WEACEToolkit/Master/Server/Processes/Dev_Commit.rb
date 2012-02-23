# Usage:
# This file is used by WEACEMasterServer.rb.
# Do not call it directly.
#
# Check http://weacemethod.sourceforge.net for details.
#--
# Copyright (c) 2009 - 2012 Muriel Salvan  (muriel@x-aeon.com)
# Licensed under BSD LICENSE. No warranty is provided.
#++

module WEACE

  module Master
  
    class Server

      module Processes

        class Dev_Commit

          include WEACE::Common

          # Error thrown when the Files file is missing
          class MissingFilesFileError < RuntimeError
          end

          # Error thrown when the Tasks file is missing
          class MissingTasksFileError < RuntimeError
          end

          # Error thrown when the Tickets file is missing
          class MissingTicketsFileError < RuntimeError
          end

          # Error thrown when the Local Repository is missing
          class MissingLocalRepositoryError < RuntimeError
          end

          # Error thrown when update has a conflict
          class UpdateConflictError < RuntimeError
          end

          # Error thrown when commit has a conflict
          class CommitConflictError < RuntimeError
          end

          # Error thrown when commit has an invalid output
          class CommitInvalidError < RuntimeError
          end

          # Error thrown when regression fails
          class RegressionError < RuntimeError
          end

          # Process the script and get the actions to perform on WEACE Slave Clients
          #
          # Parameters::
          # * *ioSlaveActions* (_SlaveActions_): The slave actions to populate (check WEACEMasterServer.rb for API)
          # * *iAdditionalParameters* (<em>list<String></em>): Additional parameters given that were not parsed by the options parser
          # Return::
          # * _Exception_: An error, or nil in case of success
          def processScript(ioSlaveActions, iAdditionalParameters)
            rError = nil

            # Check for options
            checkVar(:Comment, 'Comment to give to the commit')
            checkVar(:CommitUser, 'Name of the user committing')
            checkVar(:BranchName, 'Name of the branch to commit on')
            checkVar(:TasksFileName, 'Name of the file containing Tasks ID')
            checkVar(:TicketsFileName, 'Name of the file containing Tickets ID')
            checkVar(:LocalRepository, 'Path to the local repository containing files to commit')
            if ((@FilesFileName != nil) and
                (@RegressionCmd != nil))
              checkVar(:SVNCOCmd, 'Command line parameters to give "svn co"')
            end
            # Read files first. Don't try anything if they fail.
            rError = readFiles
            if (rError == nil)
              # Lists of files, Tasks and Tickets have been retrieved
              rError = updateAndCheckConflicts
              if (rError == nil)
                if (@RegressionCmd != nil)
                  rError = testCommitAgainstRegression
                end
                if (rError == nil)
                  rError, lCommitID = commit
                  if (rError == nil)
                    # For each Ticket to update, add a commit comment
                    @LstTickets.each do |iTicketID|
                      ioSlaveActions.addSlaveAction(
                        Tools::TicketTracker, Actions::Ticket_AddCommitComment,
                        iTicketID, @BranchName, lCommitID, @CommitUser, @Comment
                      )
                    end
                    # For each Task to update, add a commit comment
                    @LstTasks.each do |iTaskID|
                      ioSlaveActions.addSlaveAction(
                        Tools::ProjectManager, Actions::Task_AddCommitComment,
                        iTaskID, @BranchName, lCommitID, @CommitUser, @Comment
                      )
                    end
                    ioSlaveActions.addSlaveAction(
                      Tools::Wiki, Actions::Wiki_AddCommitComment,
                      @BranchName, lCommitID, @CommitUser, @Comment
                    )
                  end
                end
              end
            end

            return rError
          end

          # Get the command line options for this Process
          #
          # Return::
          # * _OptionParser_: The corresponding options
          def getOptions
            rOptions = OptionParser.new

            @RegressionCmd = nil
            @FilesFileName = nil
            @CommitPassword = nil
            rOptions.banner = '-u|--user <CommitUser> [-p|--password <CommitPassword>] -b|--branch <BranchName> -c|--comment <CommitComment> -t|--tasksfile <TasksFileName> -k|--ticketsfile <TicketsFileName> -l|--local <LocalRepository> [-f|--filesfile <FilesFileName> -s|--svnco <SVNCheckOutCmd>] [-r|--regressioncmd <RegressionCmd>]'
            rOptions.on('-u', '--user <CommitUser>', String,
              '<CommitUser>: User that performs the commit.') do |iArg|
              @CommitUser = iArg
            end
            rOptions.on('-p', '--password <CommitPassword>', String,
              '<CommitPassword>: Password of the commit user.') do |iArg|
              @CommitPassword = iArg
            end
            rOptions.on('-b', '--branch <BranchName>', String,
              '<BranchName>: Name of the branch to commit on.') do |iArg|
              @BranchName = iArg
            end
            rOptions.on('-c', '--comment <CommitComment>', String,
              '<CommitComment>: Comment to associate to the commit.') do |iArg|
              @Comment = iArg
            end
            rOptions.on('-t', '--tasksfile <TasksFileName>', String,
              '<TasksFileName>: Name of the file containing Tasks IDs to update (1 Task ID per line).') do |iArg|
              @TasksFileName = iArg
            end
            rOptions.on('-k', '--ticketsfile <TicketsFileName>', String,
              '<TicketsFileName>: Name of the file containing Tickets IDs to update (1 Ticket ID per line).') do |iArg|
              @TicketsFileName = iArg
            end
            rOptions.on('-f', '--filesfile <FilesFileName>', String,
              '<FilesFileName>: Name of the file containing file names to commit (1 file name per line, relative to the SVN root).',
              'If not specified, all files will be committed.') do |iArg|
              @FilesFileName = iArg
            end
            rOptions.on('-l', '--local <LocalRepository>', String,
              '<LocalRepository>: Path to the local SVN checkout repository. This is where we will be fetching files to commit.') do |iArg|
              @LocalRepository = iArg
            end
            rOptions.on('-s', '--svnco <SVNCheckOutCmd>', String,
              '<SVNCheckOutCmd>: The command line options to give "svn co" command to checkout the project\'s repository.',
              'Used only if specific files list is given using --filesfile parameter and --regressioncmd has been specified.') do |iArg|
              @SVNCOCmd = iArg
            end
            rOptions.on('-r', '--regressioncmd <RegressionCmd>', String,
              '<RegressionCmd>: The command to launch from the repository root to test for the regression. Return code will tell about the regression validation (0=success).') do |iArg|
              @RegressionCmd = iArg
            end

            return rOptions
          end

          private

          # Read files given as parameters, containing lists of files, Tasks and Tickets.
          #
          # Return::
          # * _Exception_: An error, or nil in case of success
          def readFiles
            rError = nil

            # Check the repository
            if (File.exists?(@LocalRepository))
              @LstFiles = nil
              if (@FilesFileName != nil)
                if (File.exists?(@FilesFileName))
                  File.open(@FilesFileName, 'r') do |iFile|
                    @LstFiles = iFile.readlines.map do |iLine|
                      next iLine.strip
                    end
                  end
                else
                  rError = MissingFilesFileError.new("Missing Files file: #{@FilesFileName}")
                end
              end
              if (rError == nil)
                # Construct the files list as seen on the command line
                @StrFiles = ''
                if (@LstFiles != nil)
                  @LstFiles.each do |iFileName|
                    if (iFileName.include?(' '))
                      @StrFiles += " \"#{iFileName}\""
                    else
                      @StrFiles += " #{iFileName}"
                    end
                  end
                end
                if (File.exists?(@TasksFileName))
                  @LstTasks = nil
                  File.open(@TasksFileName, 'r') do |iFile|
                    @LstTasks = iFile.readlines.map do |iLine|
                      next iLine.strip
                    end
                  end
                  if (File.exists?(@TicketsFileName))
                    @LstTickets = nil
                    File.open(@TicketsFileName, 'r') do |iFile|
                      @LstTickets = iFile.readlines.map do |iLine|
                        next iLine.strip
                      end
                    end
                  else
                    rError = MissingTicketsFileError.new("Missing Tickets file: #{@TicketsFileName}")
                  end
                else
                  rError = MissingTasksFileError.new("Missing Tasks file: #{@TasksFileName}")
                end
              end
            else
              rError = MissingLocalRepositoryError.new("Missing local repository: #{@LocalRepository}")
            end

            return rError
          end

          # Update the local repository files and checks for conflicts doing so.
          #
          # Return::
          # * _Exception_: An error, or nil if success and no conflict
          def updateAndCheckConflicts
            rError = nil

            lConflicts = []
            # Execute svn update
            change_dir(@LocalRepository) do
              `svn update --accept=postpone #{@StrFiles}`.split("\n").each do |iLine|
                # Check that this line does not tell about a conflict
                if (iLine.strip[0..0] == 'C')
                  # There is a conflict
                  lConflicts << iLine.strip[1..-1].strip
                end
              end
            end
            # Sum up conflicts
            if (!lConflicts.empty?)
              rError = UpdateConflictError.new("The following files are in conflict: #{lConflicts.join(', ')}. Please resolve the conflict by updating before committing.")
            end

            return rError
          end

          # Test that the files we want to commit will not break the regression.
          # Returns an error if the regression is failing.
          #
          # Return::
          # * _Exception_: An error, or nil if success
          def testCommitAgainstRegression
            rError = nil

            # If we commit all files, no need to checkout in a different repository
            if (@LstFiles == nil)
              rError = executeRegression(@LocalRepository)
            else
              # Check out the project in a temporary repository
              require 'tmpdir'
              lTempRepositoryDirName = "#{Dir.tmpdir}/WEACERegTest_#{Thread.current.object_id}"
              require 'fileutils'
              FileUtils::mkdir_p(lTempRepositoryDirName)
              change_dir(lTempRepositoryDirName) do
                # Checkout using svn
                `svn co #{@SVNCOCmd}`
                # Now replace the files we want with the ones from the local repository
                @LstFiles.each do |iFileName|
                  lSrcFileName = "#{@LocalRepository}/#{iFileName}"
                  lDstFileName = "#{lTempRepositoryDirName}/#{iFileName}"
                  if (File.exists?(lSrcFileName))
                    FileUtils::cp(lSrcFileName, lDstFileName)
                  elsif (File.exists?(lDstFileName))
                    FileUtils::rm(lDstFileName)
                  end
                end
                # Execute the regression from this repository
                rError = executeRegression(lTempRepositoryDirName)
              end
              if (rError == nil)
                # Perfect, we can clean up the temporary directory
                FileUtils::rm_rf(lTempRepositoryDirName)
              else
                log_err "An error occurred when testing regression: #{rError}. Leaving checked-out repository #{lTempRepositoryDirName} for further investigations. Feel free to remove it."
              end
            end

            return rError
          end

          # Execute the regression from a given repository
          #
          # Parameters::
          # * *iRepositoryDir* (_String_): Repository dir from where we execute the regression
          # Return::
          # * _Exception_: An error, or nil in case of success
          def executeRegression(iRepositoryDir)
            rError = nil

            change_dir(iRepositoryDir) do
              lOutput = `#{@RegressionCmd}`
              lReturnCode = $?.exitstatus
              if (lReturnCode != 0)
                rError = RegressionError.new("Regression failed with error #{lReturnCode}. Output: #{lOutput}")
              end
            end

            return rError
          end

          # Commit
          #
          # Return::
          # * _Exception_: An error, or nil if success
          # * _Integer_: The commit ID, to be used for future references
          def commit
            rError = nil
            rCommitID = nil

            lStrPassword = ''
            if (@CommitPassword != nil)
              lStrPassword = "--password #{@CommitPassword}"
            end
            change_dir(@LocalRepository) do
              lOutput = `svn ci --message "#{@Comment}" --username #{@CommitUser} #{lStrPassword} #{@StrFiles}`.split("\n")
              lReturnCode = $?.exitstatus
              if (lReturnCode == 0)
                # Get back the revision number from the output
                lOutput.each do |iLine|
                  lMatch = iLine.match(/^Committed revision (.*)\.$/)
                  if (lMatch != nil)
                    rCommitID = lMatch[1].to_i
                  end
                end
                if ((rCommitID == nil) or
                    (rCommitID == 0))
                  rError = CommitInvalidError.new("Failed to retrieve SVN commit revision. Here is the output: #{lOutput}")
                end
              else
                rError = CommitConflictError.new("SVN returned error #{lReturnCode} upon commit.")
              end
            end

            return rError, rCommitID
          end

        end

      end
    
    end

  end

end
