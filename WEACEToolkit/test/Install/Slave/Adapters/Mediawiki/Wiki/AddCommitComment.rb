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

          module Mediawiki

            module Wiki

              class AddCommitComment < ::Test::Unit::TestCase

                include WEACE::Test::Install::Adapters

                # Test normal behaviour
                def testNormal
                  executeInstallAdapter(
                    [
                      '--mediawikidir', '%{ProductDir}/wiki'
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
                      '--mediawikidir', '%{ProductDir}/wiki'
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
