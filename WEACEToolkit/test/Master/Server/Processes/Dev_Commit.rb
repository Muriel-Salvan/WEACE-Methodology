#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  # Define class exceptions here as they have to be known before requiring the plugin
  module Master

    class Server

      module Processes

        class Dev_Commit

          class MissingFilesFileError < RuntimeError
          end

          class MissingTasksFileError < RuntimeError
          end

          class MissingTicketsFileError < RuntimeError
          end

          class MissingLocalRepositoryError < RuntimeError
          end

          class UpdateConflictError < RuntimeError
          end

          class CommitConflictError < RuntimeError
          end

          class CommitInvalidError < RuntimeError
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

        class Dev_Commit < ::Test::Unit::TestCase
          
          include WEACE::Test::Master::Common

          # Test that getOptions return something correct
          def testGetOptions
            accessProcessPlugin do |iProcessPlugin|
              lProcessOptions = iProcessPlugin.getOptions
              assert(lProcessOptions.kind_of?(OptionParser))
            end
          end

          # Test a nominal case
          def testNominal
            setupTest do |iTasksFileName, iTicketsFileName, iLocalRepository|
              $Context[:OS_ExecAnswers] = [
                # svn up => no conflict
                [ 0, 'M  SampleFile.txt' ],
                # svn ci => success
                [ 0, 'Sending        SampleFile.txt
Transmitting file data .
Committed revision 314.' ]
              ]
              executeProcess(
                [
                  '--user', 'CommitUser',
                  '--branch', 'BranchName',
                  '--comment', 'CommitComment',
                  '--tasksfile', iTasksFileName,
                  '--ticketsfile', iTicketsFileName,
                  '--local', iLocalRepository
                ]
              ) do |iError, iSlaveActions|
                checkCallsMatch(
                  [
                    [ 'query', 'svn update --accept=postpone ' ],
                    [ 'query', 'svn ci --message "CommitComment" --username CommitUser  ' ]
                  ],
                  $Variables[:OS_Exec]
                )
                assert_equal(
                  {
                    Tools::TicketTracker => {
                      Actions::Ticket_AddCommitComment => [
                        [ 'TicketID 1', 'BranchName', 314, 'CommitUser', 'CommitComment' ],
                        [ 'TicketID 2', 'BranchName', 314, 'CommitUser', 'CommitComment' ],
                        [ 'TicketID 3', 'BranchName', 314, 'CommitUser', 'CommitComment' ]
                      ]
                    },
                    Tools::ProjectManager => {
                      Actions::Task_AddCommitComment => [
                        [ 'TaskID 1', 'BranchName', 314, 'CommitUser', 'CommitComment' ],
                        [ 'TaskID 2', 'BranchName', 314, 'CommitUser', 'CommitComment' ],
                        [ 'TaskID 3', 'BranchName', 314, 'CommitUser', 'CommitComment' ]
                      ]
                    },
                    Tools::Wiki => {
                      Actions::Wiki_AddCommitComment => [
                        [ 'BranchName', 314, 'CommitUser', 'CommitComment' ]
                      ]
                    }
                  },
                  iSlaveActions
                )
              end
            end
          end

          # Test a nominal case (short version)
          def testNominalShort
            setupTest do |iTasksFileName, iTicketsFileName, iLocalRepository|
              $Context[:OS_ExecAnswers] = [
                # svn up => no conflict
                [ 0, 'M  SampleFile.txt' ],
                # svn ci => success
                [ 0, 'Sending        SampleFile.txt
Transmitting file data .
Committed revision 314.' ]
              ]
              executeProcess(
                [
                  '-u', 'CommitUser',
                  '-b', 'BranchName',
                  '-c', 'CommitComment',
                  '-t', iTasksFileName,
                  '-k', iTicketsFileName,
                  '-l', iLocalRepository
                ]
              ) do |iError, iSlaveActions|
                checkCallsMatch(
                  [
                    [ 'query', 'svn update --accept=postpone ' ],
                    [ 'query', 'svn ci --message "CommitComment" --username CommitUser  ' ]
                  ],
                  $Variables[:OS_Exec]
                )
                assert_equal(
                  {
                    Tools::TicketTracker => {
                      Actions::Ticket_AddCommitComment => [
                        [ 'TicketID 1', 'BranchName', 314, 'CommitUser', 'CommitComment' ],
                        [ 'TicketID 2', 'BranchName', 314, 'CommitUser', 'CommitComment' ],
                        [ 'TicketID 3', 'BranchName', 314, 'CommitUser', 'CommitComment' ]
                      ]
                    },
                    Tools::ProjectManager => {
                      Actions::Task_AddCommitComment => [
                        [ 'TaskID 1', 'BranchName', 314, 'CommitUser', 'CommitComment' ],
                        [ 'TaskID 2', 'BranchName', 314, 'CommitUser', 'CommitComment' ],
                        [ 'TaskID 3', 'BranchName', 314, 'CommitUser', 'CommitComment' ]
                      ]
                    },
                    Tools::Wiki => {
                      Actions::Wiki_AddCommitComment => [
                        [ 'BranchName', 314, 'CommitUser', 'CommitComment' ]
                      ]
                    }
                  },
                  iSlaveActions
                )
              end
            end
          end

          # Test a nominal case with password
          def testNominalWithPassword
            setupTest do |iTasksFileName, iTicketsFileName, iLocalRepository|
              $Context[:OS_ExecAnswers] = [
                # svn up => no conflict
                [ 0, 'M  SampleFile.txt' ],
                # svn ci => success
                [ 0, 'Sending        SampleFile.txt
Transmitting file data .
Committed revision 314.' ]
              ]
              executeProcess(
                [
                  '--user', 'CommitUser',
                  '--password', 'CommitPassword',
                  '--branch', 'BranchName',
                  '--comment', 'CommitComment',
                  '--tasksfile', iTasksFileName,
                  '--ticketsfile', iTicketsFileName,
                  '--local', iLocalRepository
                ]
              ) do |iError, iSlaveActions|
                checkCallsMatch(
                  [
                    [ 'query', 'svn update --accept=postpone ' ],
                    [ 'query', 'svn ci --message "CommitComment" --username CommitUser --password CommitPassword ' ]
                  ],
                  $Variables[:OS_Exec]
                )
                assert_equal(
                  {
                    Tools::TicketTracker => {
                      Actions::Ticket_AddCommitComment => [
                        [ 'TicketID 1', 'BranchName', 314, 'CommitUser', 'CommitComment' ],
                        [ 'TicketID 2', 'BranchName', 314, 'CommitUser', 'CommitComment' ],
                        [ 'TicketID 3', 'BranchName', 314, 'CommitUser', 'CommitComment' ]
                      ]
                    },
                    Tools::ProjectManager => {
                      Actions::Task_AddCommitComment => [
                        [ 'TaskID 1', 'BranchName', 314, 'CommitUser', 'CommitComment' ],
                        [ 'TaskID 2', 'BranchName', 314, 'CommitUser', 'CommitComment' ],
                        [ 'TaskID 3', 'BranchName', 314, 'CommitUser', 'CommitComment' ]
                      ]
                    },
                    Tools::Wiki => {
                      Actions::Wiki_AddCommitComment => [
                        [ 'BranchName', 314, 'CommitUser', 'CommitComment' ]
                      ]
                    }
                  },
                  iSlaveActions
                )
              end
            end
          end

          # Test a nominal case with password (short version)
          def testNominalWithPasswordShort
            setupTest do |iTasksFileName, iTicketsFileName, iLocalRepository|
              $Context[:OS_ExecAnswers] = [
                # svn up => no conflict
                [ 0, 'M  SampleFile.txt' ],
                # svn ci => success
                [ 0, 'Sending        SampleFile.txt
Transmitting file data .
Committed revision 314.' ]
              ]
              executeProcess(
                [
                  '--user', 'CommitUser',
                  '-p', 'CommitPassword',
                  '--branch', 'BranchName',
                  '--comment', 'CommitComment',
                  '--tasksfile', iTasksFileName,
                  '--ticketsfile', iTicketsFileName,
                  '--local', iLocalRepository
                ]
              ) do |iError, iSlaveActions|
                checkCallsMatch(
                  [
                    [ 'query', 'svn update --accept=postpone ' ],
                    [ 'query', 'svn ci --message "CommitComment" --username CommitUser --password CommitPassword ' ]
                  ],
                  $Variables[:OS_Exec]
                )
                assert_equal(
                  {
                    Tools::TicketTracker => {
                      Actions::Ticket_AddCommitComment => [
                        [ 'TicketID 1', 'BranchName', 314, 'CommitUser', 'CommitComment' ],
                        [ 'TicketID 2', 'BranchName', 314, 'CommitUser', 'CommitComment' ],
                        [ 'TicketID 3', 'BranchName', 314, 'CommitUser', 'CommitComment' ]
                      ]
                    },
                    Tools::ProjectManager => {
                      Actions::Task_AddCommitComment => [
                        [ 'TaskID 1', 'BranchName', 314, 'CommitUser', 'CommitComment' ],
                        [ 'TaskID 2', 'BranchName', 314, 'CommitUser', 'CommitComment' ],
                        [ 'TaskID 3', 'BranchName', 314, 'CommitUser', 'CommitComment' ]
                      ]
                    },
                    Tools::Wiki => {
                      Actions::Wiki_AddCommitComment => [
                        [ 'BranchName', 314, 'CommitUser', 'CommitComment' ]
                      ]
                    }
                  },
                  iSlaveActions
                )
              end
            end
          end

          # Test a nominal case with a files list
          def testNominalWithFilesList
            setupTest(:FilesList => true) do |iTasksFileName, iTicketsFileName, iLocalRepository, iFilesFileName|
              $Context[:OS_ExecAnswers] = [
                # svn up => no conflict
                [ 0, 'M  SampleFile.txt' ],
                # svn ci => success
                [ 0, 'Sending        SampleFile.txt
Transmitting file data .
Committed revision 314.' ]
              ]
              executeProcess(
                [
                  '--user', 'CommitUser',
                  '--branch', 'BranchName',
                  '--comment', 'CommitComment',
                  '--tasksfile', iTasksFileName,
                  '--ticketsfile', iTicketsFileName,
                  '--filesfile', iFilesFileName,
                  '--local', iLocalRepository
                ]
              ) do |iError, iSlaveActions|
                checkCallsMatch(
                  [
                    [ 'query', 'svn update --accept=postpone  "File name 1" FileName2 "File name 3"' ],
                    [ 'query', 'svn ci --message "CommitComment" --username CommitUser   "File name 1" FileName2 "File name 3"' ]
                  ],
                  $Variables[:OS_Exec]
                )
                assert_equal(
                  {
                    Tools::TicketTracker => {
                      Actions::Ticket_AddCommitComment => [
                        [ 'TicketID 1', 'BranchName', 314, 'CommitUser', 'CommitComment' ],
                        [ 'TicketID 2', 'BranchName', 314, 'CommitUser', 'CommitComment' ],
                        [ 'TicketID 3', 'BranchName', 314, 'CommitUser', 'CommitComment' ]
                      ]
                    },
                    Tools::ProjectManager => {
                      Actions::Task_AddCommitComment => [
                        [ 'TaskID 1', 'BranchName', 314, 'CommitUser', 'CommitComment' ],
                        [ 'TaskID 2', 'BranchName', 314, 'CommitUser', 'CommitComment' ],
                        [ 'TaskID 3', 'BranchName', 314, 'CommitUser', 'CommitComment' ]
                      ]
                    },
                    Tools::Wiki => {
                      Actions::Wiki_AddCommitComment => [
                        [ 'BranchName', 314, 'CommitUser', 'CommitComment' ]
                      ]
                    }
                  },
                  iSlaveActions
                )
              end
            end
          end

          # Test a nominal case with a files list (short version)
          def testNominalWithFilesListShort
            setupTest(:FilesList => true) do |iTasksFileName, iTicketsFileName, iLocalRepository, iFilesFileName|
              $Context[:OS_ExecAnswers] = [
                # svn up => no conflict
                [ 0, 'M  SampleFile.txt' ],
                # svn ci => success
                [ 0, 'Sending        SampleFile.txt
Transmitting file data .
Committed revision 314.' ]
              ]
              executeProcess(
                [
                  '--user', 'CommitUser',
                  '--branch', 'BranchName',
                  '--comment', 'CommitComment',
                  '--tasksfile', iTasksFileName,
                  '--ticketsfile', iTicketsFileName,
                  '-f', iFilesFileName,
                  '--local', iLocalRepository
                ]
              ) do |iError, iSlaveActions|
                checkCallsMatch(
                  [
                    [ 'query', 'svn update --accept=postpone  "File name 1" FileName2 "File name 3"' ],
                    [ 'query', 'svn ci --message "CommitComment" --username CommitUser   "File name 1" FileName2 "File name 3"' ]
                  ],
                  $Variables[:OS_Exec]
                )
                assert_equal(
                  {
                    Tools::TicketTracker => {
                      Actions::Ticket_AddCommitComment => [
                        [ 'TicketID 1', 'BranchName', 314, 'CommitUser', 'CommitComment' ],
                        [ 'TicketID 2', 'BranchName', 314, 'CommitUser', 'CommitComment' ],
                        [ 'TicketID 3', 'BranchName', 314, 'CommitUser', 'CommitComment' ]
                      ]
                    },
                    Tools::ProjectManager => {
                      Actions::Task_AddCommitComment => [
                        [ 'TaskID 1', 'BranchName', 314, 'CommitUser', 'CommitComment' ],
                        [ 'TaskID 2', 'BranchName', 314, 'CommitUser', 'CommitComment' ],
                        [ 'TaskID 3', 'BranchName', 314, 'CommitUser', 'CommitComment' ]
                      ]
                    },
                    Tools::Wiki => {
                      Actions::Wiki_AddCommitComment => [
                        [ 'BranchName', 314, 'CommitUser', 'CommitComment' ]
                      ]
                    }
                  },
                  iSlaveActions
                )
              end
            end
          end

          # Test a nominal case with regression testing
          def testNominalWithRegression
            setupTest do |iTasksFileName, iTicketsFileName, iLocalRepository|
              $Context[:OS_ExecAnswers] = [
                # svn up => no conflict
                [ 0, 'M  SampleFile.txt' ],
                # Run regression => success
                [ 0, '' ],
                # svn ci => success
                [ 0, 'Sending        SampleFile.txt
Transmitting file data .
Committed revision 314.' ]
              ]
              executeProcess(
                [
                  '--user', 'CommitUser',
                  '--branch', 'BranchName',
                  '--comment', 'CommitComment',
                  '--tasksfile', iTasksFileName,
                  '--ticketsfile', iTicketsFileName,
                  '--local', iLocalRepository,
                  '--regressioncmd', 'test/runReg'
                ]
              ) do |iError, iSlaveActions|
                checkCallsMatch(
                  [
                    [ 'query', 'svn update --accept=postpone ' ],
                    [ 'query', 'test/runReg' ],
                    [ 'query', 'svn ci --message "CommitComment" --username CommitUser  ' ]
                  ],
                  $Variables[:OS_Exec]
                )
                assert_equal(
                  {
                    Tools::TicketTracker => {
                      Actions::Ticket_AddCommitComment => [
                        [ 'TicketID 1', 'BranchName', 314, 'CommitUser', 'CommitComment' ],
                        [ 'TicketID 2', 'BranchName', 314, 'CommitUser', 'CommitComment' ],
                        [ 'TicketID 3', 'BranchName', 314, 'CommitUser', 'CommitComment' ]
                      ]
                    },
                    Tools::ProjectManager => {
                      Actions::Task_AddCommitComment => [
                        [ 'TaskID 1', 'BranchName', 314, 'CommitUser', 'CommitComment' ],
                        [ 'TaskID 2', 'BranchName', 314, 'CommitUser', 'CommitComment' ],
                        [ 'TaskID 3', 'BranchName', 314, 'CommitUser', 'CommitComment' ]
                      ]
                    },
                    Tools::Wiki => {
                      Actions::Wiki_AddCommitComment => [
                        [ 'BranchName', 314, 'CommitUser', 'CommitComment' ]
                      ]
                    }
                  },
                  iSlaveActions
                )
              end
            end
          end

          # Test a nominal case with regression testing (short version)
          def testNominalWithRegressionShort
            setupTest do |iTasksFileName, iTicketsFileName, iLocalRepository|
              $Context[:OS_ExecAnswers] = [
                # svn up => no conflict
                [ 0, 'M  SampleFile.txt' ],
                # Run regression => success
                [ 0, '' ],
                # svn ci => success
                [ 0, 'Sending        SampleFile.txt
Transmitting file data .
Committed revision 314.' ]
              ]
              executeProcess(
                [
                  '--user', 'CommitUser',
                  '--branch', 'BranchName',
                  '--comment', 'CommitComment',
                  '--tasksfile', iTasksFileName,
                  '--ticketsfile', iTicketsFileName,
                  '--local', iLocalRepository,
                  '-r', 'test/runReg'
                ]
              ) do |iError, iSlaveActions|
                checkCallsMatch(
                  [
                    [ 'query', 'svn update --accept=postpone ' ],
                    [ 'query', 'test/runReg' ],
                    [ 'query', 'svn ci --message "CommitComment" --username CommitUser  ' ]
                  ],
                  $Variables[:OS_Exec]
                )
                assert_equal(
                  {
                    Tools::TicketTracker => {
                      Actions::Ticket_AddCommitComment => [
                        [ 'TicketID 1', 'BranchName', 314, 'CommitUser', 'CommitComment' ],
                        [ 'TicketID 2', 'BranchName', 314, 'CommitUser', 'CommitComment' ],
                        [ 'TicketID 3', 'BranchName', 314, 'CommitUser', 'CommitComment' ]
                      ]
                    },
                    Tools::ProjectManager => {
                      Actions::Task_AddCommitComment => [
                        [ 'TaskID 1', 'BranchName', 314, 'CommitUser', 'CommitComment' ],
                        [ 'TaskID 2', 'BranchName', 314, 'CommitUser', 'CommitComment' ],
                        [ 'TaskID 3', 'BranchName', 314, 'CommitUser', 'CommitComment' ]
                      ]
                    },
                    Tools::Wiki => {
                      Actions::Wiki_AddCommitComment => [
                        [ 'BranchName', 314, 'CommitUser', 'CommitComment' ]
                      ]
                    }
                  },
                  iSlaveActions
                )
              end
            end
          end

          # Test a nominal case with regression failure
          def testNominalWithRegressionFailed
            setupTest do |iTasksFileName, iTicketsFileName, iLocalRepository|
              $Context[:OS_ExecAnswers] = [
                # svn up => no conflict
                [ 0, 'M  SampleFile.txt' ],
                # Run regression => failure
                [ 1, '' ]
              ]
              executeProcess(
                [
                  '--user', 'CommitUser',
                  '--branch', 'BranchName',
                  '--comment', 'CommitComment',
                  '--tasksfile', iTasksFileName,
                  '--ticketsfile', iTicketsFileName,
                  '--local', iLocalRepository,
                  '--regressioncmd', 'test/runReg'
                ],
                :Error => WEACE::Master::Server::Processes::Dev_Commit::RegressionError
              )
            end
          end

          # Test a nominal case with files list and regression testing
          def testNominalWithFilesAndRegression
            setupTest(:FilesList => true) do |iTasksFileName, iTicketsFileName, iLocalRepository, iFilesFileName|
              $Context[:OS_ExecAnswers] = [
                # svn up => no conflict
                [ 0, 'M  SampleFile.txt' ],
                # svn co => success
                [ 0, '' ],
                # Run regression => success
                [ 0, '' ],
                # svn ci => success
                [ 0, 'Sending        SampleFile.txt
Transmitting file data .
Committed revision 314.' ]
              ]
              executeProcess(
                [
                  '--user', 'CommitUser',
                  '--branch', 'BranchName',
                  '--comment', 'CommitComment',
                  '--tasksfile', iTasksFileName,
                  '--ticketsfile', iTicketsFileName,
                  '--filesfile', iFilesFileName,
                  '--local', iLocalRepository,
                  '--regressioncmd', 'test/runReg',
                  '--svnco', 'MySVNRep'
                ]
              ) do |iError, iSlaveActions|
                checkCallsMatch(
                  [
                    [ 'query', 'svn update --accept=postpone  "File name 1" FileName2 "File name 3"' ],
                    [ 'query', 'svn co MySVNRep' ],
                    [ 'query', 'test/runReg' ],
                    [ 'query', 'svn ci --message "CommitComment" --username CommitUser   "File name 1" FileName2 "File name 3"' ]
                  ],
                  $Variables[:OS_Exec]
                )
                assert_equal(
                  {
                    Tools::TicketTracker => {
                      Actions::Ticket_AddCommitComment => [
                        [ 'TicketID 1', 'BranchName', 314, 'CommitUser', 'CommitComment' ],
                        [ 'TicketID 2', 'BranchName', 314, 'CommitUser', 'CommitComment' ],
                        [ 'TicketID 3', 'BranchName', 314, 'CommitUser', 'CommitComment' ]
                      ]
                    },
                    Tools::ProjectManager => {
                      Actions::Task_AddCommitComment => [
                        [ 'TaskID 1', 'BranchName', 314, 'CommitUser', 'CommitComment' ],
                        [ 'TaskID 2', 'BranchName', 314, 'CommitUser', 'CommitComment' ],
                        [ 'TaskID 3', 'BranchName', 314, 'CommitUser', 'CommitComment' ]
                      ]
                    },
                    Tools::Wiki => {
                      Actions::Wiki_AddCommitComment => [
                        [ 'BranchName', 314, 'CommitUser', 'CommitComment' ]
                      ]
                    }
                  },
                  iSlaveActions
                )
              end
            end
          end

          # Test a nominal case with files list and regression testing (short version)
          def testNominalWithFilesAndRegressionShort
            setupTest(:FilesList => true) do |iTasksFileName, iTicketsFileName, iLocalRepository, iFilesFileName|
              $Context[:OS_ExecAnswers] = [
                # svn up => no conflict
                [ 0, 'M  SampleFile.txt' ],
                # svn co => success
                [ 0, '' ],
                # Run regression => success
                [ 0, '' ],
                # svn ci => success
                [ 0, 'Sending        SampleFile.txt
Transmitting file data .
Committed revision 314.' ]
              ]
              executeProcess(
                [
                  '--user', 'CommitUser',
                  '--branch', 'BranchName',
                  '--comment', 'CommitComment',
                  '--tasksfile', iTasksFileName,
                  '--ticketsfile', iTicketsFileName,
                  '--filesfile', iFilesFileName,
                  '--local', iLocalRepository,
                  '--regressioncmd', 'test/runReg',
                  '-s', 'MySVNRep'
                ]
              ) do |iError, iSlaveActions|
                checkCallsMatch(
                  [
                    [ 'query', 'svn update --accept=postpone  "File name 1" FileName2 "File name 3"' ],
                    [ 'query', 'svn co MySVNRep' ],
                    [ 'query', 'test/runReg' ],
                    [ 'query', 'svn ci --message "CommitComment" --username CommitUser   "File name 1" FileName2 "File name 3"' ]
                  ],
                  $Variables[:OS_Exec]
                )
                assert_equal(
                  {
                    Tools::TicketTracker => {
                      Actions::Ticket_AddCommitComment => [
                        [ 'TicketID 1', 'BranchName', 314, 'CommitUser', 'CommitComment' ],
                        [ 'TicketID 2', 'BranchName', 314, 'CommitUser', 'CommitComment' ],
                        [ 'TicketID 3', 'BranchName', 314, 'CommitUser', 'CommitComment' ]
                      ]
                    },
                    Tools::ProjectManager => {
                      Actions::Task_AddCommitComment => [
                        [ 'TaskID 1', 'BranchName', 314, 'CommitUser', 'CommitComment' ],
                        [ 'TaskID 2', 'BranchName', 314, 'CommitUser', 'CommitComment' ],
                        [ 'TaskID 3', 'BranchName', 314, 'CommitUser', 'CommitComment' ]
                      ]
                    },
                    Tools::Wiki => {
                      Actions::Wiki_AddCommitComment => [
                        [ 'BranchName', 314, 'CommitUser', 'CommitComment' ]
                      ]
                    }
                  },
                  iSlaveActions
                )
              end
            end
          end

          # Test a nominal case with files list and regression failing
          def testNominalWithFilesAndRegressionFail
            setupTest(:FilesList => true) do |iTasksFileName, iTicketsFileName, iLocalRepository, iFilesFileName|
              $Context[:OS_ExecAnswers] = [
                # svn up => no conflict
                [ 0, 'M  SampleFile.txt' ],
                # svn co => success
                [ 0, '' ],
                # Run regression => failure
                [ 1, '' ]
              ]
              executeProcess(
                [
                  '--user', 'CommitUser',
                  '--branch', 'BranchName',
                  '--comment', 'CommitComment',
                  '--tasksfile', iTasksFileName,
                  '--ticketsfile', iTicketsFileName,
                  '--filesfile', iFilesFileName,
                  '--local', iLocalRepository,
                  '--regressioncmd', 'test/runReg',
                  '--svnco', 'MySVNRep'
                ],
                :Error => WEACE::Master::Server::Processes::Dev_Commit::RegressionError
              )
            end
          end

          # Test missing --svnco parameter
          def testMissingSVNCo
            setupTest(:FilesList => true) do |iTasksFileName, iTicketsFileName, iLocalRepository, iFilesFileName|
              executeProcess(
                [
                  '--user', 'CommitUser',
                  '--branch', 'BranchName',
                  '--comment', 'CommitComment',
                  '--tasksfile', iTasksFileName,
                  '--ticketsfile', iTicketsFileName,
                  '--filesfile', iFilesFileName,
                  '--local', iLocalRepository,
                  '--regressioncmd', 'test/runReg'
                ],
                :Error => WEACE::MissingVariableError
              )
            end
          end

          # Test when the user is missing
          def testMissingUser
            setupTest do |iTasksFileName, iTicketsFileName, iLocalRepository|
              executeProcess(
                [
                  '--branch', 'BranchName',
                  '--comment', 'CommitComment',
                  '--tasksfile', iTasksFileName,
                  '--ticketsfile', iTicketsFileName,
                  '--local', iLocalRepository
                ],
                :Error => WEACE::MissingVariableError
              )
            end
          end

          # Test when the branch is missing
          def testMissingBranch
            setupTest do |iTasksFileName, iTicketsFileName, iLocalRepository|
              executeProcess(
                [
                  '--user', 'CommitUser',
                  '--comment', 'CommitComment',
                  '--tasksfile', iTasksFileName,
                  '--ticketsfile', iTicketsFileName,
                  '--local', iLocalRepository
                ],
                :Error => WEACE::MissingVariableError
              )
            end
          end

          # Test when the comment is missing
          def testMissingComment
            setupTest do |iTasksFileName, iTicketsFileName, iLocalRepository|
              executeProcess(
                [
                  '--user', 'CommitUser',
                  '--branch', 'BranchName',
                  '--tasksfile', iTasksFileName,
                  '--ticketsfile', iTicketsFileName,
                  '--local', iLocalRepository
                ],
                :Error => WEACE::MissingVariableError
              )
            end
          end

          # Test when the Tasks file is missing
          def testMissingTasksFile
            setupTest do |iTasksFileName, iTicketsFileName, iLocalRepository|
              executeProcess(
                [
                  '--user', 'CommitUser',
                  '--branch', 'BranchName',
                  '--comment', 'CommitComment',
                  '--ticketsfile', iTicketsFileName,
                  '--local', iLocalRepository
                ],
                :Error => WEACE::MissingVariableError
              )
            end
          end

          # Test when the Tickets file is missing
          def testMissingTicketsFile
            setupTest do |iTasksFileName, iTicketsFileName, iLocalRepository|
              executeProcess(
                [
                  '--user', 'CommitUser',
                  '--branch', 'BranchName',
                  '--comment', 'CommitComment',
                  '--tasksfile', iTasksFileName,
                  '--local', iLocalRepository
                ],
                :Error => WEACE::MissingVariableError
              )
            end
          end

          # Test when the local repository is missing
          def testMissingLocalRepository
            setupTest do |iTasksFileName, iTicketsFileName, iLocalRepository|
              executeProcess(
                [
                  '--user', 'CommitUser',
                  '--branch', 'BranchName',
                  '--comment', 'CommitComment',
                  '--tasksfile', iTasksFileName,
                  '--ticketsfile', iTicketsFileName
                ],
                :Error => WEACE::MissingVariableError
              )
            end
          end

          # Test when the Tasks file is invalid
          def testInvalidTasksFile
            setupTest do |iTasksFileName, iTicketsFileName, iLocalRepository|
              executeProcess(
                [
                  '--user', 'CommitUser',
                  '--branch', 'BranchName',
                  '--comment', 'CommitComment',
                  '--tasksfile', '__Invalid__Tasks__File__',
                  '--ticketsfile', iTicketsFileName,
                  '--local', iLocalRepository
                ],
                :Error => WEACE::Master::Server::Processes::Dev_Commit::MissingTasksFileError
              )
            end
          end

          # Test when the Tickets file is invalid
          def testInvalidTicketsFile
            setupTest do |iTasksFileName, iTicketsFileName, iLocalRepository|
              executeProcess(
                [
                  '--user', 'CommitUser',
                  '--branch', 'BranchName',
                  '--comment', 'CommitComment',
                  '--tasksfile', iTasksFileName,
                  '--ticketsfile', '__Invalid__Tickets__File__',
                  '--local', iLocalRepository
                ],
                :Error => WEACE::Master::Server::Processes::Dev_Commit::MissingTicketsFileError
              )
            end
          end

          # Test when the local repository is invalid
          def testInvalidLocalRepository
            setupTest do |iTasksFileName, iTicketsFileName, iLocalRepository|
              executeProcess(
                [
                  '--user', 'CommitUser',
                  '--branch', 'BranchName',
                  '--comment', 'CommitComment',
                  '--tasksfile', iTasksFileName,
                  '--ticketsfile', iTicketsFileName,
                  '--local', '__Invalid__Local__Repository__'
                ],
                :Error => WEACE::Master::Server::Processes::Dev_Commit::MissingLocalRepositoryError
              )
            end
          end

          # Test when update has a conflict
          def testConflictUpdate
            setupTest do |iTasksFileName, iTicketsFileName, iLocalRepository|
              $Context[:OS_ExecAnswers] = [
                # svn up => conflict
                [ 0, 'C  SampleFile.txt' ]
              ]
              executeProcess(
                [
                  '--user', 'CommitUser',
                  '--branch', 'BranchName',
                  '--comment', 'CommitComment',
                  '--tasksfile', iTasksFileName,
                  '--ticketsfile', iTicketsFileName,
                  '--local', iLocalRepository
                ],
                :Error => WEACE::Master::Server::Processes::Dev_Commit::UpdateConflictError
              )
            end
          end

          # Test when commit has a conflict
          def testConflictCommit
            setupTest do |iTasksFileName, iTicketsFileName, iLocalRepository|
              $Context[:OS_ExecAnswers] = [
                # svn up => no conflict
                [ 0, 'M  SampleFile.txt' ],
                # svn ci => conflict
                [ 1, 'Sending        SampleFile.txt
svn: Commit failed (details follow):
svn: Out of date: \'SampleFile.txt\' in transaction \'g\'' ]
              ]
              executeProcess(
                [
                  '--user', 'CommitUser',
                  '--branch', 'BranchName',
                  '--comment', 'CommitComment',
                  '--tasksfile', iTasksFileName,
                  '--ticketsfile', iTicketsFileName,
                  '--local', iLocalRepository
                ],
                :Error => WEACE::Master::Server::Processes::Dev_Commit::CommitConflictError
              )
            end
          end

          # Test when commit has an invalid output
          def testInvalidCommit
            setupTest do |iTasksFileName, iTicketsFileName, iLocalRepository|
              $Context[:OS_ExecAnswers] = [
                # svn up => no conflict
                [ 0, 'M  SampleFile.txt' ],
                # svn ci => invalid
                [ 0, 'Blablabla
Invalid output' ]
              ]
              executeProcess(
                [
                  '--user', 'CommitUser',
                  '--branch', 'BranchName',
                  '--comment', 'CommitComment',
                  '--tasksfile', iTasksFileName,
                  '--ticketsfile', iTicketsFileName,
                  '--local', iLocalRepository
                ],
                :Error => WEACE::Master::Server::Processes::Dev_Commit::CommitInvalidError
              )
            end
          end


          # Test other parameters

          private

          # Setup a file containing Tasks IDs, and ensure it will be removed at the end of the test.
          #
          # Parameters:
          # * *CodeBlock*: Code called once the file has been created:
          # ** *iFileName* (_String_): The file name generated
          def setupTasksList
            require 'tmpdir'
            lTasksFileName = "#{Dir.tmpdir}/WEACE_Tasks_#{Thread.object_id}.lst"
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
            lTicketsFileName = "#{Dir.tmpdir}/WEACE_Tickets_#{Thread.object_id}.lst"
            File.open(lTicketsFileName, 'w') do |oFile|
              oFile << 'TicketID 1
TicketID 2
TicketID 3'
            end
            yield(lTicketsFileName)
            File.unlink(lTicketsFileName)
          end

          # Setup a file containing file names, and ensure it will be removed at the end of the test.
          #
          # Parameters:
          # * *CodeBlock*: Code called once the file has been created:
          # ** *iFileName* (_String_): The file name generated
          def setupFilesList
            require 'tmpdir'
            lFilesFileName = "#{Dir.tmpdir}/WEACE_Files_#{Thread.object_id}.lst"
            File.open(lFilesFileName, 'w') do |oFile|
              oFile << 'File name 1
FileName2
File name 3'
            end
            yield(lFilesFileName)
            File.unlink(lFilesFileName)
          end

          # Setup a local repository
          #
          # Parameters:
          # * *CodeBlock*: Code called once the file has been created:
          # ** *iDirName* (_String_): The directory name generated
          def setupLocalRepository
            lLocalRepository = "#{Dir.tmpdir}/WEACE_LocalRepository"
            require 'fileutils'
            FileUtils::mkdir_p(lLocalRepository)
            yield(lLocalRepository)
            FileUtils::rm_rf(lLocalRepository)
          end

          # Setup everything before calling the test:
          # 1. Initialize the test case
          # 2. Create Tasks and Tickets files. Create Files file if asked.
          # 3. Create local repository
          # 4. Catch executions of `` operator
          #
          # Parameters:
          # * *iOptions* (<em>map<Symbol,Object></em>): Additional options [optional = {}]
          # ** *:FilesList* (_Boolean_): Do we generate a files list ? [optional = false]
          # * *CodeBlock*: Code called once everything has been initialized
          # ** *iTasksFileName* (_String_): The Tasks file name
          # ** *iTicketsFileName* (_String_): The Tickets file name
          # ** *iLocalRepository* (_String_): The local repository
          # ** *iFilesFileName* (_String_): The Files file name (only if :FilesList was set to true).
          def setupTest(iOptions = {})
            # Parse options
            lFilesList = iOptions[:FilesList]
            if (lFilesList == nil)
              lFilesList = false
            end
            initTestCase do
              setupTasksList do |iTasksFileName|
                setupTicketsList do |iTicketsFileName|
                  setupLocalRepository do |iLocalRepository|
                    # Catch execution of `` operator
                    WEACE::Test::Common::changeMethod(
                      Kernel,
                      :`,
                      :backquote_regression
                    ) do
                      if (lFilesList)
                        setupFilesList do |iFilesFileName|
                          yield(iTasksFileName, iTicketsFileName, iLocalRepository, iFilesFileName)
                        end
                      else
                        yield(iTasksFileName, iTicketsFileName, iLocalRepository)
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

end
