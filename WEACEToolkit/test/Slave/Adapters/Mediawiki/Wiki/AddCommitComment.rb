# Usage: This file is used by other files.
# Do not call it directly.
#
# Check http://weacemethod.sourceforge.net for details.
#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
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

              include WEACE::Test::Slave::Adapters::Common
              include WEACE::Test::Slave::Adapters::Mediawiki::Common

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
