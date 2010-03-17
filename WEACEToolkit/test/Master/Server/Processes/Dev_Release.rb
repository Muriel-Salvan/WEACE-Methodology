#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  # Define class exceptions here as they have to be known before requiring the plugin
  module Master

    class TransferFile

      # Define a comparison operator, as it will be useful for comparing SlaveActions
      #
      # Parameters:
      # * *iOther* (_TransferFile_): The other to compare with
      def ==(iOther)
        if (iOther.is_a?(TransferFile))
          return (@LocalFileName == iOther.LocalFileName)
        else
          return false
        end
      end

    end

    class Server

      module Processes

        class Dev_Release

          class InvalidDeliverablesError < RuntimeError
          end

          class DeliverablesGenerationError < RuntimeError
          end

          class NoDeliverableError < RuntimeError
          end
          
          class MissingTasksFileError < RuntimeError
          end

          class MissingTicketsFileError < RuntimeError
          end

          class RegressionError < RuntimeError
          end

        end

      end

    end

  end
  
  module Test

    module Master

      module Processes

        class Dev_Release < ::Test::Unit::TestCase
          
          include WEACE::Test::Master::Common

          # Setup test cases
          def setup
            # Define common constants that need this class' context if not already done
            if (defined?(@@CommonSlaveActions) == nil)
              # Common Slave Actions: these Actions will always be present in standard test cases.
              @@CommonSlaveActions = {
                Tools::TicketTracker => {
                  Actions::Ticket_AddReleaseComment => [
                    [ 'TicketID 1', 'BranchName', '0.0.1.20100317', 'ReleaseUser', 'ReleaseComment' ],
                    [ 'TicketID 2', 'BranchName', '0.0.1.20100317', 'ReleaseUser', 'ReleaseComment' ],
                    [ 'TicketID 3', 'BranchName', '0.0.1.20100317', 'ReleaseUser', 'ReleaseComment' ]
                  ]
                },
                Tools::ProjectManager => {
                  Actions::Task_AddReleaseComment => [
                    [ 'TaskID 1', 'BranchName', '0.0.1.20100317', 'ReleaseUser', 'ReleaseComment' ],
                    [ 'TaskID 2', 'BranchName', '0.0.1.20100317', 'ReleaseUser', 'ReleaseComment' ],
                    [ 'TaskID 3', 'BranchName', '0.0.1.20100317', 'ReleaseUser', 'ReleaseComment' ]
                  ]
                },
                Tools::Wiki => {
                  Actions::Wiki_AddReleaseComment => [
                    [ 'BranchName', '0.0.1.20100317', 'ReleaseUser', 'ReleaseComment' ]
                  ]
                }
              }
              # Generator used for 2 dummy gems
              @@Generator_2DummyGems = Proc.new do |iCommand|
                # Get the deliverable dir
                lMatch = iCommand.match(/^deliver "(.*)"$/)
                assert(lMatch != nil)
                lDeliverableDir = lMatch[1]
                $Variables[:DeliverableDir] = lDeliverableDir
                # Create dummy deliverables
                FileUtils::mkdir_p("#{lDeliverableDir}/Releases/All/Gem")
                File.open("#{lDeliverableDir}/Releases/All/Gem/DummyGem1.gem", 'w') do |oFile|
                  oFile << 'DummyGemContent1'
                end
                File.open("#{lDeliverableDir}/Releases/All/Gem/DummyGem2.gem", 'w') do |oFile|
                  oFile << 'DummyGemContent2'
                end
              end
              # Generator used for a dummy gem and another deliverable type
              @@Generator_DummyGemAndOther = Proc.new do |iCommand|
                # Get the deliverable dir
                lMatch = iCommand.match(/^deliver "(.*)"$/)
                assert(lMatch != nil)
                lDeliverableDir = lMatch[1]
                $Variables[:DeliverableDir] = lDeliverableDir
                # Create dummy deliverables
                FileUtils::mkdir_p("#{lDeliverableDir}/Releases/All/Gem")
                FileUtils::mkdir_p("#{lDeliverableDir}/Releases/All/Other")
                File.open("#{lDeliverableDir}/Releases/All/Gem/DummyGem.gem", 'w') do |oFile|
                  oFile << 'DummyGemContent'
                end
                File.open("#{lDeliverableDir}/Releases/All/Other/DummyOtherFile", 'w') do |oFile|
                  oFile << 'DummyOtherFile'
                end
              end
              # Generator used for a dummy gem and another platform release
              @@Generator_DummyGemAndWindows = Proc.new do |iCommand|
                # Get the deliverable dir
                lMatch = iCommand.match(/^deliver "(.*)"$/)
                assert(lMatch != nil)
                lDeliverableDir = lMatch[1]
                $Variables[:DeliverableDir] = lDeliverableDir
                # Create dummy deliverables
                FileUtils::mkdir_p("#{lDeliverableDir}/Releases/All/Gem")
                FileUtils::mkdir_p("#{lDeliverableDir}/Releases/Windows/Inst")
                File.open("#{lDeliverableDir}/Releases/All/Gem/DummyGem.gem", 'w') do |oFile|
                  oFile << 'DummyGemContent'
                end
                File.open("#{lDeliverableDir}/Releases/Windows/Inst/Install.exe", 'w') do |oFile|
                  oFile << 'DummyWindowsInstaller'
                end
              end
              # Generator used for a single dummy gem
              @@Generator_SingleDummyGem = Proc.new do |iCommand|
                # Get the deliverable dir
                lMatch = iCommand.match(/^deliver "(.*)"$/)
                assert(lMatch != nil)
                lDeliverableDir = lMatch[1]
                $Variables[:DeliverableDir] = lDeliverableDir
                # Create dummy deliverables
                FileUtils::mkdir_p("#{lDeliverableDir}/Releases/All/Gem")
                File.open("#{lDeliverableDir}/Releases/All/Gem/DummyGem.gem", 'w') do |oFile|
                  oFile << 'DummyGemContent'
                end
              end
              # Generator used for a single dummy gem with its Release Note
              @@Generator_SingleDummyGemWithRN = Proc.new do |iCommand|
                # Get the deliverable dir
                lMatch = iCommand.match(/^deliver "(.*)"$/)
                assert(lMatch != nil)
                lDeliverableDir = lMatch[1]
                $Variables[:DeliverableDir] = lDeliverableDir
                # Create dummy deliverables
                FileUtils::mkdir_p("#{lDeliverableDir}/Releases/All/Gem")
                File.open("#{lDeliverableDir}/Releases/All/Gem/DummyGem.gem", 'w') do |oFile|
                  oFile << 'DummyGemContent'
                end
                File.open("#{lDeliverableDir}/ReleaseNotes/DummyGemReleaseNote.html", 'w') do |oFile|
                  oFile << 'DummyGemReleaseNote in html'
                end
              end
              # Generator used for a single dummy gem with several Release Notes
              @@Generator_SingleDummyGemWithSeveralRN = Proc.new do |iCommand|
                # Get the deliverable dir
                lMatch = iCommand.match(/^deliver "(.*)"$/)
                assert(lMatch != nil)
                lDeliverableDir = lMatch[1]
                $Variables[:DeliverableDir] = lDeliverableDir
                # Create dummy deliverables
                FileUtils::mkdir_p("#{lDeliverableDir}/Releases/All/Gem")
                File.open("#{lDeliverableDir}/Releases/All/Gem/DummyGem.gem", 'w') do |oFile|
                  oFile << 'DummyGemContent'
                end
                File.open("#{lDeliverableDir}/ReleaseNotes/DummyGemReleaseNote.html", 'w') do |oFile|
                  oFile << 'DummyGemReleaseNote in html'
                end
                File.open("#{lDeliverableDir}/ReleaseNotes/DummyGemReleaseNote.txt", 'w') do |oFile|
                  oFile << 'DummyGemReleaseNote in txt'
                end
              end
              # Generator used for an invalid deliverable
              @@Generator_Invalid = Proc.new do |iCommand|
                # Get the deliverable dir
                lMatch = iCommand.match(/^deliver "(.*)"$/)
                assert(lMatch != nil)
                lDeliverableDir = lMatch[1]
                $Variables[:DeliverableDir] = lDeliverableDir
                # Create dummy deliverables
                FileUtils::mkdir_p("#{lDeliverableDir}/Releases/All/Gem/InvalidDir")
              end
              # Generator used for an invalid RN
              @@Generator_InvalidRN = Proc.new do |iCommand|
                # Get the deliverable dir
                lMatch = iCommand.match(/^deliver "(.*)"$/)
                assert(lMatch != nil)
                lDeliverableDir = lMatch[1]
                $Variables[:DeliverableDir] = lDeliverableDir
                # Create dummy deliverables
                FileUtils::mkdir_p("#{lDeliverableDir}/Releases/All/Gem")
                File.open("#{lDeliverableDir}/Releases/All/Gem/DummyGem.gem", 'w') do |oFile|
                  oFile << 'DummyGemContent'
                end
                File.open("#{lDeliverableDir}/ReleaseNotes/InvalidReleaseNote", 'w') do |oFile|
                  oFile << 'InvalidReleaseNote content'
                end
              end
              # Generator used for a duplicate RN
              @@Generator_DuplicateRN = Proc.new do |iCommand|
                # Get the deliverable dir
                lMatch = iCommand.match(/^deliver "(.*)"$/)
                assert(lMatch != nil)
                lDeliverableDir = lMatch[1]
                $Variables[:DeliverableDir] = lDeliverableDir
                # Create dummy deliverables
                FileUtils::mkdir_p("#{lDeliverableDir}/Releases/All/Gem")
                File.open("#{lDeliverableDir}/Releases/All/Gem/DummyGem.gem", 'w') do |oFile|
                  oFile << 'DummyGemContent'
                end
                File.open("#{lDeliverableDir}/ReleaseNotes/ReleaseNote1.txt", 'w') do |oFile|
                  oFile << 'ReleaseNote 1 in txt'
                end
                File.open("#{lDeliverableDir}/ReleaseNotes/ReleaseNote2.txt", 'w') do |oFile|
                  oFile << 'ReleaseNote 2 in txt'
                end
              end
            end
          end

          # Test that getOptions return something correct
          def testGetOptions
            accessProcessPlugin do |iProcessPlugin|
              lProcessOptions = iProcessPlugin.getOptions
              assert(lProcessOptions.kind_of?(OptionParser))
            end
          end

          # Test a case were deliver does not produce any deliverable
          def testNoDeliverable
            setupTest do |iTasksFileName, iTicketsFileName|
              $Context[:OS_ExecAnswers] = [
                # svn co => success
                [ 0, '' ],
                # deliver => success, but no deliverable
                [ 0, '' ]
              ]
              executeProcess(
                [
                  '--user', 'ReleaseUser',
                  '--branch', 'BranchName',
                  '--comment', 'ReleaseComment',
                  '--version', '0.0.1.20100317',
                  '--tasksfile', iTasksFileName,
                  '--ticketsfile', iTicketsFileName,
                  '--svnco', 'MySVNRep',
                  '--deliver', 'deliver %{DeliverablesDir}'
                ],
                :Error => WEACE::Master::Server::Processes::Dev_Release::NoDeliverableError
              ) do |iError, iSlaveActions|
                checkCallsMatch(
                  [
                    [ 'query', 'svn co MySVNRep' ],
                    [ 'query', /^deliver .*$/ ]
                  ],
                  $Variables[:OS_Exec]
                )
                assert_equal( {}, iSlaveActions )
              end
            end
          end

          # Test a nominal case
          def testNominal
            setupTest do |iTasksFileName, iTicketsFileName|
              $Context[:OS_ExecAnswers] = [
                # svn co => success
                [ 0, '' ],
                # deliver => success, generating files
                [ 0, '', @@Generator_SingleDummyGem ]
              ]
              executeProcess(
                [
                  '--user', 'ReleaseUser',
                  '--branch', 'BranchName',
                  '--comment', 'ReleaseComment',
                  '--version', '0.0.1.20100317',
                  '--tasksfile', iTasksFileName,
                  '--ticketsfile', iTicketsFileName,
                  '--svnco', 'MySVNRep',
                  '--deliver', 'deliver %{DeliverablesDir}'
                ]
              ) do |iError, iSlaveActions|
                checkCallsMatch(
                  [
                    [ 'query', 'svn co MySVNRep' ],
                    [ 'query', /^deliver .*$/ ]
                  ],
                  $Variables[:OS_Exec]
                )
                assert_equal( @@CommonSlaveActions.merge(
                  {
                    Tools::FilesManager => {
                      Actions::File_Upload => [
                        [ WEACE::Master::TransferFile.new("#{$Variables[:DeliverableDir]}/Releases/All/Gem/DummyGem.gem"), 'All', 'Gem', 'BranchName', '0.0.1.20100317', 'ReleaseUser', 'ReleaseComment' ]
                      ]
                    }
                  } ),
                  iSlaveActions
                )
              end
            end
          end

          # Test a nominal case (short version)
          def testNominalShort
            setupTest do |iTasksFileName, iTicketsFileName|
              $Context[:OS_ExecAnswers] = [
                # svn co => success
                [ 0, '' ],
                # deliver => success, generating files
                [ 0, '', @@Generator_SingleDummyGem ]
              ]
              executeProcess(
                [
                  '-u', 'ReleaseUser',
                  '-b', 'BranchName',
                  '-c', 'ReleaseComment',
                  '-v', '0.0.1.20100317',
                  '-t', iTasksFileName,
                  '-k', iTicketsFileName,
                  '-s', 'MySVNRep',
                  '-d', 'deliver %{DeliverablesDir}'
                ]
              ) do |iError, iSlaveActions|
                checkCallsMatch(
                  [
                    [ 'query', 'svn co MySVNRep' ],
                    [ 'query', /^deliver .*$/ ]
                  ],
                  $Variables[:OS_Exec]
                )
                assert_equal( @@CommonSlaveActions.merge(
                  {
                    Tools::FilesManager => {
                      Actions::File_Upload => [
                        [ WEACE::Master::TransferFile.new("#{$Variables[:DeliverableDir]}/Releases/All/Gem/DummyGem.gem"), 'All', 'Gem', 'BranchName', '0.0.1.20100317', 'ReleaseUser', 'ReleaseComment' ]
                      ]
                    }
                  } ),
                  iSlaveActions
                )
              end
            end
          end

          # Test a nominal case with a release note file
          def testNominalWithRN
            setupTest do |iTasksFileName, iTicketsFileName|
              $Context[:OS_ExecAnswers] = [
                # svn co => success
                [ 0, '' ],
                # deliver => success, generating files
                [ 0, '', @@Generator_SingleDummyGemWithRN ]
              ]
              executeProcess(
                [
                  '--user', 'ReleaseUser',
                  '--branch', 'BranchName',
                  '--comment', 'ReleaseComment',
                  '--version', '0.0.1.20100317',
                  '--tasksfile', iTasksFileName,
                  '--ticketsfile', iTicketsFileName,
                  '--svnco', 'MySVNRep',
                  '--deliver', 'deliver %{DeliverablesDir}'
                ]
              ) do |iError, iSlaveActions|
                checkCallsMatch(
                  [
                    [ 'query', 'svn co MySVNRep' ],
                    [ 'query', /^deliver .*$/ ]
                  ],
                  $Variables[:OS_Exec]
                )
                assert_equal( @@CommonSlaveActions.merge(
                  {
                    Tools::FilesManager => {
                      Actions::File_Upload => [
                        [ WEACE::Master::TransferFile.new("#{$Variables[:DeliverableDir]}/Releases/All/Gem/DummyGem.gem"), 'All', 'Gem', 'BranchName', '0.0.1.20100317', 'ReleaseUser', 'ReleaseComment' ]
                      ],
                      Actions::File_UploadReleaseNote => [
                        [ WEACE::Master::TransferFile.new("#{$Variables[:DeliverableDir]}/ReleaseNotes/DummyGemReleaseNote.html"), 'html', 'BranchName', '0.0.1.20100317', 'ReleaseUser', 'ReleaseComment' ]
                      ]
                    }
                  } ),
                  iSlaveActions
                )
              end
            end
          end

          # Test a nominal case with several release note files
          def testNominalWithSeveralRN
            setupTest do |iTasksFileName, iTicketsFileName|
              $Context[:OS_ExecAnswers] = [
                # svn co => success
                [ 0, '' ],
                # deliver => success, generating files
                [ 0, '', @@Generator_SingleDummyGemWithSeveralRN ]
              ]
              executeProcess(
                [
                  '--user', 'ReleaseUser',
                  '--branch', 'BranchName',
                  '--comment', 'ReleaseComment',
                  '--version', '0.0.1.20100317',
                  '--tasksfile', iTasksFileName,
                  '--ticketsfile', iTicketsFileName,
                  '--svnco', 'MySVNRep',
                  '--deliver', 'deliver %{DeliverablesDir}'
                ]
              ) do |iError, iSlaveActions|
                checkCallsMatch(
                  [
                    [ 'query', 'svn co MySVNRep' ],
                    [ 'query', /^deliver .*$/ ]
                  ],
                  $Variables[:OS_Exec]
                )
                assert_equal( @@CommonSlaveActions.merge(
                  {
                    Tools::FilesManager => {
                      Actions::File_Upload => [
                        [ WEACE::Master::TransferFile.new("#{$Variables[:DeliverableDir]}/Releases/All/Gem/DummyGem.gem"), 'All', 'Gem', 'BranchName', '0.0.1.20100317', 'ReleaseUser', 'ReleaseComment' ]
                      ],
                      Actions::File_UploadReleaseNote => [
                        [ WEACE::Master::TransferFile.new("#{$Variables[:DeliverableDir]}/ReleaseNotes/DummyGemReleaseNote.html"), 'html', 'BranchName', '0.0.1.20100317', 'ReleaseUser', 'ReleaseComment' ],
                        [ WEACE::Master::TransferFile.new("#{$Variables[:DeliverableDir]}/ReleaseNotes/DummyGemReleaseNote.txt"), 'txt', 'BranchName', '0.0.1.20100317', 'ReleaseUser', 'ReleaseComment' ]
                      ]
                    }
                  } ),
                  iSlaveActions
                )
              end
            end
          end

          # Test a nominal case with several deliverables in the same platform and type
          def testNominalWithSeveralDeliverables
            setupTest do |iTasksFileName, iTicketsFileName|
              $Context[:OS_ExecAnswers] = [
                # svn co => success
                [ 0, '' ],
                # deliver => success, generating files
                [ 0, '', @@Generator_2DummyGems ]
              ]
              executeProcess(
                [
                  '--user', 'ReleaseUser',
                  '--branch', 'BranchName',
                  '--comment', 'ReleaseComment',
                  '--version', '0.0.1.20100317',
                  '--tasksfile', iTasksFileName,
                  '--ticketsfile', iTicketsFileName,
                  '--svnco', 'MySVNRep',
                  '--deliver', 'deliver %{DeliverablesDir}'
                ]
              ) do |iError, iSlaveActions|
                checkCallsMatch(
                  [
                    [ 'query', 'svn co MySVNRep' ],
                    [ 'query', /^deliver .*$/ ]
                  ],
                  $Variables[:OS_Exec]
                )
                assert_equal( @@CommonSlaveActions.merge(
                  {
                    Tools::FilesManager => {
                      Actions::File_Upload => [
                        [ WEACE::Master::TransferFile.new("#{$Variables[:DeliverableDir]}/Releases/All/Gem/DummyGem1.gem"), 'All', 'Gem', 'BranchName', '0.0.1.20100317', 'ReleaseUser', 'ReleaseComment' ],
                        [ WEACE::Master::TransferFile.new("#{$Variables[:DeliverableDir]}/Releases/All/Gem/DummyGem2.gem"), 'All', 'Gem', 'BranchName', '0.0.1.20100317', 'ReleaseUser', 'ReleaseComment' ]
                      ]
                    }
                  } ),
                  iSlaveActions
                )
              end
            end
          end

          # Test a nominal case with several deliverables of different types
          def testNominalWithSeveralTypes
            setupTest do |iTasksFileName, iTicketsFileName|
              $Context[:OS_ExecAnswers] = [
                # svn co => success
                [ 0, '' ],
                # deliver => success, generating files
                [ 0, '', @@Generator_DummyGemAndOther ]
              ]
              executeProcess(
                [
                  '--user', 'ReleaseUser',
                  '--branch', 'BranchName',
                  '--comment', 'ReleaseComment',
                  '--version', '0.0.1.20100317',
                  '--tasksfile', iTasksFileName,
                  '--ticketsfile', iTicketsFileName,
                  '--svnco', 'MySVNRep',
                  '--deliver', 'deliver %{DeliverablesDir}'
                ]
              ) do |iError, iSlaveActions|
                checkCallsMatch(
                  [
                    [ 'query', 'svn co MySVNRep' ],
                    [ 'query', /^deliver .*$/ ]
                  ],
                  $Variables[:OS_Exec]
                )
                assert_equal( @@CommonSlaveActions.merge(
                  {
                    Tools::FilesManager => {
                      Actions::File_Upload => [
                        [ WEACE::Master::TransferFile.new("#{$Variables[:DeliverableDir]}/Releases/All/Gem/DummyGem.gem"), 'All', 'Gem', 'BranchName', '0.0.1.20100317', 'ReleaseUser', 'ReleaseComment' ],
                        [ WEACE::Master::TransferFile.new("#{$Variables[:DeliverableDir]}/Releases/All/Other/DummyOtherFile"), 'All', 'Other', 'BranchName', '0.0.1.20100317', 'ReleaseUser', 'ReleaseComment' ]
                      ]
                    }
                  } ),
                  iSlaveActions
                )
              end
            end
          end

          # Test a nominal case with several deliverables of different platforms
          def testNominalWithSeveralPlatforms
            setupTest do |iTasksFileName, iTicketsFileName|
              $Context[:OS_ExecAnswers] = [
                # svn co => success
                [ 0, '' ],
                # deliver => success, generating files
                [ 0, '', @@Generator_DummyGemAndWindows ]
              ]
              executeProcess(
                [
                  '--user', 'ReleaseUser',
                  '--branch', 'BranchName',
                  '--comment', 'ReleaseComment',
                  '--version', '0.0.1.20100317',
                  '--tasksfile', iTasksFileName,
                  '--ticketsfile', iTicketsFileName,
                  '--svnco', 'MySVNRep',
                  '--deliver', 'deliver %{DeliverablesDir}'
                ]
              ) do |iError, iSlaveActions|
                checkCallsMatch(
                  [
                    [ 'query', 'svn co MySVNRep' ],
                    [ 'query', /^deliver .*$/ ]
                  ],
                  $Variables[:OS_Exec]
                )
                assert_equal( @@CommonSlaveActions.merge(
                  {
                    Tools::FilesManager => {
                      Actions::File_Upload => [
                        [ WEACE::Master::TransferFile.new("#{$Variables[:DeliverableDir]}/Releases/All/Gem/DummyGem.gem"), 'All', 'Gem', 'BranchName', '0.0.1.20100317', 'ReleaseUser', 'ReleaseComment' ],
                        [ WEACE::Master::TransferFile.new("#{$Variables[:DeliverableDir]}/Releases/Windows/Inst/Install.exe"), 'Windows', 'Inst', 'BranchName', '0.0.1.20100317', 'ReleaseUser', 'ReleaseComment' ]
                      ]
                    }
                  } ),
                  iSlaveActions
                )
              end
            end
          end

          # Test a nominal case with regression testing
          def testNominalWithRegression
            setupTest do |iTasksFileName, iTicketsFileName|
              $Context[:OS_ExecAnswers] = [
                # svn co => success
                [ 0, '' ],
                # Run regression => success
                [ 0, '' ],
                # deliver => success, generating files
                [ 0, '', @@Generator_SingleDummyGem ]
              ]
              executeProcess(
                [
                  '--user', 'ReleaseUser',
                  '--branch', 'BranchName',
                  '--comment', 'ReleaseComment',
                  '--version', '0.0.1.20100317',
                  '--tasksfile', iTasksFileName,
                  '--ticketsfile', iTicketsFileName,
                  '--svnco', 'MySVNRep',
                  '--deliver', 'deliver %{DeliverablesDir}',
                  '--regressioncmd', 'test/runReg'
                ]
              ) do |iError, iSlaveActions|
                checkCallsMatch(
                  [
                    [ 'query', 'svn co MySVNRep' ],
                    [ 'query', 'test/runReg' ],
                    [ 'query', /^deliver .*$/ ]
                  ],
                  $Variables[:OS_Exec]
                )
                assert_equal( @@CommonSlaveActions.merge(
                  {
                    Tools::FilesManager => {
                      Actions::File_Upload => [
                        [ WEACE::Master::TransferFile.new("#{$Variables[:DeliverableDir]}/Releases/All/Gem/DummyGem.gem"), 'All', 'Gem', 'BranchName', '0.0.1.20100317', 'ReleaseUser', 'ReleaseComment' ]
                      ]
                    }
                  } ),
                  iSlaveActions
                )
              end
            end
          end

          # Test a nominal case with regression testing (short version)
          def testNominalWithRegressionShort
            setupTest do |iTasksFileName, iTicketsFileName|
              $Context[:OS_ExecAnswers] = [
                # svn co => success
                [ 0, '' ],
                # Run regression => success
                [ 0, '' ],
                # deliver => success, generating files
                [ 0, '', @@Generator_SingleDummyGem ]
              ]
              executeProcess(
                [
                  '--user', 'ReleaseUser',
                  '--branch', 'BranchName',
                  '--comment', 'ReleaseComment',
                  '--version', '0.0.1.20100317',
                  '--tasksfile', iTasksFileName,
                  '--ticketsfile', iTicketsFileName,
                  '--svnco', 'MySVNRep',
                  '--deliver', 'deliver %{DeliverablesDir}',
                  '-r', 'test/runReg'
                ]
              ) do |iError, iSlaveActions|
                checkCallsMatch(
                  [
                    [ 'query', 'svn co MySVNRep' ],
                    [ 'query', 'test/runReg' ],
                    [ 'query', /^deliver .*$/ ]
                  ],
                  $Variables[:OS_Exec]
                )
                assert_equal( @@CommonSlaveActions.merge(
                  {
                    Tools::FilesManager => {
                      Actions::File_Upload => [
                        [ WEACE::Master::TransferFile.new("#{$Variables[:DeliverableDir]}/Releases/All/Gem/DummyGem.gem"), 'All', 'Gem', 'BranchName', '0.0.1.20100317', 'ReleaseUser', 'ReleaseComment' ]
                      ]
                    }
                  } ),
                  iSlaveActions
                )
              end
            end
          end

          # Test a nominal case with regression failing
          def testNominalWithRegressionFailed
            setupTest do |iTasksFileName, iTicketsFileName|
              $Context[:OS_ExecAnswers] = [
                # svn co => success
                [ 0, '' ],
                # Run regression => failure
                [ 1, '' ]
              ]
              executeProcess(
                [
                  '--user', 'ReleaseUser',
                  '--branch', 'BranchName',
                  '--comment', 'ReleaseComment',
                  '--version', '0.0.1.20100317',
                  '--tasksfile', iTasksFileName,
                  '--ticketsfile', iTicketsFileName,
                  '--svnco', 'MySVNRep',
                  '--deliver', 'deliver %{DeliverablesDir}',
                  '--regressioncmd', 'test/runReg'
                ],
                :Error => WEACE::Master::Server::Processes::Dev_Release::RegressionError
              )
            end
          end

          # Test missing --user parameter
          def testMissingUser
            setupTest do |iTasksFileName, iTicketsFileName|
              executeProcess(
                [
                  '--branch', 'BranchName',
                  '--comment', 'ReleaseComment',
                  '--version', '0.0.1.20100317',
                  '--tasksfile', iTasksFileName,
                  '--ticketsfile', iTicketsFileName,
                  '--svnco', 'MySVNRep',
                  '--deliver', 'deliver %{DeliverablesDir}'
                ],
                :Error => WEACE::MissingVariableError
              )
            end
          end

          # Test missing --branch parameter
          def testMissingBranch
            setupTest do |iTasksFileName, iTicketsFileName|
              executeProcess(
                [
                  '--user', 'ReleaseUser',
                  '--comment', 'ReleaseComment',
                  '--version', '0.0.1.20100317',
                  '--tasksfile', iTasksFileName,
                  '--ticketsfile', iTicketsFileName,
                  '--svnco', 'MySVNRep',
                  '--deliver', 'deliver %{DeliverablesDir}'
                ],
                :Error => WEACE::MissingVariableError
              )
            end
          end

          # Test missing --comment parameter
          def testMissingComment
            setupTest do |iTasksFileName, iTicketsFileName|
              executeProcess(
                [
                  '--user', 'ReleaseUser',
                  '--branch', 'BranchName',
                  '--version', '0.0.1.20100317',
                  '--tasksfile', iTasksFileName,
                  '--ticketsfile', iTicketsFileName,
                  '--svnco', 'MySVNRep',
                  '--deliver', 'deliver %{DeliverablesDir}'
                ],
                :Error => WEACE::MissingVariableError
              )
            end
          end

          # Test missing --version parameter
          def testMissingVersion
            setupTest do |iTasksFileName, iTicketsFileName|
              executeProcess(
                [
                  '--user', 'ReleaseUser',
                  '--branch', 'BranchName',
                  '--comment', 'ReleaseComment',
                  '--tasksfile', iTasksFileName,
                  '--ticketsfile', iTicketsFileName,
                  '--svnco', 'MySVNRep',
                  '--deliver', 'deliver %{DeliverablesDir}'
                ],
                :Error => WEACE::MissingVariableError
              )
            end
          end

          # Test missing --tasksfile parameter
          def testMissingTasks
            setupTest do |iTasksFileName, iTicketsFileName|
              executeProcess(
                [
                  '--user', 'ReleaseUser',
                  '--branch', 'BranchName',
                  '--comment', 'ReleaseComment',
                  '--version', '0.0.1.20100317',
                  '--ticketsfile', iTicketsFileName,
                  '--svnco', 'MySVNRep',
                  '--deliver', 'deliver %{DeliverablesDir}'
                ],
                :Error => WEACE::MissingVariableError
              )
            end
          end

          # Test missing --ticketsfile parameter
          def testMissingTickets
            setupTest do |iTasksFileName, iTicketsFileName|
              executeProcess(
                [
                  '--user', 'ReleaseUser',
                  '--branch', 'BranchName',
                  '--comment', 'ReleaseComment',
                  '--version', '0.0.1.20100317',
                  '--tasksfile', iTasksFileName,
                  '--svnco', 'MySVNRep',
                  '--deliver', 'deliver %{DeliverablesDir}'
                ],
                :Error => WEACE::MissingVariableError
              )
            end
          end

          # Test missing --svnco parameter
          def testMissingSVNCO
            setupTest do |iTasksFileName, iTicketsFileName|
              executeProcess(
                [
                  '--user', 'ReleaseUser',
                  '--branch', 'BranchName',
                  '--comment', 'ReleaseComment',
                  '--version', '0.0.1.20100317',
                  '--tasksfile', iTasksFileName,
                  '--ticketsfile', iTicketsFileName,
                  '--deliver', 'deliver %{DeliverablesDir}'
                ],
                :Error => WEACE::MissingVariableError
              )
            end
          end

          # Test missing --deliver parameter
          def testMissingDeliver
            setupTest do |iTasksFileName, iTicketsFileName|
              executeProcess(
                [
                  '--user', 'ReleaseUser',
                  '--branch', 'BranchName',
                  '--comment', 'ReleaseComment',
                  '--version', '0.0.1.20100317',
                  '--tasksfile', iTasksFileName,
                  '--ticketsfile', iTicketsFileName,
                  '--svnco', 'MySVNRep'
                ],
                :Error => WEACE::MissingVariableError
              )
            end
          end

          # Test invalid Tasks file
          def testInvalidTasks
            setupTest do |iTasksFileName, iTicketsFileName|
              executeProcess(
                [
                  '--user', 'ReleaseUser',
                  '--branch', 'BranchName',
                  '--comment', 'ReleaseComment',
                  '--version', '0.0.1.20100317',
                  '--tasksfile', '__Invalid_Tasks_File__',
                  '--ticketsfile', iTicketsFileName,
                  '--svnco', 'MySVNRep',
                  '--deliver', 'deliver %{DeliverablesDir}'
                ],
                :Error => WEACE::Master::Server::Processes::Dev_Release::MissingTasksFileError
              )
            end
          end

          # Test invalid Tickets file
          def testInvalidTickets
            setupTest do |iTasksFileName, iTicketsFileName|
              executeProcess(
                [
                  '--user', 'ReleaseUser',
                  '--branch', 'BranchName',
                  '--comment', 'ReleaseComment',
                  '--version', '0.0.1.20100317',
                  '--tasksfile', iTasksFileName,
                  '--ticketsfile', '__Invalid_Tickets_File__',
                  '--svnco', 'MySVNRep',
                  '--deliver', 'deliver %{DeliverablesDir}'
                ],
                :Error => WEACE::Master::Server::Processes::Dev_Release::MissingTicketsFileError
              )
            end
          end

          # Test when deliverables generation fails
          def testDeliverFail
            setupTest do |iTasksFileName, iTicketsFileName|
              $Context[:OS_ExecAnswers] = [
                # svn co => success
                [ 0, '' ],
                # deliver => failure
                [ 1, '' ]
              ]
              executeProcess(
                [
                  '--user', 'ReleaseUser',
                  '--branch', 'BranchName',
                  '--comment', 'ReleaseComment',
                  '--version', '0.0.1.20100317',
                  '--tasksfile', iTasksFileName,
                  '--ticketsfile', iTicketsFileName,
                  '--svnco', 'MySVNRep',
                  '--deliver', 'deliver %{DeliverablesDir}'
                ],
                :Error => WEACE::Master::Server::Processes::Dev_Release::DeliverablesGenerationError
              )
            end
          end

          # Test when deliverables generation is invalid
          def testDeliverInvalid
            setupTest do |iTasksFileName, iTicketsFileName|
              $Context[:OS_ExecAnswers] = [
                # svn co => success
                [ 0, '' ],
                # deliver => success, but invalid
                [ 0, '', @@Generator_Invalid ]
              ]
              executeProcess(
                [
                  '--user', 'ReleaseUser',
                  '--branch', 'BranchName',
                  '--comment', 'ReleaseComment',
                  '--version', '0.0.1.20100317',
                  '--tasksfile', iTasksFileName,
                  '--ticketsfile', iTicketsFileName,
                  '--svnco', 'MySVNRep',
                  '--deliver', 'deliver %{DeliverablesDir}'
                ],
                :Error => WEACE::Master::Server::Processes::Dev_Release::InvalidDeliverablesError
              )
            end
          end

          # Test when deliverables generation is valid, but release notes are invalid
          def testDeliverRNInvalid
            setupTest do |iTasksFileName, iTicketsFileName|
              $Context[:OS_ExecAnswers] = [
                # svn co => success
                [ 0, '' ],
                # deliver => success, but invalid
                [ 0, '', @@Generator_InvalidRN ]
              ]
              executeProcess(
                [
                  '--user', 'ReleaseUser',
                  '--branch', 'BranchName',
                  '--comment', 'ReleaseComment',
                  '--version', '0.0.1.20100317',
                  '--tasksfile', iTasksFileName,
                  '--ticketsfile', iTicketsFileName,
                  '--svnco', 'MySVNRep',
                  '--deliver', 'deliver %{DeliverablesDir}'
                ],
                :Error => WEACE::Master::Server::Processes::Dev_Release::InvalidDeliverablesError
              )
            end
          end

          # Test when deliverables generation is valid, but release notes are duplicated
          def testDeliverRNDuplicate
            setupTest do |iTasksFileName, iTicketsFileName|
              $Context[:OS_ExecAnswers] = [
                # svn co => success
                [ 0, '' ],
                # deliver => success, but invalid
                [ 0, '', @@Generator_DuplicateRN ]
              ]
              executeProcess(
                [
                  '--user', 'ReleaseUser',
                  '--branch', 'BranchName',
                  '--comment', 'ReleaseComment',
                  '--version', '0.0.1.20100317',
                  '--tasksfile', iTasksFileName,
                  '--ticketsfile', iTicketsFileName,
                  '--svnco', 'MySVNRep',
                  '--deliver', 'deliver %{DeliverablesDir}'
                ],
                :Error => WEACE::Master::Server::Processes::Dev_Release::InvalidDeliverablesError
              )
            end
          end

          private

          # Setup a file containing Tasks IDs, and ensure it will be removed at the end of the test.
          #
          # Parameters:
          # * *CodeBlock*: Code called once the file has been created:
          # ** *iFileName* (_String_): The file name generated
          def setupTasksList
            require 'tmpdir'
            lTasksFileName = "#{Dir.tmpdir}/WEACE_Tasks_#{Thread.current.object_id}.lst"
            File.open(lTasksFileName, 'w') do |oFile|
              oFile << 'TaskID 1
