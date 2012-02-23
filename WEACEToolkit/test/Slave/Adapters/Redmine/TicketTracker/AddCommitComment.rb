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

            class AddCommitComment < ::Test::Unit::TestCase

              include WEACE::Test::Slave::Common
              include WEACE::Test::Slave::GenericAdapters::TicketTracker::AddCommitComment
              include WEACE::Test::Slave::Adapters::Redmine::Common

              # Prepare the plugin's execution
              #
              # Parameters::
              # * *iUserID* (_String_): User ID of the script adding this info
              # * *iTicketID* (_String_): The Ticket ID
              # * *iBranchName* (_String_): Name of the branch receiving the commit
              # * *iCommitID* (_String_): The commit ID
              # * *iCommitUser* (_String_): The commit user
              # * *iCommitComment* (_String_): The commit comment
              # * *CodeBlock*: Code to call once preparation has been made
              def prepareExecution(iUserID, iTicketID, iBranchName, iCommitID, iCommitUser, iCommitComment)
                prepareRedmineExecution do
                  $Context[:DummySQLAnswers] = [
                    [ # Select
                      [ 666 ]
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
              # * *iTicketID* (_String_): The Ticket ID
              # * *iBranchName* (_String_): Name of the branch receiving the commit
              # * *iCommitID* (_String_): The commit ID
              # * *iCommitUser* (_String_): The commit user
              # * *iCommitComment* (_String_): The commit comment
              def checkData(iUserID, iTicketID, iBranchName, iCommitID, iCommitUser, iCommitComment)
                checkConnectionData
                checkCallsMatch(
                  [
                    ['query', 'select id from users where login = \'DummyUserID\''],
                    ['query', /^insert into journals \( journalized_id, journalized_type, user_id, notes, created_on \) values \( 123, 'Issue', 666, '\[....-..-.. ..:..:..\] - A new Commit \(ID=DummyCommitID\) from DummyCommitUser on branch DummyBranchName is affecting this Ticket: DummyCommitComment', '....-..-.. ..:..:..' \)$/]
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
