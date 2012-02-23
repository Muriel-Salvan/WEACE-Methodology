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

            class AddReleaseComment < ::Test::Unit::TestCase

              include WEACE::Test::Slave::Common
              include WEACE::Test::Slave::GenericAdapters::TicketTracker::AddReleaseComment
              include WEACE::Test::Slave::Adapters::Redmine::Common

              # Prepare the plugin's execution
              #
              # Parameters::
              # * *iUserID* (_String_): User ID of the script adding this info
              # * *iTicketID* (_String_): The Ticket ID
              # * *iBranchName* (_String_): Name of the branch receiving the commit
              # * *iReleaseVersion* (_String_): The Release version
              # * *iReleaseUser* (_String_): The Release user
              # * *iReleaseComment* (_String_): The Release comment
              # * *CodeBlock*: Code to call once preparation has been made
              def prepareExecution(iUserID, iTicketID, iBranchName, iReleaseVersion, iReleaseUser, iReleaseComment)
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
              # * *iReleaseVersion* (_String_): The Release version
              # * *iReleaseUser* (_String_): The Release user
              # * *iReleaseComment* (_String_): The Release comment
              def checkData(iUserID, iTicketID, iBranchName, iReleaseVersion, iReleaseUser, iReleaseComment)
                checkConnectionData
                checkCallsMatch(
                  [
                    ['query', 'select id from users where login = \'DummyUserID\''],
                    ['query', /^insert into journals \( journalized_id, journalized_type, user_id, notes, created_on \) values \( 123, 'Issue', 666, '\[....-..-.. ..:..:..\] - Release 0.0.1.20100112 \(released by DummyReleaseUser\) is shipping modifications made for this Ticket: DummyReleaseComment', '....-..-.. ..:..:..' \)$/]
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
