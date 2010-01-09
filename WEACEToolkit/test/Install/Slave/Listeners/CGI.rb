#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  module Test

    module Install

      module Slave

        module Listeners

          class CGI < ::Test::Unit::TestCase

            include WEACE::Test::Install::Slave::Listeners

            # Test nominal case
            def testNominal2
              executeInstallListener(
                [],
                :ProductRepository => 'Virgin',
                :Repository => 'SlaveClientInstalledWithCGI'
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
