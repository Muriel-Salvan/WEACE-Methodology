#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  module Test

    module Master

      module Processes

        class Ticket_CloseDuplicate < ::Test::Unit::TestCase
          
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
                '--masterticket', '123',
                '--slaveticket', '456'
              ]
            ) do |iError, iSlaveActions|
              assert_equal(
                {
                  Tools_TicketTracker => [
                    [
                      Action_Ticket_RejectDuplicate,
                      [ '123', '456' ]
                    ]
                  ]
                },
                iSlaveActions
              )
            end
          end

          # Test when the slave Ticket ID is missing
          def testMissingSlave
            executeProcess(
              [
                '--masterticket', '123'
              ],
              :Error => WEACE::MissingVariableError
            )
          end

          # Test when the master Ticket ID is missing
          def testMissingMaster
            executeProcess(
              [
                '--slaveticket', '456'
              ],
              :Error => WEACE::MissingVariableError
            )
          end

        end

      end

    end

  end

end
