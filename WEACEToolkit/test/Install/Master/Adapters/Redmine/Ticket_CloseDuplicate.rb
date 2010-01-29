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

    module Install

      module Master

        module Adapters

          class Redmine

            class Ticket_CloseDuplicate < ::Test::Unit::TestCase

              include WEACE::Test::Install::Master::MasterProcess

              # Test normal behaviour
              def testNormal
                executeInstallMasterProcess(
                  [],
                  :Repository => 'MasterRedmineInstalled',
                  :ProductRepository => 'Redmine/Master/Ticket_CloseDuplicate/Virgin',
                  :ContextVars => {
                    'WEACEMasterInfoURL' => 'http://weacemethod.sourceforge.net',
                    'WEACEExecuteCmd' => '/usr/bin/ruby -w WEACEExecute.rb'
                  },
                  :CheckInstallFile => {
                    :Description => 'This adapter is triggered when a Ticket is marked as duplicating another one.',
                    :Author => 'murielsalvan@users.sourceforge.net'
                  },
                  :CheckConfigFile => {}
                ) do |iError|
                  compareWithRepository('Redmine/Master/Ticket_CloseDuplicate/Normal')
                end
              end

              # Test duplicate behaviour
              def testDuplicate
                executeInstallMasterProcess(
                  [],
                  :Repository => 'MasterRedmineInstalled',
                  :ProductRepository => 'Redmine/Master/Ticket_CloseDuplicate/Normal',
                  :ContextVars => {
                    'WEACEMasterInfoURL' => 'http://weacemethod.sourceforge.net',
                    'WEACEExecuteCmd' => '/usr/bin/ruby -w WEACEExecute.rb'
                  },
                  :CheckInstallFile => {
                    :Description => 'This adapter is triggered when a Ticket is marked as duplicating another one.',
                    :Author => 'murielsalvan@users.sourceforge.net'
                  },
                  :CheckConfigFile => {}
                ) do |iError|
                  compareWithRepository('Redmine/Master/Ticket_CloseDuplicate/Normal')
                end
              end

            end

          end

        end

      end

    end

  end

end
