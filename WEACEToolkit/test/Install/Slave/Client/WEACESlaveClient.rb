#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  module Test

    module Install

      module Slave

        module Client

          # Test everything related to installing WEACE Slave Client.
          class Install < ::Test::Unit::TestCase

            include WEACE::Test::Install::Common

            # Test installing the Slave Client without specifying any provider
            def testSlaveClientWithoutProvider
              executeInstall(['--install', 'SlaveClient'], :Error => WEACEInstall::CommandLineError)
            end

            # Test installing the Slave Client with specifying a missing provider
            def testSlaveClientWithMissingProvider
              executeInstall(['--install', 'SlaveClient', '--provider'], :Error => OptionParser::MissingArgument)
            end

            # Test installing the Slave Client with specifying an unknown provider
            def testSlaveClientWithUnknownProvider
              executeInstall(['--install', 'SlaveClient', '--provider', 'UnknownProviderForRegression'], :Error => WEACEInstall::ProviderError)
            end

            # Test installing the Slave Client
            def testSlaveClient
              executeInstall(['--install', 'SlaveClient', '--provider', 'DummySlaveProvider'],
                :AddRegressionSlaveProviders => true,
                :CheckComponentName => 'SlaveClient',
                :CheckInstallFile => {
                  :Description => 'The WEACE Slave Client.',
                  :Author => 'murielsalvan@users.sourceforge.net',
                  :InstallationParameters => '',
                  :ProviderID => 'DummySlaveProvider'
                },
                :CheckConfigFile => {
                  :WEACESlaveAdapters => {}
                }
              )
            end

            # Test installing the Slave Client twice
            def testSlaveClientTwice
              executeInstall(['--install', 'SlaveClient', '--provider', 'DummySlaveProvider'],
                :Repository => 'Dummy/SlaveClientInstalled',
                :AddRegressionSlaveProviders => true,
                :Error => WEACEInstall::Installer::AlreadyInstalledComponentError
              )
            end

            # Test installing the Slave Client twice with force option
            def testSlaveClientTwiceForce
              executeInstall(['--install', 'SlaveClient', '--provider', 'DummySlaveProvider', '--force'],
                :Repository => 'Dummy/SlaveClientInstalled',
                :AddRegressionSlaveProviders => true,
                :CheckComponentName => 'SlaveClient',
                :CheckInstallFile => {
                  :Description => 'The WEACE Slave Client.',
                  :Author => 'murielsalvan@users.sourceforge.net',
                  :InstallationParameters => '',
                  :ProviderID => 'DummySlaveProvider'
                },
                :CheckConfigFile => {
                  :WEACESlaveAdapters => {}
                }
              )
            end

            # Test installing the Slave Client twice with force option (short version)
            def testSlaveClientTwiceForceShort
              executeInstall(['--install', 'SlaveClient', '--provider', 'DummySlaveProvider', '-f'],
                :Repository => 'Dummy/SlaveClientInstalled',
                :AddRegressionSlaveProviders => true,
                :CheckComponentName => 'SlaveClient',
                :CheckInstallFile => {
                  :Description => 'The WEACE Slave Client.',
                  :Author => 'murielsalvan@users.sourceforge.net',
                  :InstallationParameters => '',
                  :ProviderID => 'DummySlaveProvider'
                },
                :CheckConfigFile => {
                  :WEACESlaveAdapters => {}
                }
              )
            end

            # Test installing the Slave Client already configured
            def testSlaveClientAlreadyConfigured
              executeInstall(['--install', 'SlaveClient', '--provider', 'DummySlaveProvider', '-f'],
                :Repository => 'Dummy/SlaveClientConfigured',
                :AddRegressionSlaveProviders => true,
                :CheckComponentName => 'SlaveClient',
                :CheckInstallFile => {
                  :Description => 'The WEACE Slave Client.',
                  :Author => 'murielsalvan@users.sourceforge.net',
                  :InstallationParameters => '',
                  :ProviderID => 'DummySlaveProvider'
                },
                :CheckConfigFile => {
                  :WEACESlaveAdapters => {},
                  :PersonalizedAttribute => 'PersonalizedValue'
                }
              )
            end

            # Test installing the Slave Client with a Provider missing some parameters
            def testSlaveClientWithProviderMissingParameters
              executeInstall(['--install', 'SlaveClient', '--provider', 'DummySlaveProviderWithParams'],
                :Error => WEACEInstall::CommandLineError,
                :AddRegressionSlaveProviders => true
              ) do |iError|
                assert_equal(nil, $Variables[:SlaveProviderDummyFlag])
              end
            end

            # Test installing the Slave Client with a Provider missing some parameters values
            def testSlaveClientWithProviderMissingParametersValues
              executeInstall(['--install', 'SlaveClient', '--provider', 'DummySlaveProviderWithParamsValues', '--', '--dummyvar'],
                :Error => WEACEInstall::CommandLineError,
                :AddRegressionSlaveProviders => true
              ) do |iError|
                assert_equal(nil, $Variables[:SlaveProviderDummyVar])
              end
            end

            # Test installing the Slave Client with a Provider having some parameters
            def testSlaveClientWithProviderHavingParameters
              executeInstall(['--install', 'SlaveClient', '--provider', 'DummySlaveProviderWithParams', '--', '--flag'],
                :AddRegressionSlaveProviders => true,
                :CheckComponentName => 'SlaveClient',
                :CheckInstallFile => {
                  :Description => 'The WEACE Slave Client.',
                  :Author => 'murielsalvan@users.sourceforge.net',
                  :InstallationParameters => '--flag',
                  :ProviderID => 'DummySlaveProviderWithParams'
                },
                :CheckConfigFile => {
                  :WEACESlaveAdapters => {}
                }
              ) do |iError|
                assert_equal(true, $Variables[:SlaveProviderDummyFlag])
              end
            end

            # Test installing the Slave Client with a Provider having some parameters values
            def testSlaveClientWithProviderHavingParametersValues
              executeInstall(['--install', 'SlaveClient', '--provider', 'DummySlaveProviderWithParamsValues', '--', '--dummyvar', 'testvalue'],
                :AddRegressionSlaveProviders => true,
                :CheckComponentName => 'SlaveClient',
                :CheckInstallFile => {
                  :Description => 'The WEACE Slave Client.',
                  :Author => 'murielsalvan@users.sourceforge.net',
                  :InstallationParameters => '--dummyvar testvalue',
                  :ProviderID => 'DummySlaveProviderWithParamsValues'
                },
                :CheckConfigFile => {
                  :WEACESlaveAdapters => {}
                }
              ) do |iError|
                assert_equal('testvalue', $Variables[:SlaveProviderDummyVar])
              end
            end

            # Test installing the Slave Client with a Provider giving CGI abilities
            def testSlaveClientWithCGIProvider
              executeInstall(['--install', 'SlaveClient', '--provider', 'DummySlaveProviderWithCGI', '--', '--repository', '%{WEACERepositoryDir}/CGI'],
                :AddRegressionSlaveProviders => true,
                :CheckComponentName => 'SlaveClient',
                :CheckInstallFile => {
                  :Description => 'The WEACE Slave Client.',
                  :Author => 'murielsalvan@users.sourceforge.net',
                  :InstallationParameters => '--repository %{WEACERepositoryDir}/CGI',
                  :ProviderID => 'DummySlaveProviderWithCGI'
                },
                :CheckConfigFile => {
                  :WEACESlaveAdapters => {}
                }
              ) do |iError|
                # Check that CGI files have been created correctly
                lCGIFileName = "#{@WEACERepositoryDir}/CGI/cgi/WEACE/ShowWEACESlaveInfo.cgi"
                assert(File.exists?(lCGIFileName))
                lCGIContent = nil
                File.open(lCGIFileName, 'r') do |iFile|
                  lCGIContent = iFile.read
                end
                assert_equal("\#!/usr/bin/env ruby
\# This file has been generated by the installation of WEACE Slave Client
\# Print header
puts 'Content-type: text/html'
puts ''
puts ''
begin
  \# Load WEACE environment
  require '#{@WEACEEnvFile}'
  require 'WEACEToolkit/Slave/DumpInfo'
  WEACE::Slave::DumpInfo.new.dumpHTML
rescue Exception
  puts \"WEACE Slave Installation is corrupted: \#{$!}\"
end
",
                  lCGIContent
                )
              end
            end

            # Test installing the Slave Client with a Provider giving Shell abilities
            def testSlaveClientWithShellProvider
              executeInstall(['--install', 'SlaveClient', '--provider', 'DummySlaveProviderWithShell', '--', '--shelldir', '%{WEACERepositoryDir}/WEACETools'],
                :AddRegressionSlaveProviders => true,
                :CheckComponentName => 'SlaveClient',
                :CheckInstallFile => {
                  :Description => 'The WEACE Slave Client.',
                  :Author => 'murielsalvan@users.sourceforge.net',
                  :InstallationParameters => '--shelldir %{WEACERepositoryDir}/WEACETools',
                  :ProviderID => 'DummySlaveProviderWithShell'
                },
                :CheckConfigFile => {
                  :WEACESlaveAdapters => {}
                }
              ) do |iError|
                # Check that Shell files have been created correctly
                lShellFileName = "#{@WEACERepositoryDir}/WEACETools/ShowWEACESlaveInfo.sh"
                assert(File.exists?(lShellFileName))
                lShellContent = nil
                File.open(lShellFileName, 'r') do |iFile|
                  lShellContent = iFile.read
                end
                assert_equal("\#!/usr/bin/env ruby
\# This file has been generated by the installation of WEACE Slave Client
begin
  \# Load WEACE environment
  require '#{@WEACEEnvFile}'
  require 'WEACEToolkit/Slave/DumpInfo'
  WEACE::Slave::DumpInfo.new.dumpTerminal
rescue Exception
  puts \"WEACE Slave Installation is corrupted: \#{$!}\"
end
",
                  lShellContent
                )
              end
            end

          end

        end

      end

    end

  end

end
