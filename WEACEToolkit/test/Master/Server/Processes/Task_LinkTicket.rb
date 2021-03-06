#--
# Copyright (c) 2009 - 2012 Muriel Salvan  (muriel@x-aeon.com)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  module Test

    module Master

      module Processes

        class Task_LinkTicket < ::Test::Unit::TestCase
          
          include WEACE::Test::Master::Common

          # Test that getOptions return something correct
          def testGetOptions
            accessProcessPlugin do |iProcessPlugin|
              lProcessOptions = iProcessPlugin.getOptions
              assert(lProcessOptions.kind_of?(OptionParser))
            end
          end

          # Test a nominal case
          def testNominal
            executeProcess(
              [
                '--ticket', '123',
                '--task', '456'
              ]
            ) do |iError, iSlaveActions|
              assert_equal(
                {
                  Tools::TicketTracker => {
                    Actions::Ticket_AddLinkToTask => [
                      [ '123', '456' ]
                    ]
                  },
                  Tools::ProjectManager => {
                    Actions::Task_AddLinkToTicket => [
                      [ '456', '123' ]
                    ]
                  }
                },
                iSlaveActions
              )
            end
          end

          # Test when the task ID is missing
          def testMissingTask
            executeProcess(
              [
                '--ticket', '123'
              ],
              :Error => WEACE::MissingVariableError
            )
          end

          # Test when the ticket ID is missing
          def testMissingTicket
            executeProcess(
              [
                '--task', '123'
              ],
              :Error => WEACE::MissingVariableError
            )
          end

        end

      end

    end

  end

end
