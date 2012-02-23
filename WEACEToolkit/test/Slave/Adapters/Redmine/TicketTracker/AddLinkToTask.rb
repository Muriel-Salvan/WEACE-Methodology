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

            class AddLinkToTask < ::Test::Unit::TestCase

              include WEACE::Test::Slave::Common
              include WEACE::Test::Slave::GenericAdapters::TicketTracker::AddLinkToTask
              include WEACE::Test::Slave::Adapters::Redmine::Common

              # Prepare the plugin's execution
              #
              # Parameters::
              # * *iUserID* (_String_): User ID of the script adding this info
              # * *iTicketID* (_String_): The Ticket ID
              # * *iTaskID* (_String_): The Task ID
              # * *iTaskName* (_String_): The Task name to add into the comment
              # * *CodeBlock*: Code to call once preparation has been made
              def prepareExecution(iUserID, iTicketID, iTaskID, iTaskName)
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
              # * *iTaskID* (_String_): The Task ID
              # * *iTaskName* (_String_): The Task name to add into the comment
              def checkData(iUserID, iTicketID, iTaskID, iTaskName)
                checkConnectionData
                checkCallsMatch(
                  [
                    ['query', 'select id from users where login = \'DummyUserID\''],
                    ['query', /^insert into journals \( journalized_id, journalized_type, user_id, notes, created_on \) values \( 123, 'Issue', 666, '\[....-..-.. ..:..:..\] - This Ticket has been linked to Task "DummyTaskName" \(ID: 456\)', '....-..-.. ..:..:..' \)$/]
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
