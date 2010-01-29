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

          module Redmine

            module TicketTracker

              class Ticket_CloseDuplicate < ::Test::Unit::TestCase

                include WEACE::Test::Install::Adapters

                # Test normal behaviour
                def testNormal
                  executeInstallAdapter(
                    [
                      '--redminedir', '%{Repository}/redmine-0.8.2',
                      '--ruby', '/usr/bin/ruby'
                    ],
                    :ProductRepository => 'Virgin',
                    :ContextVars => {
                      'WEACEMasterInfoURL' => 'http://weacemethod.sourceforge.net'
                    }
                  ) do |iError|
                    compareWithRepository('Normal')
                  end
                end

                # Test duplicate behaviour
                def testDuplicate
                  executeInstallAdapter(
                    [
                      '--redminedir', '%{Repository}/redmine-0.8.2',
                      '--ruby', '/usr/bin/ruby'
                    ],
                    :ProductRepository => 'Normal',
                    :ContextVars => {
                      'WEACEMasterInfoURL' => 'http://weacemethod.sourceforge.net'
                    }
                  ) do |iError|
                    compareWithRepository('Normal')
                  end
                end

              end

            end

          end

        end

      end

    end

  end

end
