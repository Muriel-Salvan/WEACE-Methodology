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

            class Ping < ::Test::Unit::TestCase

              include WEACE::Test::Slave::Adapters::Common
              include WEACE::Test::Slave::Adapters::Mediawiki::Common

              # Test normal behaviour with an empty page
              def testNormalWithEmptyContent
                executeSlaveAdapterMediawiki(
                  {
                    :MediaWikiInstallationDir => '/home/groups/m/my/myproject/mediawiki'
                  },
                  [ 'DummyComment' ],
                  :OSExecAnswers => [
                    '',
                    ''
                  ]
                ) do |iError|
                  checkCallsMatch(
                    [
                      [ 'query', 'php ../Mediawiki_getContent.php /home/groups/m/my/myproject/mediawiki Tester_Log' ],
                      [ 'query', /^echo '\* \[....-..-.. ..:..:..\] - Ping Mediawiki\/Wiki: DummyComment' \| php \/home\/groups\/m\/my\/myproject\/mediawiki\/maintenance\/edit\.php -u DummyUser -s 'Automatic addition upon ping' Tester_Log$/]
                    ],
                    $Variables[:OS_Exec]
                  )
                end
              end

              # Test normal behaviour with a page having content
              def testNormalWithContent
                executeSlaveAdapterMediawiki(
                  {
                    :MediaWikiInstallationDir => '/home/groups/m/my/myproject/mediawiki'
                  },
                  [ 'DummyComment' ],
                  :OSExecAnswers => [
                    "Content - Line 1\nContent - Line 2",
                    ''
                  ]
                ) do |iError|
                  checkCallsMatch(
                    [
                      [ 'query', 'php ../Mediawiki_getContent.php /home/groups/m/my/myproject/mediawiki Tester_Log' ],
                      [ 'query', /^echo 'Content - Line 1\nContent - Line 2\n\* \[....-..-.. ..:..:..\] - Ping Mediawiki\/Wiki: DummyComment' \| php \/home\/groups\/m\/my\/myproject\/mediawiki\/maintenance\/edit\.php -u DummyUser -s 'Automatic addition upon commit ping' Tester_Log$/]
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
