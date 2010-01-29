#--
# Copyright (c) 2010 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  module Test

    module Install

      module Master

        module Adapters

          class Redmine < ::Test::Unit::TestCase

            include WEACE::Test::Install::Master::MasterProduct

            # Test a normal run
            def testNormal
              executeInstallMasterProduct(
                [
                  '--redminedir', '%{ProductDir}/redmine-0.8.2'
                ],
                :ProductRepository => 'Redmine/Master/Virgin',
                :ContextVars => {
                  'WEACEMasterInfoURL' => 'http://weacemethod.sourceforge.net'
                },
                :CheckInstallFile => {
                  :Description => 'Product Redmine adapted to WEACE Master.',
                  :Author => 'murielsalvan@users.sourceforge.net',
                },
                :CheckConfigFile => {
                  :RedmineDir => '%{ProductDir}/redmine-0.8.2'
                }
              ) do |iError|
                compareWithRepository('Redmine/Master/Normal')
              end
            end

            # Test a duplicate run with a corrupted installation info.
            # The Product has already the info, but the Component is not marked as installed.
            def testDuplicate
              executeInstallMasterProduct(
                [
                  '--redminedir', '%{ProductDir}/redmine-0.8.2'
                ],
                :ProductRepository => 'Redmine/Master/Normal',
                :ContextVars => {
                  'WEACEMasterInfoURL' => 'http://weacemethod.sourceforge.net'
                },
                :CheckInstallFile => {
                  :Description => 'Product Redmine adapted to WEACE Master.',
                  :Author => 'murielsalvan@users.sourceforge.net',
                },
                :CheckConfigFile => {
                  :RedmineDir => '%{ProductDir}/redmine-0.8.2'
                }
              ) do |iError|
                compareWithRepository('Redmine/Master/Normal')
              end
            end

          end

        end

      end

    end

  end

end
