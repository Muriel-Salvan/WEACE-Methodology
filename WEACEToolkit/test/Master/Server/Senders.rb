#--
# Copyright (c) 2009 - 2012 Muriel Salvan  (muriel@x-aeon.com)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  module Test

    module Master

      module Server

        # This test suite validates the use of Senders by MasterServer.
        # It does not test any Sender.
        class Senders < ::Test::Unit::TestCase

          include WEACE::Test::Master::Common

          # Get the SlaveClient queue corresponding to the SlaveClient info configured in the repository
          #
          # Return
          # * <em>list< [String,map<ToolID,map<ActionID,list<Parameters>>>] ></em>: The corresponding queue
          def getSlaveClientQueue
            rQueue = []

            # Read the SlaveClient's info from the MasterServer's configuration
            lSlaveClientInfo = nil
            File.open("#{@WEACERepositoryDir}/Config/MasterServer.conf.rb", 'r') do |iFile|
              lSlaveClientInfo = eval(iFile.read)[:WEACESlaveClients][0]
            end
            # Get the corresponding queue
            lHash = sprintf('%X', lSlaveClientInfo.hash.abs)
            lQueueFile = "#{@WEACERepositoryDir}/Volatile/MasterServer/SlaveClientQueues/#{lHash}.Queue"
            if (File.exists?(lQueueFile))
              File.open(lQueueFile, 'rb') do |iFile|
                rQueue = Marshal.load(iFile.read)
              end
            end

            return rQueue
          end

          # Get all the SlaveClient queues corresponding to the SlaveClients info configured in the repository
          #
          # Return
          # * <em>map<map<Symbol,Object>,list< [String,map<ToolID,map<ActionID,list<Parameters>>>] >></em>: The corresponding queues, per SlaveClient info
          def getSlaveClientQueues
            rQueues = {}

            # Read the SlaveClient's info from the MasterServer's configuration
            lSlaveClientInfos = nil
            File.open("#{@WEACERepositoryDir}/Config/MasterServer.conf.rb", 'r') do |iFile|
              lSlaveClientInfos = eval(iFile.read)[:WEACESlaveClients]
            end
            lSlaveClientInfos.each do |iSlaveClientInfo|
              # Get the corresponding queue
              lHash = sprintf('%X', iSlaveClientInfo.hash.abs)
              lQueueFile = "#{@WEACERepositoryDir}/Volatile/MasterServer/SlaveClientQueues/#{lHash}.Queue"
              if (File.exists?(lQueueFile))
                File.open(lQueueFile, 'rb') do |iFile|
                  rQueues[iSlaveClientInfo] = Marshal.load(iFile.read)
                end
              end
            end

            return rQueues
          end

          # Get the set of transfer files, along with their counters
          #
          # Return::
          # * <em>map<String,Integer></em>: The transfer files
          def getTransferFiles
            rTransferFiles = {}

            lTransferFilesFile = "#{@WEACERepositoryDir}/Volatile/MasterServer/SlaveClientQueues/TransferFiles"
            if (File.exists?(lTransferFilesFile))
              File.open(lTransferFilesFile, 'rb') do |iFile|
                rTransferFiles = Marshal.load(iFile.read)
              end
            end

            return rTransferFiles
          end

          # Test when no action is to be performed
          def testNoAction
            executeMaster( [ '--process', 'DummyProcess', '--user', 'DummyUser' ],
              :Repository => 'Dummy/MasterServerInstalledWithDummySender',
              :AddRegressionProcesses => true,
              :AddRegressionSenders => true
            ) do |iError|
              assert_equal(nil, $Variables[:DummySenderCalls])
            end
          end

          # Test minimal flow
          def testMinimalFlow
            initTestCase do
              $Context[:SlaveActions] = [
                [ 'DummyTool', 'DummyAction', [] ]
              ]
              executeMaster( [ '--process', 'DummyProcess', '--user', 'DummyUser' ],
                :Repository => 'Dummy/MasterServerInstalledWithDummySender',
                :AddRegressionProcesses => true,
                :AddRegressionSenders => true
              ) do |iError|
                assert_equal( [
                    [ 'sendMessage', [ 'DummyUser', {
                          'DummyTool' => {
                            'DummyAction' => [
                              []
                            ]
                          }
                        } ]
                    ]
                  ],
                  $Variables[:DummySenderCalls]
                )
                assert_equal([], getSlaveClientQueue)
              end
            end
          end

          # Test 1 Action with parameters
          def test1ActionWithParams
            initTestCase do
              $Context[:SlaveActions] = [
                [ 'DummyTool', 'DummyAction', ['Param1', 'Param2'] ]
              ]
              executeMaster( [ '--process', 'DummyProcess', '--user', 'DummyUser' ],
                :Repository => 'Dummy/MasterServerInstalledWithDummySender',
                :AddRegressionProcesses => true,
                :AddRegressionSenders => true
              ) do |iError|
                assert_equal( [
                    [ 'sendMessage', [ 'DummyUser', {
                          'DummyTool' => {
                            'DummyAction' => [
                              ['Param1', 'Param2']
                            ]
                          }
                        } ]
                    ]
                  ],
                  $Variables[:DummySenderCalls]
                )
                assert_equal([], getSlaveClientQueue)
              end
            end
          end

          # Test sending 2 SlaveActions
          def test2Actions
            initTestCase do
              $Context[:SlaveActions] = [
                [ 'DummyTool', 'DummyAction', [] ],
                [ 'DummyTool', 'DummyAction2', [] ]
              ]
              executeMaster( [ '--process', 'DummyProcess', '--user', 'DummyUser' ],
                :Repository => 'Dummy/MasterServerInstalledWithDummySender',
                :AddRegressionProcesses => true,
                :AddRegressionSenders => true
              ) do |iError|
                assert_equal( [
                    [ 'sendMessage', [ 'DummyUser', {
                          'DummyTool' => {
                            'DummyAction' => [
                              []
                            ],
                            'DummyAction2' => [
                              []
                            ]
                          }
                        } ]
                    ]
                  ],
                  $Variables[:DummySenderCalls]
                )
                assert_equal([], getSlaveClientQueue)
              end
            end
          end

          # Test sending 2 SlaveActions with different Tools
          def test2ActionsDifferentTools
            initTestCase do
              $Context[:SlaveActions] = [
                [ 'DummyTool', 'DummyAction', [] ],
                [ 'DummyTool2', 'DummyAction2', [] ]
              ]
              executeMaster( [ '--process', 'DummyProcess', '--user', 'DummyUser' ],
                :Repository => 'Dummy/MasterServerInstalledWithDummySender',
                :AddRegressionProcesses => true,
                :AddRegressionSenders => true
              ) do |iError|
                assert_equal( [
                    [ 'sendMessage', [ 'DummyUser', {
                          'DummyTool' => {
                            'DummyAction' => [
                              []
                            ]
                          },
                          'DummyTool2' => {
                            'DummyAction2' => [
                              []
                            ]
                          }
                        } ]
                    ]
                  ],
                  $Variables[:DummySenderCalls]
                )
                assert_equal([], getSlaveClientQueue)
              end
            end
          end

          # Test sending 2 SlaveActions with different parameters
          def test2ActionsDifferentParameters
            initTestCase do
              $Context[:SlaveActions] = [
                [ 'DummyTool', 'DummyAction', ['Param1'] ],
                [ 'DummyTool', 'DummyAction', ['Param2'] ]
              ]
              executeMaster( [ '--process', 'DummyProcess', '--user', 'DummyUser' ],
                :Repository => 'Dummy/MasterServerInstalledWithDummySender',
                :AddRegressionProcesses => true,
                :AddRegressionSenders => true
              ) do |iError|
                assert_equal( [
                    [ 'sendMessage', [ 'DummyUser', {
                          'DummyTool' => {
                            'DummyAction' => [
                              ['Param1'],
                              ['Param2']
                            ]
                          }
                        } ]
                    ]
                  ],
                  $Variables[:DummySenderCalls]
                )
                assert_equal([], getSlaveClientQueue)
              end
            end
          end

          # Test 1 Action with a file transfer
          def test1ActionWithFileTransfer
            initTestCase do
              setupTempFile(false) do |iTmpFileName|
                $Context[:SlaveActions] = [
                  [ 'DummyTool', 'DummyAction', [WEACE::Master::TransferFile.new(iTmpFileName)] ]
                ]
                executeMaster( [ '--process', 'DummyProcess', '--user', 'DummyUser' ],
                  :Repository => 'Dummy/MasterServerInstalledWithDummySender',
                  :AddRegressionProcesses => true,
                  :AddRegressionSenders => true
                ) do |iError|
                  assert_equal( [
                      [ 'prepareFileTransfer', [ iTmpFileName ] ],
                      [ 'sendMessage', [ 'DummyUser', {
                            'DummyTool' => {
                              'DummyAction' => [
                                [ "#{iTmpFileName}_PREPARED" ]
                              ]
                            }
                          } ]
                      ]
                    ],
                    $Variables[:DummySenderCalls]
                  )
                  assert(!File.exists?(iTmpFileName))
                  assert_equal([], getSlaveClientQueue)
                  assert_equal({}, getTransferFiles)
                end
              end
            end
          end

          # Test 1 Action with a file transfer using a file already in the Transfer files
          def test1ActionWithFileTransferAlreadyRemanent
            initTestCase do
              setupTempFile do |iTmpFileName|
                $Context[:SlaveActions] = [
                  [ 'DummyTool', 'DummyAction', [WEACE::Master::TransferFile.new(iTmpFileName)] ]
                ]
                executeMaster( [ '--process', 'DummyProcess', '--user', 'DummyUser' ],
                  :Repository => 'Dummy/MasterServerInstalledWithDummySender',
                  :AddRegressionProcesses => true,
                  :AddRegressionSenders => true,
                  :AddTransferFiles => {
                    iTmpFileName => 1
                  }
                ) do |iError|
                  assert_equal( [
                      [ 'prepareFileTransfer', [ iTmpFileName ] ],
                      [ 'sendMessage', [ 'DummyUser', {
                            'DummyTool' => {
                              'DummyAction' => [
                                [ "#{iTmpFileName}_PREPARED" ]
                              ]
                            }
                          } ]
                      ]
                    ],
                    $Variables[:DummySenderCalls]
                  )
                  assert(File.exists?(iTmpFileName))
                  assert_equal([], getSlaveClientQueue)
                  assert_equal({iTmpFileName => 1}, getTransferFiles)
                end
              end
            end
          end

          # Test 1 failing Action with a file transfer using a file already in the Transfer files
          def test1FailActionWithFileTransferAlreadyRemanent
            initTestCase do
              setupTempFile do |iTmpFileName|
                lTransferFile = WEACE::Master::TransferFile.new(iTmpFileName)
                $Context[:SlaveActions] = [
                  [ 'DummyTool', 'DummyAction', [lTransferFile] ]
                ]
                $Context[:DummySenderSendError] = RuntimeError.new('Sending error')
                executeMaster( [ '--process', 'DummyProcess', '--user', 'DummyUser' ],
                  :Repository => 'Dummy/MasterServerInstalledWithDummySender',
                  :AddRegressionProcesses => true,
                  :AddRegressionSenders => true,
                  :AddTransferFiles => {
                    iTmpFileName => 1
                  },
                  :Error => RuntimeError
                ) do |iError|
                  assert_equal( [
                      [ 'prepareFileTransfer', [ iTmpFileName ] ],
                      [ 'sendMessage', [ 'DummyUser', {
                            'DummyTool' => {
                              'DummyAction' => [
                                [ "#{iTmpFileName}_PREPARED" ]
                              ]
                            }
                          } ]
                      ]
                    ],
                    $Variables[:DummySenderCalls]
                  )
                  assert(File.exists?(iTmpFileName))
                  assert_equal(
                    [
                      [ 'DummyUser',
                        { 'DummyTool' => {
                            'DummyAction' => [
                              [lTransferFile]
                            ]
                          }
                        }
                      ]
                    ],
                    getSlaveClientQueue
                  )
                  assert_equal({iTmpFileName => 2}, getTransferFiles)
                end
              end
            end
          end

          # Test 1 failing Action during prepare with a file transfer using a file already in the Transfer files
          def test1PrepareFailActionWithFileTransferAlreadyRemanent
            initTestCase do
              setupTempFile do |iTmpFileName|
                lTransferFile = WEACE::Master::TransferFile.new(iTmpFileName)
                $Context[:SlaveActions] = [
                  [ 'DummyTool', 'DummyAction', [lTransferFile] ]
                ]
                $Context[:DummySenderPrepareError] = RuntimeError.new('Preparing error')
                executeMaster( [ '--process', 'DummyProcess', '--user', 'DummyUser' ],
                  :Repository => 'Dummy/MasterServerInstalledWithDummySender',
                  :AddRegressionProcesses => true,
                  :AddRegressionSenders => true,
                  :AddTransferFiles => {
                    iTmpFileName => 1
                  },
                  :Error => RuntimeError
                ) do |iError|
                  assert_equal( [
                      [ 'prepareFileTransfer', [ iTmpFileName ] ]
                    ],
                    $Variables[:DummySenderCalls]
                  )
                  assert(File.exists?(iTmpFileName))
                  assert_equal(
                    [
                      [ 'DummyUser',
                        { 'DummyTool' => {
                            'DummyAction' => [
                              [lTransferFile]
                            ]
                          }
                        }
                      ]
                    ],
                    getSlaveClientQueue
                  )
                  assert_equal({iTmpFileName => 2}, getTransferFiles)
                end
              end
            end
          end

          # Test that Tools::All on the MasterServer filters in every tool
          def testToolsAll
            initTestCase do
              $Context[:SlaveActions] = [
                [ 'DummyTool', 'DummyAction', [] ]
              ]
              executeMaster( [ '--process', 'DummyProcess', '--user', 'DummyUser' ],
                :Repository => 'Dummy/MasterServerInstalledWithDummySender',
                :AddRegressionProcesses => true,
                :AddRegressionSenders => true
              ) do |iError|
                assert_equal( [
                    [ 'sendMessage', [ 'DummyUser', {
                          'DummyTool' => {
                            'DummyAction' => [
                              []
                            ]
                          }
                        } ]
                    ]
                  ],
                  $Variables[:DummySenderCalls]
                )
                assert_equal([], getSlaveClientQueue)
              end
            end
          end

          # Test that Tools::All on the MasterServer filters in Tools::All
          def testToolsAllWithAll
            initTestCase do
              $Context[:SlaveActions] = [
                [ Tools::All, 'DummyAction', [] ]
              ]
              executeMaster( [ '--process', 'DummyProcess', '--user', 'DummyUser' ],
                :Repository => 'Dummy/MasterServerInstalledWithDummySender',
                :AddRegressionProcesses => true,
                :AddRegressionSenders => true
              ) do |iError|
                assert_equal( [
                    [ 'sendMessage', [ 'DummyUser', {
                          Tools::All => {
                            'DummyAction' => [
                              []
                            ]
                          }
                        } ]
                    ]
                  ],
                  $Variables[:DummySenderCalls]
                )
                assert_equal([], getSlaveClientQueue)
              end
            end
          end

          # Test that Tools filtering works for an exact match
          def testExactMatch
            initTestCase do
              $Context[:SlaveActions] = [
                [ 'DummyTool', 'DummyAction', [] ]
              ]
              executeMaster( [ '--process', 'DummyProcess', '--user', 'DummyUser' ],
                :Repository => 'Dummy/MasterServerInstalledWithDummySenderFilterDummyTool',
                :AddRegressionProcesses => true,
                :AddRegressionSenders => true
              ) do |iError|
                assert_equal( [
                    [ 'sendMessage', [ 'DummyUser', {
                          'DummyTool' => {
                            'DummyAction' => [
                              []
                            ]
                          }
                        } ]
                    ]
                  ],
                  $Variables[:DummySenderCalls]
                )
                assert_equal([], getSlaveClientQueue)
              end
            end
          end

          # Test that Tools filtering works for an exact match with 2 Actions
          def testExactMatch2Actions
            initTestCase do
              $Context[:SlaveActions] = [
                [ 'DummyTool', 'DummyAction', [] ],
                [ 'DummyTool', 'DummyAction2', [] ]
              ]
              executeMaster( [ '--process', 'DummyProcess', '--user', 'DummyUser' ],
                :Repository => 'Dummy/MasterServerInstalledWithDummySenderFilterDummyTool',
                :AddRegressionProcesses => true,
                :AddRegressionSenders => true
              ) do |iError|
                assert_equal( [
                    [ 'sendMessage', [ 'DummyUser', {
                          'DummyTool' => {
                            'DummyAction' => [
                              []
                            ],
                            'DummyAction2' => [
                              []
                            ]
                          }
                        } ]
                    ]
                  ],
                  $Variables[:DummySenderCalls]
                )
                assert_equal([], getSlaveClientQueue)
              end
            end
          end

          # Test that Tools filtering works for an exact match with 2 parameters
          def testExactMatch2Parameters
            initTestCase do
              $Context[:SlaveActions] = [
                [ 'DummyTool', 'DummyAction', ['Param1'] ],
                [ 'DummyTool', 'DummyAction', ['Param2'] ]
              ]
              executeMaster( [ '--process', 'DummyProcess', '--user', 'DummyUser' ],
                :Repository => 'Dummy/MasterServerInstalledWithDummySenderFilterDummyTool',
                :AddRegressionProcesses => true,
                :AddRegressionSenders => true
              ) do |iError|
                assert_equal( [
                    [ 'sendMessage', [ 'DummyUser', {
                          'DummyTool' => {
                            'DummyAction' => [
                              ['Param1'],
                              ['Param2']
                            ]
                          }
                        } ]
                    ]
                  ],
                  $Variables[:DummySenderCalls]
                )
                assert_equal([], getSlaveClientQueue)
              end
            end
          end

          # Test that Tools filtering works for an exact difference
          def testExactDifference
            initTestCase do
              $Context[:SlaveActions] = [
                [ 'DummyTool2', 'DummyAction', [] ]
              ]
              executeMaster( [ '--process', 'DummyProcess', '--user', 'DummyUser' ],
                :Repository => 'Dummy/MasterServerInstalledWithDummySenderFilterDummyTool',
                :AddRegressionProcesses => true,
                :AddRegressionSenders => true
              ) do |iError|
                assert_equal(nil, $Variables[:DummySenderCalls])
                assert_equal([], getSlaveClientQueue)
              end
            end
          end

          # Test that Tools filtering works for an exact difference with 2 Actions
          def testExactDifference2Actions
            initTestCase do
              $Context[:SlaveActions] = [
                [ 'DummyTool2', 'DummyAction', [] ],
                [ 'DummyTool2', 'DummyAction2', [] ]
              ]
              executeMaster( [ '--process', 'DummyProcess', '--user', 'DummyUser' ],
                :Repository => 'Dummy/MasterServerInstalledWithDummySenderFilterDummyTool',
                :AddRegressionProcesses => true,
                :AddRegressionSenders => true
              ) do |iError|
                assert_equal(nil, $Variables[:DummySenderCalls])
                assert_equal([], getSlaveClientQueue)
              end
            end
          end

          # Test that Tools filtering works for an exact difference with 2 parameters
          def testExactDifference2Parameters
            initTestCase do
              $Context[:SlaveActions] = [
                [ 'DummyTool2', 'DummyAction', ['Param1'] ],
                [ 'DummyTool2', 'DummyAction', ['Param2'] ]
              ]
              executeMaster( [ '--process', 'DummyProcess', '--user', 'DummyUser' ],
                :Repository => 'Dummy/MasterServerInstalledWithDummySenderFilterDummyTool',
                :AddRegressionProcesses => true,
                :AddRegressionSenders => true
              ) do |iError|
                assert_equal(nil, $Variables[:DummySenderCalls])
                assert_equal([], getSlaveClientQueue)
              end
            end
          end

          # Test that Tools filtering works for 2 different Tools
          def testExactMatch1Of2
            initTestCase do
              $Context[:SlaveActions] = [
                [ 'DummyTool', 'DummyAction', [] ],
                [ 'DummyTool2', 'DummyAction2', [] ]
              ]
              executeMaster( [ '--process', 'DummyProcess', '--user', 'DummyUser' ],
                :Repository => 'Dummy/MasterServerInstalledWithDummySenderFilterDummyTool',
                :AddRegressionProcesses => true,
                :AddRegressionSenders => true
              ) do |iError|
                assert_equal( [
                    [ 'sendMessage', [ 'DummyUser', {
                          'DummyTool' => {
                            'DummyAction' => [
                              []
                            ]
                          }
                        } ]
                    ]
                  ],
                  $Variables[:DummySenderCalls]
                )
                assert_equal([], getSlaveClientQueue)
              end
            end
          end

          # Test that Tools filtering works with Tools::All
          def testExactMatchWithAll
            initTestCase do
              $Context[:SlaveActions] = [
                [ Tools::All, 'DummyAction', [] ]
              ]
              executeMaster( [ '--process', 'DummyProcess', '--user', 'DummyUser' ],
                :Repository => 'Dummy/MasterServerInstalledWithDummySenderFilterDummyTool',
                :AddRegressionProcesses => true,
                :AddRegressionSenders => true
              ) do |iError|
                assert_equal( [
                    [ 'sendMessage', [ 'DummyUser', {
                          Tools::All => {
                            'DummyAction' => [
                              []
                            ]
                          }
                        } ]
                    ]
                  ],
                  $Variables[:DummySenderCalls]
                )
                assert_equal([], getSlaveClientQueue)
              end
            end
          end

          # Test that when send fails, the queue still has the item
          def testSendFail
            initTestCase do
              $Context[:SlaveActions] = [
                [ 'DummyTool', 'DummyAction', [] ]
              ]
              $Context[:DummySenderSendError] = RuntimeError.new('Sending error')
              executeMaster( [ '--process', 'DummyProcess', '--user', 'DummyUser' ],
                :Repository => 'Dummy/MasterServerInstalledWithDummySender',
                :AddRegressionProcesses => true,
                :AddRegressionSenders => true,
                :Error => RuntimeError
              ) do |iError|
                assert_equal( [
                    [ 'sendMessage', [ 'DummyUser', {
                          'DummyTool' => {
                            'DummyAction' => [
                              []
                            ]
                          }
                        } ]
                    ]
                  ],
                  $Variables[:DummySenderCalls]
                )
                assert_equal(
                  [
                    [ 'DummyUser', 
                      { 'DummyTool' => {
                          'DummyAction' => [
                            []
                          ]
                        }
                      }
                    ]
                  ],
                  getSlaveClientQueue
                )
              end
            end
          end

          # Test that when send fails with a file, the file is not deleted
          def testSendFileFail
            initTestCase do
              setupTempFile do |iTmpFileName|
                lTransferFile = WEACE::Master::TransferFile.new(iTmpFileName)
                $Context[:SlaveActions] = [
                  [ 'DummyTool', 'DummyAction', [lTransferFile] ]
                ]
                $Context[:DummySenderSendError] = RuntimeError.new('Sending error')
                executeMaster( [ '--process', 'DummyProcess', '--user', 'DummyUser' ],
                  :Repository => 'Dummy/MasterServerInstalledWithDummySender',
                  :AddRegressionProcesses => true,
                  :AddRegressionSenders => true,
                  :Error => RuntimeError
                ) do |iError|
                  assert_equal( [
                      [ 'prepareFileTransfer', [ iTmpFileName ] ],
                      [ 'sendMessage', [ 'DummyUser', {
                            'DummyTool' => {
                              'DummyAction' => [
                                [ "#{iTmpFileName}_PREPARED" ]
                              ]
                            }
                          } ]
                      ]
                    ],
                    $Variables[:DummySenderCalls]
                  )
                  assert(File.exists?(iTmpFileName))
                  assert_equal(
                    [
                      [ 'DummyUser',
                        { 'DummyTool' => {
                            'DummyAction' => [
                              [lTransferFile]
                            ]
                          }
                        }
                      ]
                    ],
                    getSlaveClientQueue
                  )
                  assert_equal({iTmpFileName => 1}, getTransferFiles)
                end
              end
            end
          end

          # Test that when preparing file transfers fails, the file is not deleted
          def testPrepareFileFail
            initTestCase do
              setupTempFile do |iTmpFileName|
                lTransferFile = WEACE::Master::TransferFile.new(iTmpFileName)
                $Context[:SlaveActions] = [
                  [ 'DummyTool', 'DummyAction', [lTransferFile] ]
                ]
                $Context[:DummySenderPrepareError] = RuntimeError.new('Preparing error')
                executeMaster( [ '--process', 'DummyProcess', '--user', 'DummyUser' ],
                  :Repository => 'Dummy/MasterServerInstalledWithDummySender',
                  :AddRegressionProcesses => true,
                  :AddRegressionSenders => true,
                  :Error => RuntimeError
                ) do |iError|
                  assert_equal( [
                      [ 'prepareFileTransfer', [ iTmpFileName ] ]
                    ],
                    $Variables[:DummySenderCalls]
                  )
                  assert(File.exists?(iTmpFileName))
                  assert_equal(
                    [
                      [ 'DummyUser',
                        { 'DummyTool' => {
                            'DummyAction' => [
                              [lTransferFile]
                            ]
                          }
                        }
                      ]
                    ],
                    getSlaveClientQueue
                  )
                  assert_equal({iTmpFileName => 1}, getTransferFiles)
                end
              end
            end
          end

          # Test that when a queue is not empty, we send first waiting Actions
          def testWaitingActions
            initTestCase do
              $Context[:SlaveActions] = [
                [ 'DummyTool2', 'DummyAction2', [] ]
              ]
              executeMaster( [ '--process', 'DummyProcess', '--user', 'DummyUser2' ],
                :Repository => 'Dummy/MasterServerInstalledWithDummySender',
                :AddRegressionProcesses => true,
                :AddRegressionSenders => true,
                :AddSlaveClientQueues => {
                  {
                    :Type => 'DummySender',
                    :Tools => [
                      Tools::All
                    ]
                  } => [
                    [ 'DummyUser1',
                      {
                        'DummyTool1' => {
                          'DummyAction1' => [
                            []
                          ]
                        }
                      }
                    ]
                  ]
                }
              ) do |iError|
                assert_equal( [
                    [ 'sendMessage', [ 'DummyUser1', {
                          'DummyTool1' => {
                            'DummyAction1' => [
                              []
                            ]
                          }
                        } ]
                    ],
                    [ 'sendMessage', [ 'DummyUser2', {
                          'DummyTool2' => {
                            'DummyAction2' => [
                              []
                            ]
                          }
                        } ]
                    ]
                  ],
                  $Variables[:DummySenderCalls]
                )
                assert_equal([], getSlaveClientQueue)
              end
            end
          end

          # Test that when a queue is not empty, subsequent Actions are on hold
          def testWaitingActionsOnHold
            initTestCase do
              $Context[:SlaveActions] = [
                [ 'DummyTool2', 'DummyAction2', [] ]
              ]
              $Context[:DummySenderSendError] = RuntimeError.new('Sending error')
              executeMaster( [ '--process', 'DummyProcess', '--user', 'DummyUser2' ],
                :Repository => 'Dummy/MasterServerInstalledWithDummySender',
                :AddRegressionProcesses => true,
                :AddRegressionSenders => true,
                :AddSlaveClientQueues => {
                  {
                    :Type => 'DummySender',
                    :Tools => [
                      Tools::All
                    ]
                  } => [
                    [ 'DummyUser1',
                      {
                        'DummyTool1' => {
                          'DummyAction1' => [
                            []
                          ]
                        }
                      }
                    ]
                  ]
                },
                :Error => RuntimeError
              ) do |iError|
                assert_equal( [
                    [ 'sendMessage', [ 'DummyUser1', {
                          'DummyTool1' => {
                            'DummyAction1' => [
                              []
                            ]
                          }
                        } ]
                    ]
                  ],
                  $Variables[:DummySenderCalls]
                )
                assert_equal(
                  [
                    [ 'DummyUser1',
                      { 'DummyTool1' => {
                          'DummyAction1' => [
                            []
                          ]
                        }
                      }
                    ],
                    [ 'DummyUser2',
                      { 'DummyTool2' => {
                          'DummyAction2' => [
                            []
                          ]
                        }
                      }
                    ]
                  ],
                  getSlaveClientQueue
                )
              end
            end
          end

          # Test the sending occurs to several configured SlaveClients
          def testSeveralSlaveClients
            initTestCase do
              $Context[:SlaveActions] = [
                [ 'DummyTool', 'DummyAction', [] ]
              ]
              executeMaster( [ '--process', 'DummyProcess', '--user', 'DummyUser' ],
                :Repository => 'Dummy/MasterServerInstalledWith2SlaveClients',
                :AddRegressionProcesses => true,
                :AddRegressionSenders => true
              ) do |iError|
                assert_equal(
                  {
                    'SlaveClient1' => [
                      [ 'sendMessage', [ 'DummyUser', {
                          'DummyTool' => {
                            'DummyAction' => [
                              []
                            ]
                          }
                        } ] ]
                      ],
                    'SlaveClient2' => [
                      [ 'sendMessage', [ 'DummyUser', {
                          'DummyTool' => {
                            'DummyAction' => [
                              []
                            ]
                          }
                        } ] ]
                      ]
                  },
                  $Variables[:DummySenderCalls]
                )
                assert_equal([], getSlaveClientQueue)
              end
            end
          end

          # Test several SlaveActions occur to several configured SlaveClients
          def testSeveralSlaveClients2Actions
            initTestCase do
              $Context[:SlaveActions] = [
                [ 'DummyTool1', 'DummyAction1', [] ],
                [ 'DummyTool2', 'DummyAction2', [] ]
              ]
              executeMaster( [ '--process', 'DummyProcess', '--user', 'DummyUser' ],
                :Repository => 'Dummy/MasterServerInstalledWith2SlaveClients',
                :AddRegressionProcesses => true,
                :AddRegressionSenders => true
              ) do |iError|
                assert_equal(
                  {
                    'SlaveClient1' => [
                      [ 'sendMessage', [
                          'DummyUser',
                          {
                            'DummyTool1' => {
                              'DummyAction1' => [
                                []
                              ]
                            },
                            'DummyTool2' => {
                              'DummyAction2' => [
                                []
                              ]
                            }
                          } ] ]
                      ],
                    'SlaveClient2' => [
                      [ 'sendMessage', [
                          'DummyUser',
                          {
                            'DummyTool1' => {
                              'DummyAction1' => [
                                []
                              ]
                            },
                            'DummyTool2' => {
                              'DummyAction2' => [
                                []
                              ]
                            }
                          } ] ]
                      ]
                  },
                  $Variables[:DummySenderCalls]
                )
                assert_equal([], getSlaveClientQueue)
              end
            end
          end

          # Test the sending is filtered differently for several configured SlaveClients
          def testSeveralSlaveClientsDifferentFilters
            initTestCase do
              $Context[:SlaveActions] = [
                [ 'DummyTool1', 'DummyAction', [] ]
              ]
              executeMaster( [ '--process', 'DummyProcess', '--user', 'DummyUser' ],
                :Repository => 'Dummy/MasterServerInstalledWith2SlaveClientsFilters',
                :AddRegressionProcesses => true,
                :AddRegressionSenders => true
              ) do |iError|
                assert_equal(
                  {
                    'SlaveClient1' => [
                      [ 'sendMessage', [ 'DummyUser', {
                            'DummyTool1' => {
                              'DummyAction' => [
                                []
                              ]
                            }
                          } ] ]
                    ]
                  },
                  $Variables[:DummySenderCalls]
                )
                assert_equal([], getSlaveClientQueue)
              end
            end
          end

          # Test several sendings are filtered differently for several configured SlaveClients
          def testSeveralSlaveClients2ActionsDifferentFilters
            initTestCase do
              $Context[:SlaveActions] = [
                [ 'DummyTool1', 'DummyAction1', [] ],
                [ 'DummyTool2', 'DummyAction2', [] ]
              ]
              executeMaster( [ '--process', 'DummyProcess', '--user', 'DummyUser' ],
                :Repository => 'Dummy/MasterServerInstalledWith2SlaveClientsFilters',
                :AddRegressionProcesses => true,
                :AddRegressionSenders => true
              ) do |iError|
                assert_equal(
                  {
                    'SlaveClient1' => [
                      [ 'sendMessage', [ 'DummyUser', {
                            'DummyTool1' => {
                              'DummyAction1' => [
                                []
                              ]
                            }
                          } ] ]
                    ],
                    'SlaveClient2' => [
                      [ 'sendMessage', [ 'DummyUser', {
                          'DummyTool2' => {
                            'DummyAction2' => [
                              []
                            ]
                          }
                        } ] ]
                    ]
                  },
                  $Variables[:DummySenderCalls]
                )
                assert_equal([], getSlaveClientQueue)
              end
            end
          end

          # Test when several SlaveClients are configured and some fail, others continue
          def testSeveralSlaveClients1Fail
            initTestCase do
              $Context[:SlaveActions] = [
                [ 'DummyTool', 'DummyAction', [] ]
              ]
              $Context[:DummySenderSendError] = {
                'SlaveClient1' => RuntimeError.new('Sending error')
              }
              executeMaster( [ '--process', 'DummyProcess', '--user', 'DummyUser' ],
                :Repository => 'Dummy/MasterServerInstalledWith2SlaveClients',
                :AddRegressionProcesses => true,
                :AddRegressionSenders => true,
                :Error => RuntimeError
              ) do |iError|
                assert_equal(
                  {
                    'SlaveClient1' => [
                      [ 'sendMessage', [ 'DummyUser', {
                            'DummyTool' => {
                              'DummyAction' => [
                                []
                              ]
                            }
                          } ] ]
                    ],
                    'SlaveClient2' => [
                      [ 'sendMessage', [ 'DummyUser', {
                            'DummyTool' => {
                              'DummyAction' => [
                                []
                              ]
                            }
                          } ] ]
                    ]
                  },
                  $Variables[:DummySenderCalls]
                )
                assert_equal(
                  {
                    {
                      :Type => 'DummySender',
                      :Tools => [
                        Tools::All
                      ],
                      :PersoParam => 'SlaveClient1'
                    } => [
                      [ 'DummyUser', {
                          'DummyTool' => {
                            'DummyAction' => [
                              []
                            ]
                          }
                        } ]
                    ]
                  },
                  getSlaveClientQueues
                )
              end
            end
          end

          # Test when several SlaveClients are configured and some fail during a file prepare, others continue
          def testSeveralSlaveClients1FailDuringPrepare
            initTestCase do
              setupTempFile do |iTmpFileName|
                lTransferFile = WEACE::Master::TransferFile.new(iTmpFileName)
                $Context[:SlaveActions] = [
                  [ 'DummyTool', 'DummyAction', [lTransferFile] ]
                ]
                $Context[:DummySenderPrepareError] = {
                  'SlaveClient1' => RuntimeError.new('Preparing error')
                }
                executeMaster( [ '--process', 'DummyProcess', '--user', 'DummyUser' ],
                  :Repository => 'Dummy/MasterServerInstalledWith2SlaveClients',
                  :AddRegressionProcesses => true,
                  :AddRegressionSenders => true,
                  :Error => RuntimeError
                ) do |iError|
                  assert_equal(
                    {
                      'SlaveClient1' => [
                        [ 'prepareFileTransfer', [ iTmpFileName ] ]
                      ],
                      'SlaveClient2' => [
                        [ 'prepareFileTransfer', [ iTmpFileName ] ],
                        [ 'sendMessage', [ 'DummyUser', {
                              'DummyTool' => {
                                'DummyAction' => [
                                  [ "#{iTmpFileName}_PREPARED" ]
                                ]
                              }
                            } ] ]
                      ]
                    },
                    $Variables[:DummySenderCalls]
                  )
                  assert(File.exists?(iTmpFileName))
                  assert_equal(
                    {
                      {
                        :Type => 'DummySender',
                        :Tools => [
                          Tools::All
                        ],
                        :PersoParam => 'SlaveClient1'
                      } => [
                        [ 'DummyUser', {
                            'DummyTool' => {
                              'DummyAction' => [
                                [lTransferFile]
                              ]
                            }
                          } ]
                      ]
                    },
                    getSlaveClientQueues
                  )
                  assert_equal({iTmpFileName => 1}, getTransferFiles)
                end
              end
            end
          end

          # Test that even if a file has been transfered, it won't be deleted if its counter is still >1
          def testPreparedFileRemanent
            initTestCase do
              setupTempFile do |iTmpFileName|
                lTransferFile = WEACE::Master::TransferFile.new(iTmpFileName)
                $Context[:SlaveActions] = [
                  [ 'DummyTool', 'DummyAction', [lTransferFile] ]
                ]
                executeMaster( [ '--process', 'DummyProcess', '--user', 'DummyUser' ],
                  :Repository => 'Dummy/MasterServerInstalledWithDummySender',
                  :AddRegressionProcesses => true,
                  :AddRegressionSenders => true,
                  :AddTransferFiles => {
                    iTmpFileName => 1
                  }
                ) do |iError|
                  assert_equal(
                    [
                      [ 'prepareFileTransfer', [ iTmpFileName ] ],
                      [ 'sendMessage', [ 'DummyUser', {
                            'DummyTool' => {
                              'DummyAction' => [
                                [ "#{iTmpFileName}_PREPARED" ]
                              ]
                            }
                          } ] ]
                    ],
                    $Variables[:DummySenderCalls]
                  )
                  assert(File.exists?(iTmpFileName))
                  assert_equal([], getSlaveClientQueue)
                  assert_equal({iTmpFileName => 1}, getTransferFiles)
                end
              end
            end
          end

          # Test that we can resume processing a queue using --send option
          def testResumeSlaveClientQueue
            initTestCase do
              executeMaster( [ '--send' ],
                :Repository => 'Dummy/MasterServerInstalledWithDummySender',
                :AddRegressionProcesses => true,
                :AddRegressionSenders => true,
                :AddSlaveClientQueues => {
                  {
                    :Type => 'DummySender',
                    :Tools => [
                      Tools::All
                    ]
                  } => [
                    [ 'DummyUser1',
                      {
                        'DummyTool1' => {
                          'DummyAction1' => [
                            []
                          ]
                        }
                      }
                    ]
                  ]
                }
              ) do |iError|
                assert_equal( [
                    [ 'sendMessage', [ 'DummyUser1', {
                          'DummyTool1' => {
                            'DummyAction1' => [
                              []
                            ]
                          }
                        } ]
                    ]
                  ],
                  $Variables[:DummySenderCalls]
                )
                assert_equal([], getSlaveClientQueue)
              end
            end
          end

          # Test that we can resume processing of several queues using --send option
          def testResumeSlaveClientQueues
            initTestCase do
              executeMaster( [ '--send' ],
                :Repository => 'Dummy/MasterServerInstalledWith2SlaveClients',
                :AddRegressionProcesses => true,
                :AddRegressionSenders => true,
                :AddSlaveClientQueues => {
                  {
                    :Type => 'DummySender',
                    :Tools => [
                      Tools::All
                    ],
                    :PersoParam => 'SlaveClient1'
                  } => [
                    [ 'DummyUser1',
                      {
                        'DummyTool1' => {
                          'DummyAction1' => [
                            []
                          ]
                        }
                      }
                    ]
                  ],
                  {
                    :Type => 'DummySender',
                    :Tools => [
                      Tools::All
                    ],
                    :PersoParam => 'SlaveClient2'
                  } => [
                    [ 'DummyUser2',
                      {
                        'DummyTool2' => {
                          'DummyAction2' => [
                            []
                          ]
                        }
                      }
                    ]
                  ]
                }
              ) do |iError|
                assert_equal(
                  {
                    'SlaveClient1' => [
                      [ 'sendMessage', [ 'DummyUser1', {
                            'DummyTool1' => {
                              'DummyAction1' => [
                                []
                              ]
                            }
                          } ] ]
                    ],
                    'SlaveClient2' => [
                      [ 'sendMessage', [ 'DummyUser2', {
                            'DummyTool2' => {
                              'DummyAction2' => [
                                []
                              ]
                            }
                          } ] ]
                    ]
                  },
                  $Variables[:DummySenderCalls]
                )
                assert_equal({}, getSlaveClientQueues)
              end
            end
          end

          # Test that we can resume processing of several queues using --send option, with 1 remaining failed
          def testResumeSlaveClientQueues1Of2
            initTestCase do
              $Context[:DummySenderSendError] = {
                'SlaveClient1' => RuntimeError.new('Sending error')
              }
              executeMaster( [ '--send' ],
                :Repository => 'Dummy/MasterServerInstalledWith2SlaveClients',
                :AddRegressionProcesses => true,
                :AddRegressionSenders => true,
                :AddSlaveClientQueues => {
                  {
                    :Type => 'DummySender',
                    :Tools => [
                      Tools::All
                    ],
                    :PersoParam => 'SlaveClient1'
                  } => [
                    [ 'DummyUser1',
                      {
                        'DummyTool1' => {
                          'DummyAction1' => [
                            []
                          ]
                        }
                      }
                    ]
                  ],
                  {
                    :Type => 'DummySender',
                    :Tools => [
                      Tools::All
                    ],
                    :PersoParam => 'SlaveClient2'
                  } => [
                    [ 'DummyUser2',
                      {
                        'DummyTool2' => {
                          'DummyAction2' => [
                            []
                          ]
                        }
                      }
                    ]
                  ]
                },
                :Error => RuntimeError
              ) do |iError|
                assert_equal(
                  {
                    'SlaveClient1' => [
                      [ 'sendMessage', [ 'DummyUser1', {
                            'DummyTool1' => {
                              'DummyAction1' => [
                                []
                              ]
                            }
                          } ] ]
                    ],
                    'SlaveClient2' => [
                      [ 'sendMessage', [ 'DummyUser2', {
                            'DummyTool2' => {
                              'DummyAction2' => [
                                []
                              ]
                            }
                          } ] ]
                    ]
                  },
                  $Variables[:DummySenderCalls]
                )
                assert_equal(
                  {
                    {
                      :Type => 'DummySender',
                      :Tools => [
                        Tools::All
                      ],
                      :PersoParam => 'SlaveClient1'
                    } => [
                      [ 'DummyUser1',
                        {
                          'DummyTool1' => {
                            'DummyAction1' => [
                              []
                            ]
                          }
                        }
                      ]
                    ]
                  },
                  getSlaveClientQueues
                )
              end
            end
          end

          # Test that resuming a failing processing queue using --send option does not alter the queue
          def testResumeSlaveClientQueueFail
            initTestCase do
              $Context[:DummySenderSendError] = RuntimeError.new('Sending error')
              executeMaster( [ '--send' ],
                :Repository => 'Dummy/MasterServerInstalledWithDummySender',
                :AddRegressionProcesses => true,
                :AddRegressionSenders => true,
                :AddSlaveClientQueues => {
                  {
                    :Type => 'DummySender',
                    :Tools => [
                      Tools::All
                    ]
                  } => [
                    [ 'DummyUser1',
                      {
                        'DummyTool1' => {
                          'DummyAction1' => [
                            []
                          ]
                        }
                      }
                    ]
                  ]
                },
                :Error => RuntimeError
              ) do |iError|
                assert_equal( [
                    [ 'sendMessage', [ 'DummyUser1', {
                          'DummyTool1' => {
                            'DummyAction1' => [
                              []
                            ]
                          }
                        } ]
                    ]
                  ],
                  $Variables[:DummySenderCalls]
                )
                assert_equal(
                  [
                    [ 'DummyUser1', {
                        'DummyTool1' => {
                          'DummyAction1' => [
                            []
                          ]
                        }
                      } ]
                  ],
                  getSlaveClientQueue
                )
              end
            end
          end

          # Test that we can resume processing a queue with file transfer using --send option
          def testResumeSlaveClientQueueWithFile
            initTestCase do
              setupTempFile(false) do |iTmpFileName|
                lTransferFile = WEACE::Master::TransferFile.new(iTmpFileName)
                executeMaster( [ '--send' ],
                  :Repository => 'Dummy/MasterServerInstalledWithDummySender',
                  :AddRegressionProcesses => true,
                  :AddRegressionSenders => true,
                  :AddSlaveClientQueues => {
                    {
                      :Type => 'DummySender',
                      :Tools => [
                        Tools::All
                      ]
                    } => [
                      [ 'DummyUser1',
                        {
                          'DummyTool1' => {
                            'DummyAction1' => [
                              [lTransferFile]
                            ]
                          }
                        }
                      ]
                    ]
                  },
                  :AddTransferFiles => {
                    iTmpFileName => 1
                  }
                ) do |iError|
                  assert_equal( [
                      [ 'prepareFileTransfer', [ iTmpFileName ] ],
                      [ 'sendMessage', [ 'DummyUser1', {
                            'DummyTool1' => {
                              'DummyAction1' => [
                                ["#{iTmpFileName}_PREPARED"]
                              ]
                            }
                          } ]
                      ]
                    ],
                    $Variables[:DummySenderCalls]
                  )
                  assert(!File.exists?(iTmpFileName))
                  assert_equal([], getSlaveClientQueue)
                  assert_equal({}, getTransferFiles)
                end
              end
            end
          end

          # Test that resuming a failing processing queue using --send option does not alter the queue even with a file
          def testResumeSlaveClientQueueFailWithFile
            initTestCase do
              setupTempFile do |iTmpFileName|
                lTransferFile = WEACE::Master::TransferFile.new(iTmpFileName)
                $Context[:DummySenderSendError] = RuntimeError.new('Sending error')
                executeMaster( [ '--send' ],
                  :Repository => 'Dummy/MasterServerInstalledWithDummySender',
                  :AddRegressionProcesses => true,
                  :AddRegressionSenders => true,
                  :AddSlaveClientQueues => {
                    {
                      :Type => 'DummySender',
                      :Tools => [
                        Tools::All
                      ]
                    } => [
                      [ 'DummyUser1',
                        {
                          'DummyTool1' => {
                            'DummyAction1' => [
                              [lTransferFile]
                            ]
                          }
                        }
                      ]
                    ]
                  },
                  :AddTransferFiles => {
                    iTmpFileName => 1
                  },
                  :Error => RuntimeError
                ) do |iError|
                  assert_equal( [
                      [ 'prepareFileTransfer', [ iTmpFileName ] ],
                      [ 'sendMessage', [ 'DummyUser1', {
                            'DummyTool1' => {
                              'DummyAction1' => [
                                ["#{iTmpFileName}_PREPARED"]
                              ]
                            }
                          } ]
                      ]
                    ],
                    $Variables[:DummySenderCalls]
                  )
                  assert(File.exists?(iTmpFileName))
                  assert_equal(
                    [
                      [ 'DummyUser1', {
                          'DummyTool1' => {
                            'DummyAction1' => [
                              [lTransferFile]
                            ]
                          }
                        } ]
                    ],
                    getSlaveClientQueue
                  )
                  assert_equal({iTmpFileName => 1}, getTransferFiles)
                end
              end
            end
          end

        end

      end

    end

  end

end
