# Usage:
# This file is used by WEACEMasterServer.rb.
# Do not call it directly.
#
# Check http://weacemethod.sourceforge.net for details.
#--
# Copyright (c) 2009 - 2011 Muriel Salvan  (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

module WEACE

  module Master
  
    class Server

      module Processes

        class Dev_Release

          include WEACE::Common

          # Error raised when invalid deliverables are generated
          class InvalidDeliverablesError < RuntimeError
          end

          # Error raised when the command generating deliverables issued an error
          class DeliverablesGenerationError < RuntimeError
          end

          # Error raised when the command generating deliverables generated no deliverable
          class NoDeliverableError < RuntimeError
          end

          # Error thrown when the Tasks file is missing
          class MissingTasksFileError < RuntimeError
          end

          # Error thrown when the Tickets file is missing
          class MissingTicketsFileError < RuntimeError
          end

          # Error thrown when regression fails
          class RegressionError < RuntimeError
          end

          # Process the script and get the actions to perform on WEACE Slave Clients
          #
          # Parameters:
          # * *ioSlaveActions* (_SlaveActions_): The slave actions to populate (check WEACEMasterServer.rb for API)
          # * *iAdditionalParameters* (<em>list<String></em>): Additional parameters given that were not parsed by the options parser
          # Return:
          # * _Exception_: An error, or nil in case of success
          def processScript(ioSlaveActions, iAdditionalParameters)
            rError = nil

            # Check for options
            checkVar(:Comment, 'Comment to give to the release')
            checkVar(:ReleaseUser, 'Name of the user releasing')
            checkVar(:BranchName, 'Name of the branch to release from')
            checkVar(:ReleaseVersion, 'Version of the release')
            checkVar(:TasksFileName, 'Name of the file containing Tasks ID')
            checkVar(:TicketsFileName, 'Name of the file containing Tickets ID')
            checkVar(:SVNCOCmd, 'Command line parameters to give "svn co" to checkout this project')
            checkVar(:DeliverCmd, 'Command to execute to generate deliverables')
            # Read files first. Don't try anything if they fail.
            rError = readFiles
            if (rError == nil)
              # Lists of files, Tasks and Tickets have been retrieved
              # Create the directory that will store deliverables
              require 'tmpdir'
              lTempDeliverablesDirName = "#{Dir.tmpdir}/WEACEDeliver_#{Thread.current.object_id}"
              require 'fileutils'
              FileUtils::mkdir_p(lTempDeliverablesDirName)
              rError, lReleaseNotes, lDeliverables = testRegressionAndDeliver(lTempDeliverablesDirName)
              if (rError == nil)
                # Deliver the files for real
                lDeliverables.each do |iPlatformName, iPlatformInfo|
                  iPlatformInfo.each do |iDeliveryType, iFilesList|
                    lDeliveryFilesDir = "#{lTempDeliverablesDirName}/Releases/#{iPlatformName}/#{iDeliveryType}"
                    iFilesList.each do |iFileName|
                      ioSlaveActions.addSlaveAction(
                        Tools::FilesManager, Actions::File_Upload,
                        TransferFile.new("#{lDeliveryFilesDir}/#{iFileName}"), iPlatformName, iDeliveryType, @BranchName, @ReleaseVersion, @ReleaseUser, @Comment
                      )
                    end
                  end
                end
                lReleaseNotesDir = "#{lTempDeliverablesDirName}/ReleaseNotes"
                lReleaseNotes.each do |iReleaseNoteType, iReleaseNoteName|
                  ioSlaveActions.addSlaveAction(
                    Tools::FilesManager, Actions::File_UploadReleaseNote,
                    TransferFile.new("#{lReleaseNotesDir}/#{iReleaseNoteName}.#{iReleaseNoteType}"), iReleaseNoteType, @BranchName, @ReleaseVersion, @ReleaseUser, @Comment
                  )
                end
                # For each Ticket to update, add a release comment
                @LstTickets.each do |iTicketID|
                  ioSlaveActions.addSlaveAction(
                    Tools::TicketTracker, Actions::Ticket_AddReleaseComment,
                    iTicketID, @BranchName, @ReleaseVersion, @ReleaseUser, @Comment
                  )
                end
                # For each Task to update, add a commit comment
                @LstTasks.each do |iTaskID|
                  ioSlaveActions.addSlaveAction(
                    Tools::ProjectManager, Actions::Task_AddReleaseComment,
                    iTaskID, @BranchName, @ReleaseVersion, @ReleaseUser, @Comment
                  )
                end
                # Add a wiki comment
                ioSlaveActions.addSlaveAction(
                  Tools::Wiki, Actions::Wiki_AddReleaseComment,
                  @BranchName, @ReleaseVersion, @ReleaseUser, @Comment
                )
              end
              if (rError == nil)
                FileUtils::rm_rf(lTempDeliverablesDirName)
              else
                logErr "Error encountered while distributing deliverables: #{rError}. Keeping directory #{lTempDeliverablesDirName} for investigation purposes. Feel free to remove it."
              end
            end

            return rError
          end

          # Get the command line options for this Process
          #
          # Return:
          # * _OptionParser_: The corresponding options
          def getOptions
            rOptions = OptionParser.new

            @RegressionCmd = nil
            rOptions.banner = '-v|--version <ReleaseVersion> -u|--user <ReleaseUser> -b|--branch <BranchName> -c|--comment <CommitComment> -t|--tasksfile <TasksFileName> -k|--ticketsfile <TicketsFileName> -s|--svnco <SVNCheckOutCmd> -d|--deliver <DeliverCmd> [-r|--regressioncmd <RegressionCmd>]'
            rOptions.on('-v', '--version <ReleaseVersion>', String,
              '<ReleaseVersion>: Version attributed to this release.') do |iArg|
              @ReleaseVersion = iArg
            end
            rOptions.on('-u', '--user <ReleaseUser>', String,
              '<ReleaseUser>: User that performs the release.') do |iArg|
              @ReleaseUser = iArg
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
            rOptions.on('-s', '--svnco <SVNCheckOutCmd>', String,
              '<SVNCheckOutCmd>: The command line options to give "svn co" command to checkout the project\'s repository.',
              'Specifies the repository to check-out to generate deliverables.') do |iArg|
              @SVNCOCmd = iArg
            end
            rOptions.on('-d', '--deliver <DeliverCmd>', String,
              '<DeliverCmd>: The command line command to execute to generate deliverables. %{DeliverablesDir} string will be replaced by the deliverables directory in the command line.',
              'Specify the command to execute to generate deliverables.') do |iArg|
              @DeliverCmd = iArg
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
          # Return:
          # * _Exception_: An error, or nil in case of success
          def readFiles
            rError = nil

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

            return rError
          end

          # Test regression on the release, and generate deliverables.
          # Returns an error if the regression is failing.
          #
          # Parameters:
          # * *iDeliverablesDir* (_String_): The directory where deliverables must be stored
          # Return:
          # * _Exception_: An error, or nil if success
          # * <em>map<String,String></em>: The release notes files to publish, per type (or nil in case of failure)
          # * <em>map<String,map<String,list<String>>></em>: The deliverables to publish, per platform and type (or nil in case of failure)
          def testRegressionAndDeliver(iDeliverablesDir)
            rError = nil
            rReleaseNotes = nil
            rDeliverables = nil

            # Check out the project in a temporary repository
            lTempRepositoryDirName = "#{Dir.tmpdir}/WEACERegTest_#{Thread.current.object_id}"
            FileUtils::mkdir_p(lTempRepositoryDirName)
            changeDir(lTempRepositoryDirName) do
              # Checkout using svn
              `svn co #{@SVNCOCmd}`
              if (@RegressionCmd != nil)
                # Execute the regression from this repository
                rError = executeRegression(lTempRepositoryDirName)
              end
              if (rError == nil)
                # Generate deliverables
                rError, rReleaseNotes, rDeliverables = generateDeliverables(lTempRepositoryDirName, iDeliverablesDir)
              end
              if (rError == nil)
                # Perfect, we can clean up the temporary directory
                FileUtils::rm_rf(lTempRepositoryDirName)
              else
                logErr "An error occurred when testing regression: #{rError}. Leaving checked-out repository #{lTempRepositoryDirName} for further investigations. Feel free to remove it."
              end
            end

            return rError, rReleaseNotes, rDeliverables
          end

          # Execute the regression from a given repository
          #
          # Parameters:
          # * *iRepositoryDir* (_String_): Repository dir from where we execute the regression
          # Return:
          # * _Exception_: An error, or nil in case of success
          def executeRegression(iRepositoryDir)
            rError = nil

            changeDir(iRepositoryDir) do
              lOutput = `#{@RegressionCmd}`
              lReturnCode = $?.exitstatus
              if (lReturnCode != 0)
                rError = RegressionError.new("Regression failed with error #{lReturnCode}. Output: #{lOutput}")
              end
            end

            return rError
          end

          # Generate deliverables
          #
          # Parameters:
          # * *iRepositoryDir* (_String_): Repository dir of the project
          # * *iDeliverablesDir* (_String_): Directory where deliverables must be put
          # Return:
          # * _Exception_: An error, or nil if success
          # * <em>map<String,String></em>: The release notes files to publish, per type (or nil in case of failure)
          # * <em>map<String,map<String,list<String>>></em>: The deliverables to publish, per platform and type (or nil in case of failure)
          def generateDeliverables(iRepositoryDir, iDeliverablesDir)
            rError = nil
            rReleaseNotes = nil
            rDeliverables = nil

            # Structure of the deliverables directory:
            # * Releases\
            # ** <Platform>\
            # *** <DeliveryType>\
            # **** <Files>
            # * ReleaseNotes\
            # ** <File>.<ReleaseNoteType>

            FileUtils::mkdir_p("#{iDeliverablesDir}/Releases")
            FileUtils::mkdir_p("#{iDeliverablesDir}/ReleaseNotes")
            changeDir(iRepositoryDir) do
              lRealDeliverCmd = @DeliverCmd.gsub("%{DeliverablesDir}", "\"#{iDeliverablesDir}\"")
              lOutput = `#{lRealDeliverCmd}`
              lErrorCode = $?.exitstatus
              if (lErrorCode == 0)
                # Parse generated files
                rDeliverables = {}
                rReleaseNotes = {}
                # Gather errors in a list
                # list< String >
                lLstErrors = []
                # Parse releases
                Dir.glob("#{iDeliverablesDir}/Releases/*") do |iPlatformDirName|
                  if (File.directory?(iPlatformDirName))
                    lPlatformName = File.basename(iPlatformDirName)
                    # Create this platform
                    lPlatformInfo = {}
                    Dir.glob("#{iDeliverablesDir}/Releases/#{lPlatformName}/*") do |iDeliveryDirName|
                      if (File.directory?(iDeliveryDirName))
                        lDeliveryType = File.basename(iDeliveryDirName)
                        # Create this delivery type
                        lFilesList = []
                        Dir.glob("#{iDeliverablesDir}/Releases/#{lPlatformName}/#{lDeliveryType}/*") do |iFileName|
                          if (File.directory?(iFileName))
                            lLstErrors << "#{iFileName} should be a file to be delivered. No directory admitted in #{iDeliverablesDir}/Releases/#{lPlatformName}/#{lDeliveryType} directory."
                          else
                            lFilesList << File.basename(iFileName)
                          end
                        end
                        if (!lFilesList.empty?)
                          lPlatformInfo[lDeliveryType] = lFilesList
                        end
                      else
                        lLstErrors << "#{iDeliveryDirName} should be a delivery directory. No file admitted in #{iDeliverablesDir}/Releases/#{lPlatformName} directory."
                      end
                    end
                    if (!lPlatformInfo.empty?)
                      rDeliverables[lPlatformName] = lPlatformInfo
                    end
                  else
                    lLstErrors << "#{iPlatformDirName} should be a platform directory. No file admitted in #{iDeliverablesDir}/Releases directory."
                  end
                end
                # Parse release notes
                Dir.glob("#{iDeliverablesDir}/ReleaseNotes/*") do |iReleaseNoteFileName|
                  if (File.directory?(iReleaseNoteFileName))
                    lLstErrors << "#{iReleaseNoteFileName} should be a release note file to be delivered. No directory admitted in #{iDeliverablesDir}/ReleaseNotes directory."
                  else
                    lBaseName = File.basename(iReleaseNoteFileName)
                    lExtName = File.extname(lBaseName)
                    if (lExtName.empty?)
                      lLstErrors << "File #{iReleaseNoteFileName} should be a file named \"<File>.<DeliveryType>\" (such as \"ReleaseNote.html\")."
                    else
                      lReleaseNoteName = lBaseName[0..-lExtName.size-1]
                      lReleaseNoteType = lExtName[1..-1]
                      if (rReleaseNotes[lReleaseNoteType] == nil)
                        rReleaseNotes[lReleaseNoteType] = lReleaseNoteName
                      else
                        lLstErrors << "There are several release notes of type #{lReleaseNoteType}: #{lReleaseNoteName} and #{rReleaseNotes[lReleaseNoteType]}. Only 1 release note per type is allowed."
                      end
                    end
                  end
                end
                # Check errors
                if (!lLstErrors.empty?)
                  rError = InvalidDeliverablesError.new("Invalid deliverables generated by command \"#{lRealDeliverCmd}\": #{lLstErrors.join(', ')}")
                  rDeliverables = nil
                  rReleaseNotes = nil
                elsif (rDeliverables.empty?)
                  rError = NoDeliverableError.new("No deliverables were generated by command \"#{lRealDeliverCmd}\".")
                  rDeliverables = nil
                  rReleaseNotes = nil
                end
              else
                rError = DeliverablesGenerationError.new("Error while generating deliverables: command \"#{lRealDeliverCmd}\" returned code #{lErrorCode}. Here is its output: #{lOutput}")
              end
            end

            return rError, rReleaseNotes, rDeliverables
          end

        end

      end
    
    end

  end

end
