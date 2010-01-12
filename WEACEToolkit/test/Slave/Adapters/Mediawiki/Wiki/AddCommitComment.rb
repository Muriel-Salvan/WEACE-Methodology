# Usage: This file is used by other files.
# Do not call it directly.
#
# Check http://weacemethod.sourceforge.net for details.
#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

module Kernel

  # Execute a command on the OS.
  #
  # Parameters:
  # * *iCommand* (_String_): The command to execute
  # Return:
  # * _String_: The result
  def backquote_regression(iCommand)
    rResult = ''

    # Record the query
    if ($Variables[:OS_Exec] == nil)
      $Variables[:OS_Exec] = []
    end
    $Variables[:OS_Exec] << [ 'query', iCommand ]

    # Send an automated answer
    if ($WEACERegression_ExecAnswers.empty?)
      $Variables[:OS_Exec] << [ 'error', "ERROR: Execution of command \"#{iCommand}\" is not prepared by WEACE Regression." ]
    else
      rResult = $WEACERegression_ExecAnswers[0]
      $WEACERegression_ExecAnswers.delete_at(0)
    end
    
    return rResult
  end

end

module WEACE

  module Test

    module Slave

      module Adapters

        module Mediawiki

          module Wiki

            class AddCommitComment < ::Test::Unit::TestCase

              include WEACE::Test::Slave::Adapters::Common

              # Execute a test for Mediawiki Slave Adapters
              #
              # Parameters:
              # * *iProductConfig* (<em>map<Symbol,Object></em>): The Product configuration
              # * *iParameters* (<em>list<String></em>): Parameters given to the Adapter
              # * *iOptions* (<em>map<Symbol,Object></em>): Options [optional = {}]
              # ** *:OSExecAnswers* (<em>list<String></em>): List of answers calls to `` have to return [optional = []]
              # * *CodeBlock*: The code called once the Adapter has been executed [optional = nil]:
              # ** *iError* (_Exception_): Error returned by the Adapter.
              def executeSlaveAdapterMediawiki(iProductConfig, iParameters, iOptions = {}, &iCodeCheck)
                # Parse options
                lOSExecAnswers = iOptions[:OSExecAnswers]
                if (lOSExecAnswers == nil)
                  lOSExecAnswers = []
                end

                # Catch `` executions
                WEACE::Test::Common::changeMethod(
                  Kernel,
                  :`,
                  :backquote_regression,
                  true
                ) do
                  $WEACERegression_ExecAnswers = lOSExecAnswers
                  executeSlaveAdapter(
                    iProductConfig,
                    iParameters
                  ) do |iError|
                    if (iCodeCheck != nil)
                      iCodeCheck.call(iError)
                    end
                  end
                end
              end

              # Test normal behaviour with an empty page
              def testNormalWithEmptyContent
                executeSlaveAdapterMediawiki(
                  {
                    :MediaWikiInstallationDir => '/home/groups/m/my/myproject/mediawiki'
                  },
                  [ '123', 'DummyBranchName', 'DummyCommitID', 'DummyCommitUser', 'DummyCommitComment' ],
                  :OSExecAnswers => [
                    '',
                    ''
                  ]
                ) do |iError|
                  checkCallsMatch(
                    [
                      [ 'query', 'php ../Mediawiki_getContent.php /home/groups/m/my/myproject/mediawiki Changelog_DummyBranchName' ],
                      [ 'query', /^echo '\* <code><small>\[....-..-.. ..:..:..\]<\/small><\/code> - Commit DummyCommitID by DummyCommitUser: DummyCommitComment' \| php \/home\/groups\/m\/my\/myproject\/mediawiki\/maintenance\/edit\.php -u DummyUser -s 'Automatic addition upon commit DummyCommitID by DummyCommitUser' Changelog_DummyBranchName$/]
                    ],
                    $Variables[:OS_Exec]
                  )
                end
              end

              # Test normal behaviour with a page having unknown content
              def testNormalWithUnknownContent
                executeSlaveAdapterMediawiki(
                  {
                    :MediaWikiInstallationDir => '/home/groups/m/my/myproject/mediawiki'
                  },
                  [ '123', 'DummyBranchName', 'DummyCommitID', 'DummyCommitUser', 'DummyCommitComment' ],
                  :OSExecAnswers => [
                    "UnknownContent - Line 1\nUnknownContent - Line 2",
                    ''
                  ]
                ) do |iError|
                  checkCallsMatch(
                    [
                      [ 'query', 'php ../Mediawiki_getContent.php /home/groups/m/my/myproject/mediawiki Changelog_DummyBranchName' ],
                      [ 'query', /^echo '\* <code><small>\[....-..-.. ..:..:..\]<\/small><\/code> - Commit DummyCommitID by DummyCommitUser: DummyCommitComment\nUnknownContent - Line 1\nUnknownContent - Line 2' \| php \/home\/groups\/m\/my\/myproject\/mediawiki\/maintenance\/edit\.php -u DummyUser -s 'Automatic addition upon commit DummyCommitID by DummyCommitUser' Changelog_DummyBranchName$/]
                    ],
                    $Variables[:OS_Exec]
                  )
                end
              end

              # Test normal behaviour with a page having known content
              def testNormalWithKnownContent
                executeSlaveAdapterMediawiki(
                  {
                    :MediaWikiInstallationDir => '/home/groups/m/my/myproject/mediawiki'
                  },
                  [ '123', 'DummyBranchName', 'DummyCommitID', 'DummyCommitUser', 'DummyCommitComment' ],
                  :OSExecAnswers => [
                    "UnknownContent - Line 1\n=== Current ===\n\nUnknownContent - Line 3",
                    ''
                  ]
                ) do |iError|
                  checkCallsMatch(
                    [
                      [ 'query', 'php ../Mediawiki_getContent.php /home/groups/m/my/myproject/mediawiki Changelog_DummyBranchName' ],
                      [ 'query', /^echo 'UnknownContent - Line 1\n=== Current ===\n\n\* <code><small>\[....-..-.. ..:..:..\]<\/small><\/code> - Commit DummyCommitID by DummyCommitUser: DummyCommitComment\nUnknownContent - Line 3' \| php \/home\/groups\/m\/my\/myproject\/mediawiki\/maintenance\/edit\.php -u DummyUser -s 'Automatic addition upon commit DummyCommitID by DummyCommitUser' Changelog_DummyBranchName$/]
                    ],
                    $Variables[:OS_Exec]
                  )
                end
              end

            end

          end

        end

      end

    end

  end

end
