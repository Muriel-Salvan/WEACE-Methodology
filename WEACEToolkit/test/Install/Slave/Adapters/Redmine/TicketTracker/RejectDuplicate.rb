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

      module Slave

        module Adapters

          module Redmine

            module TicketTracker

              class RejectDuplicate < ::Test::Unit::TestCase

                include WEACE::Test::Install::Adapters

                # Test normal behaviour
                def testNormal
                  executeInstallAdapter(
                    [
                      '--redminedir', '%{ProductDir}/redmine-0.8.2',
                      '--rubygemslib', '%{ProductDir}/rubygems/lib',
                      '--gems', '%{ProductDir}/rubygems/gems',
                      '--mysql', '%{ProductDir}/mysql/lib'
                    ],
                    :ProductRepository => 'Virgin',
                    :ContextVars => {
                      'WEACESlaveInfoURL' => 'http://weacemethod.sourceforge.net'
                    }
                  ) do |iError|
                    compareWithRepository('Normal')
                  end
                end

                # Test duplicate behaviour
                def testDuplicate
                  executeInstallAdapter(
                    [
                      '--redminedir', '%{ProductDir}/redmine-0.8.2',
                      '--rubygemslib', '%{ProductDir}/rubygems/lib',
                      '--gems', '%{ProductDir}/rubygems/gems',
                      '--mysql', '%{ProductDir}/mysql/lib'
                    ],
                    :ProductRepository => 'Normal',
                    :ContextVars => {
                      'WEACESlaveInfoURL' => 'http://weacemethod.sourceforge.net'
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
