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

        module Redmine

          module TicketTracker

            class RejectDuplicate < ::Test::Unit::TestCase

              include WEACE::Test::Slave::Common
              include WEACE::Test::Slave::GenericAdapters::TicketTracker::RejectDuplicate
              include WEACE::Test::Slave::Adapters::Redmine::Common

              # Prepare the plugin's execution
              #
              # Parameters::
              # * *iUserID* (_String_): User ID of the script adding this info
              # * *iMasterTicketID* (_String_): The Master Ticket ID
              # * *iSlaveTicketID* (_String_): The Slave Ticket ID
              # * *CodeBlock*: Code to call once preparation has been made
              def prepareExecution(iUserID, iMasterTicketID, iSlaveTicketID)
                prepareRedmineExecution do
                  $Context[:DummySQLAnswers] = [
                    [ # Select
                      [ 666 ]
                    ],
                    [ # Insert
                    ],
                    [ # Insert
                    ],
                    [ # Insert
                    ],
                    [ # Select
                      [ 42 ]
                    ],
                    [ # Update
                    ],
                    [ # Insert
                    ]
                  ]
                  yield
                end
              end

              # Check data after execution of the Action
              #
              # Parameters::
              # * *iUserID* (_String_): User ID of the script adding this info
              # * *iMasterTicketID* (_String_): The Master Ticket ID
              # * *iSlaveTicketID* (_String_): The Slave Ticket ID
              def checkData(iUserID, iMasterTicketID, iSlaveTicketID)
                checkConnectionData
                checkCallsMatch(
                  [
                    ['query', 'select id from users where login = \'DummyUserID\''],
                    ['query', /^insert into journals \( journalized_id, journalized_type, user_id, notes, created_on \) values \( 123, 'Issue', 666, 'Another Ticket \(ID=456\) has been closed as a duplicate of this one\.', '....-..-.. ..:..:..' \)$/],
                    ['query', 'insert into issue_relations ( issue_from_id, issue_to_id, relation_type, delay ) values ( 123, 456, \'duplicates\', NULL )'],
                    ['query', /^insert into journals \( journalized_id, journalized_type, user_id, notes, created_on \) values \( 456, 'Issue', 666, 'This Ticket is a duplicate of another Ticket \(ID=123\).', '....-..-.. ..:..:..' \)$/],
                    ['insert_id', 0],
                    ['query', 'select status_id from issues where id = 456'],
                    ['query', 'update issues set status_id = 6 where id = 456'],
                    ['query', 'insert into journal_details ( journal_id, property, prop_key, old_value, value ) values ( 0, \'attr\', \'status_id\', 42, 6 )']
                  ],
                  $Variables[:MySQLExecs][0][:Calls]
                )
              end

            end

          end

        end

      end

    end

  end

end
