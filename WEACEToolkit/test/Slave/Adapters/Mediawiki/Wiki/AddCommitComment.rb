# Usage: This file is used by other files.
# Do not call it directly.
#
# Check http://weacemethod.sourceforge.net for details.
#--
# Copyright (c) 2009 - 2012 Muriel Salvan  (muriel@x-aeon.com)
# Licensed under BSD LICENSE. No warranty is provided.
#++

require "#{File.dirname(__FILE__)}/../Common"

module WEACE

  module Test

    module Slave

      module Adapters

        module Mediawiki

          module Wiki

            class AddCommitComment < ::Test::Unit::TestCase

              include WEACE::Test::Slave::Common
              include WEACE::Test::Slave::GenericAdapters::Wiki::AddCommitComment
              include WEACE::Test::Slave::Adapters::Mediawiki::Common

              # Prepare the plugin's execution
              #
              # Parameters::
              # * *iUserID* (_String_): User ID of the script adding this info
              # * *iBranchName* (_String_): Name of the branch receiving the commit
              # * *iCommitID* (_String_): The commit ID
              # * *iCommitUser* (_String_): The commit user
              # * *iCommitComment* (_String_): The commit comment
              # * *CodeBlock*: Code to call once preparation has been made
              def prepareExecution(iUserID, iBranchName, iCommitID, iCommitUser, iCommitComment)
                # Catch `` executions
                WEACE::Test::Common::changeMethod(
                  Kernel,
                  :`,
                  :backquote_regression
                ) do
                  if ($Context[:WikiContent] == nil)
                    $Context[:OS_ExecAnswers] = [
                      [ 0, '' ],
                      [ 0, 'Saving... done' ]
                    ]
                  else
                    $Context[:OS_ExecAnswers] = [
                      [ 0, $Context[:WikiContent] ],
                      [ 0, 'Saving... done' ]
                    ]
                  end
                  # Set the new content to match if it wasn't already set by a test case.
                  if ($Context[:NewWikiContentRegExp] == nil)
                    $Context[:NewWikiContentRegExp] =
                      Regexp.escape('* <code><small>[') +
                      '....-..-.. ..:..:..' +
                      Regexp.escape("]</small></code> - Commit #{iCommitID} by #{iCommitUser}: #{iCommitComment}")
                  end
                  yield
                end
              end

              # Check the last commit comment
              #
              # Parameters::
              # * *iUserID* (_String_): User ID of the script adding this info
              # * *iBranchName* (_String_): Name of the branch receiving the commit
              # * *iCommitID* (_String_): The commit ID
              # * *iCommitUser* (_String_): The commit user
              # * *iCommitComment* (_String_): The commit comment
              def checkData(iUserID, iBranchName, iCommitID, iCommitUser, iCommitComment)
                checkCallsMatch(
                  [
                    [ 'query', "php %{WEACELibDir}/Slave/Adapters/Mediawiki/Mediawiki_getContent.php /path/to/Mediawiki Changelog_#{iBranchName}" ],
                    [ 'query', Regexp.new('^' + Regexp.escape('echo "') + $Context[:NewWikiContentRegExp] + Regexp.escape("\" | php /path/to/Mediawiki/maintenance/edit.php -u #{iUserID} -s 'Automatic addition upon commit #{iCommitID} by #{iCommitUser}' Changelog_#{iBranchName}") + '$')]
                  ],
                  $Variables[:OS_Exec]
                )
              end

              # Additional test cases

              # Test normal behaviour with a page having unknown content
              def testNormalWithUnknownContent
                initTestCase do
                  $Context[:WikiContent] = "UnknownContent - Line 1\nUnknownContent - Line 2"
                  $Context[:NewWikiContentRegExp] =
                    Regexp.escape('* <code><small>[') +
                    '....-..-.. ..:..:..' +
                    Regexp.escape("]</small></code> - Commit DummyCommitID by DummyCommitUser: DummyCommitComment\nUnknownContent - Line 1\nUnknownContent - Line 2")
                  execTest(
                    'DummyUserID',
                    [
                      'BranchName',
                      'DummyCommitID',
                      'DummyCommitUser',
                      'DummyCommitComment'
                    ]
                  )
                end
              end

              # Test normal behaviour with a page having known content
              def testNormalWithKnownContent
                initTestCase do
                  $Context[:WikiContent] = "UnknownContent - Line 1\n=== Current ===\n\nUnknownContent - Line 3"
                  $Context[:NewWikiContentRegExp] =
                    Regexp.escape("UnknownContent - Line 1\n=== Current ===\n\n* <code><small>[") +
                    '....-..-.. ..:..:..' +
                    Regexp.escape("]</small></code> - Commit DummyCommitID by DummyCommitUser: DummyCommitComment\nUnknownContent - Line 3")
                  execTest(
                    'DummyUserID',
                    [
                      'BranchName',
                      'DummyCommitID',
                      'DummyCommitUser',
                      'DummyCommitComment'
                    ]
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
