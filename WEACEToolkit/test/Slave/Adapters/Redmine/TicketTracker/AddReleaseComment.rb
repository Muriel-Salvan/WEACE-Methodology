# Usage: This file is used by other files.
# Do not call it directly.
#
# Check http://weacemethod.sourceforge.net for details.
#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

module WEACE

  module Test

    module Slave

      module Adapters

        module Redmine

          module TicketTracker

#            class AddReleaseComment < ::Test::Unit::TestCase
#
#              include WEACE::Test::Slave::Adapters::Common
#
#              # Test normal behaviour
#              def testNormal
#                executeSlaveAdapter(
#                  {
#                    :RedmineDir => '/home/groups/m/my/myproject/redmine',
#                    :DBHost => 'DummyHost',
#                    :DBName => 'DummyDBName',
#                    :DBUser => 'DummyDBUser',
#                    :DBPassword => 'DummyDBPassword'
#                  },
#                  [ '123', 'DummyBranchName', '0.0.1.20100112', 'DummyReleaseUser', 'DummyReleaseComment' ],
#                  :CatchMySQL => true,
#                  :DummySQLAnswers => [
#                    [ # Select
#                      [ 666 ]
#                    ],
#                    [ # Insert
#                    ]
#                  ]
#                ) do |iError|
#                  assert($Variables[:MySQLExecs] != nil)
#                  assert($Variables[:MySQLExecs].kind_of?(Array))
#                  assert_equal(1, $Variables[:MySQLExecs].size)
#                  lMySQLExec = $Variables[:MySQLExecs][0]
#                  assert(lMySQLExec.kind_of?(Hash))
#                  assert_equal('DummyHost', lMySQLExec[:Host])
#                  assert_equal('DummyDBName', lMySQLExec[:DBName])
#                  assert_equal('DummyDBUser', lMySQLExec[:DBUser])
#                  assert_equal('DummyDBPassword', lMySQLExec[:DBPassword])
#                  lCalls = lMySQLExec[:Calls]
#                  checkCallsMatch(
#                    [
#                      ['query', 'select id from users where login = \'DummyUser\''],
#                      ['query', /^insert into journals \( journalized_id, journalized_type, user_id, notes, created_on \) values \( 123, 'Issue', 666, '\[....-..-.. ..:..:..\] - Release 0.0.1.20100112 \(released by DummyReleaseUser\) is shipping modifications made for this Ticket: DummyReleaseComment', '....-..-.. ..:..:..' \)$/]
#                    ],
#                    lCalls
#                  )
#                end
#              end
#
#            end

          end

        end

      end

    end

  end

end
