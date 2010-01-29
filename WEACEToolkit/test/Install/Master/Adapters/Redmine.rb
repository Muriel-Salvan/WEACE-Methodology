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

            include WEACE::Test::Install::Common

            # Test a normal run
            def testNormal
              executeInstall( [ '--install', 'MasterProduct', '--product', 'Redmine', '--as', 'RegRedmine', '--', '--redminedir', '%{ProductDir}/redmine-0.8.2' ],
                :AddRegressionMasterProviders => true,
                :Repository => 'MasterServerInstalled',
                :ProductRepository => 'Redmine/Master/Virgin',
                :ContextVars => {
                  'WEACEMasterInfoURL' => 'http://weacemethod.sourceforge.net'
                },
                :CheckComponentName => 'RegRedmine',
                :CheckInstallFile => {
                  :Description => 'Product Redmine adapted to WEACE Master.',
                  :Author => 'murielsalvan@users.sourceforge.net',
                  :InstallationParameters => '--redminedir %{ProductDir}/redmine-0.8.2',
                  :Product => 'Redmine',
                  :Type => 'Master'
                },
                :CheckConfigFile => {}
              ) do |iError|
                compareWithRepository('Redmine/Master/Normal')
              end
            end

            # Test a duplicate run with a corrupted installation info.
            # The Product has already the info, but the Component is not marked as installed.
            def testDuplicate
              executeInstall( [ '--install', 'MasterProduct', '--product', 'Redmine', '--as', 'RegRedmine', '--', '--redminedir', '%{ProductDir}/redmine-0.8.2' ],
                :AddRegressionMasterProviders => true,
                :Repository => 'MasterServerInstalled',
                :ProductRepository => 'Redmine/Master/Normal',
                :ContextVars => {
                  'WEACEMasterInfoURL' => 'http://weacemethod.sourceforge.net'
                },
                :CheckComponentName => 'RegRedmine',
                :CheckInstallFile => {
                  :Description => 'Product Redmine adapted to WEACE Master.',
                  :Author => 'murielsalvan@users.sourceforge.net',
                  :InstallationParameters => '--redminedir %{ProductDir}/redmine-0.8.2',
                  :Product => 'Redmine',
                  :Type => 'Master'
                },
                :CheckConfigFile => {}
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