TaskID 2
TaskID 3'
            end
            yield(lTasksFileName)
            File.unlink(lTasksFileName)
          end

          # Setup a file containing Tickets IDs, and ensure it will be removed at the end of the test.
          #
          # Parameters:
          # * *CodeBlock*: Code called once the file has been created:
          # ** *iFileName* (_String_): The file name generated
          def setupTicketsList
            require 'tmpdir'
            lTicketsFileName = "#{Dir.tmpdir}/WEACE_Tickets_#{Thread.current.object_id}.lst"
            File.open(lTicketsFileName, 'w') do |oFile|
              oFile << 'TicketID 1
TicketID 2
TicketID 3'
            end
            yield(lTicketsFileName)
            File.unlink(lTicketsFileName)
          end

          # Setup everything before calling the test:
          # 1. Initialize the test case
          # 2. Create Tasks and Tickets files. Create Files file if asked.
          # 3. Create local repository
          # 4. Catch executions of `` operator
          #
          # Parameters:
          # * *iOptions* (<em>map<Symbol,Object></em>): Additional options [optional = {}]
          # * *CodeBlock*: Code called once everything has been initialized
          # ** *iTasksFileName* (_String_): The Tasks file name
          # ** *iTicketsFileName* (_String_): The Tickets file name
          def setupTest(iOptions = {})
            # Parse options
            initTestCase do
              setupTasksList do |iTasksFileName|
                setupTicketsList do |iTicketsFileName|
                  # Catch execution of `` operator
                  WEACE::Test::Common::changeMethod(
                    Kernel,
                    :`,
                    :backquote_regression
                  ) do
                    yield(iTasksFileName, iTicketsFileName)
                    if ($Variables[:DeliverableDir] != nil)
                      # Remove the Deliverable directory, as it can have been kept for investigation purposes
                      FileUtils::rm_rf($Variables[:DeliverableDir])
                    end
                  end
                end
              end
            end
          end

        end

      end

    end

  end

end
