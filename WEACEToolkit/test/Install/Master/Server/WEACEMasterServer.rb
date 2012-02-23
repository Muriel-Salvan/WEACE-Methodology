#--
# Copyright (c) 2009 - 2012 Muriel Salvan  (muriel@x-aeon.com)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  module Test

    module Install

      module Master

        module Server

          # Test everything related to installing WEACE Master Server.
          class WEACEMasterServer < ::Test::Unit::TestCase

            include WEACE::Test::Install::Common
            include WEACE::Common

            # Test installing the Master Server without specifying any provider
            def testMasterServerWithoutProvider
              executeInstall(['--install', 'MasterServer'], :Error => WEACEInstall::CommandLineError)
            end

            # Test installing the Master Server with specifying a missing provider
            def testMasterServerWithMissingProvider
              executeInstall(['--install', 'MasterServer', '--provider'], :Error => OptionParser::MissingArgument)
            end

            # Test installing the Master Server with specifying an unknown provider
            def testMasterServerWithUnknownProvider
              executeInstall(['--install', 'MasterServer', '--provider', 'UnknownProviderForRegression'], :Error => WEACEInstall::ProviderError)
            end

            # Test installing the Master Server
            def testMasterServer
              executeInstall(['--install', 'MasterServer', '--provider', 'DummyMasterProvider'],
                :AddRegressionMasterProviders => true,
                :CheckComponentName => 'MasterServer',
                :CheckInstallFile => {
                  :Description => 'The WEACE Master Server.',
                  :Author => 'muriel@x-aeon.com',
                  :InstallationParameters => '',
                  :ProviderID => 'DummyMasterProvider'
                },
                :CheckConfigFile => {
                  :WEACESlaveClients => []
                }
              )
            end

            # Test installing the Master Server twice
            def testMasterServerTwice
              executeInstall(['--install', 'MasterServer', '--provider', 'DummyMasterProvider'],
                :Repository => 'Dummy/MasterServerInstalled',
                :AddRegressionMasterProviders => true,
                :Error => WEACEInstall::Installer::AlreadyInstalledComponentError
              )
            end

            # Test installing the Master Server twice with force option
            def testMasterServerTwiceForce
              executeInstall(['--install', 'MasterServer', '--provider', 'DummyMasterProvider', '--force'],
                :Repository => 'Dummy/MasterServerInstalled',
                :AddRegressionMasterProviders => true,
                :CheckComponentName => 'MasterServer',
                :CheckInstallFile => {
                  :Description => 'The WEACE Master Server.',
                  :Author => 'muriel@x-aeon.com',
                  :InstallationParameters => '',
                  :ProviderID => 'DummyMasterProvider'
                },
                :CheckConfigFile => {
                  :WEACESlaveClients => []
                }
              )
            end

            # Test installing the Master Server twice with force option (short version)
            def testMasterServerTwiceForceShort
              executeInstall(['--install', 'MasterServer', '--provider', 'DummyMasterProvider', '-f'],
                :Repository => 'Dummy/MasterServerInstalled',
                :AddRegressionMasterProviders => true,
                :CheckComponentName => 'MasterServer',
                :CheckInstallFile => {
                  :Description => 'The WEACE Master Server.',
                  :Author => 'muriel@x-aeon.com',
                  :InstallationParameters => '',
                  :ProviderID => 'DummyMasterProvider'
                },
                :CheckConfigFile => {
                  :WEACESlaveClients => []
                }
              )
            end

            # Test installing the Master Server already configured
            def testMasterServerAlreadyConfigured
              executeInstall(['--install', 'MasterServer', '--provider', 'DummyMasterProvider'],
                :Repository => 'Dummy/MasterServerConfigured',
                :AddRegressionMasterProviders => true,
                :CheckComponentName => 'MasterServer',
                :CheckInstallFile => {
                  :Description => 'The WEACE Master Server.',
                  :Author => 'muriel@x-aeon.com',
                  :InstallationParameters => '',
                  :ProviderID => 'DummyMasterProvider'
                },
                :CheckConfigFile => {
                  :WEACESlaveClients => [],
                  :PersonalizedAttribute => 'PersonalizedValue'
                }
              )
            end

            # Test installing the Master Server with a Provider missing some parameters
            def testMasterServerWithProviderMissingParameters
              executeInstall(['--install', 'MasterServer', '--provider', 'DummyMasterProviderWithParams'],
                :Error => WEACEInstall::CommandLineError,
                :AddRegressionMasterProviders => true
              ) do |iError|
                assert_equal(nil, $Variables[:MasterProviderDummyFlag])
              end
            end

            # Test installing the Master Server with a Provider missing some parameters values
            def testMasterServerWithProviderMissingParametersValues
              executeInstall(['--install', 'MasterServer', '--provider', 'DummyMasterProviderWithParamsValues', '--', '--dummyvar'],
                :Error => WEACEInstall::CommandLineError,
                :AddRegressionMasterProviders => true
              ) do |iError|
                assert_equal(nil, $Variables[:MasterProviderDummyVar])
              end
            end

            # Test installing the Master Server with a Provider having some parameters
            def testMasterServerWithProviderHavingParameters
              executeInstall(['--install', 'MasterServer', '--provider', 'DummyMasterProviderWithParams', '--', '--flag'],
                :AddRegressionMasterProviders => true,
                :CheckComponentName => 'MasterServer',
                :CheckInstallFile => {
                  :Description => 'The WEACE Master Server.',
                  :Author => 'muriel@x-aeon.com',
                  :InstallationParameters => '--flag',
                  :ProviderID => 'DummyMasterProviderWithParams'
                },
                :CheckConfigFile => {
                  :WEACESlaveClients => []
                }
              ) do |iError|
                assert_equal(true, $Variables[:MasterProviderDummyFlag])
              end
            end

            # Test installing the Master Server with a Provider having some parameters values
            def testMasterServerWithProviderHavingParametersValues
              executeInstall(['--install', 'MasterServer', '--provider', 'DummyMasterProviderWithParamsValues', '--', '--dummyvar', 'testvalue'],
                :AddRegressionMasterProviders => true,
                :CheckComponentName => 'MasterServer',
                :CheckInstallFile => {
                  :Description => 'The WEACE Master Server.',
                  :Author => 'muriel@x-aeon.com',
                  :InstallationParameters => '--dummyvar testvalue',
                  :ProviderID => 'DummyMasterProviderWithParamsValues'
                },
                :CheckConfigFile => {
                  :WEACESlaveClients => []
                }
              ) do |iError|
                assert_equal('testvalue', $Variables[:MasterProviderDummyVar])
              end
            end

            # Test installing the Master Server with a Provider giving CGI abilities
            def testMasterServerWithCGIProvider
              executeInstall(['--install', 'MasterServer', '--provider', 'DummyMasterProviderWithCGI', '--', '--repository', '%{WEACERepositoryDir}/CGI'],
                :AddRegressionMasterProviders => true,
                :CheckComponentName => 'MasterServer',
                :CheckInstallFile => {
                  :Description => 'The WEACE Master Server.',
                  :Author => 'muriel@x-aeon.com',
                  :InstallationParameters => '--repository %{WEACERepositoryDir}/CGI',
                  :ProviderID => 'DummyMasterProviderWithCGI'
                },
                :CheckConfigFile => {
                  :WEACESlaveClients => []
                }
              ) do |iError|
                # Check that CGI files have been created correctly
                lCGIFileName = "#{@WEACERepositoryDir}/CGI/cgi/WEACE/ShowWEACEMasterInfo.cgi"
                assert(File.exists?(lCGIFileName))
                lCGIContent = nil
                File.open(lCGIFileName, 'r') do |iFile|
                  lCGIContent = iFile.read
                end
                assert_equal("\#!/usr/bin/env ruby
\# This file has been generated by the installation of WEACE Master Server
\# Print header
puts 'Content-type: text/html'
puts ''
puts ''
begin
  \# Load WEACE environment
  require '#{@WEACEEnvFile}'
  require 'WEACEToolkit/Master/DumpInfo'
  WEACE::Master::DumpInfo.new.dumpHTML
rescue Exception
  puts \"WEACE Master Installation is corrupted: \#{$!}\"
end
",
                  lCGIContent
                )
              end
            end

            # Test installing the Master Server with a Provider giving Shell abilities
            def testMasterServerWithShellProvider
              executeInstall(['--install', 'MasterServer', '--provider', 'DummyMasterProviderWithShell', '--', '--shelldir', '%{WEACERepositoryDir}/WEACETools'],
                :AddRegressionMasterProviders => true,
                :CheckComponentName => 'MasterServer',
                :CheckInstallFile => {
                  :Description => 'The WEACE Master Server.',
                  :Author => 'muriel@x-aeon.com',
                  :InstallationParameters => '--shelldir %{WEACERepositoryDir}/WEACETools',
                  :ProviderID => 'DummyMasterProviderWithShell'
                },
                :CheckConfigFile => {
                  :WEACESlaveClients => []
                }
              ) do |iError|
                # Check that Shell files have been created correctly
                lShellFileName = "#{@WEACERepositoryDir}/WEACETools/ShowWEACEMasterInfo.sh"
                assert(File.exists?(lShellFileName))
                lShellContent = nil
                File.open(lShellFileName, 'r') do |iFile|
                  lShellContent = iFile.read
                end
                assert_equal("\#!/usr/bin/env ruby
\# This file has been generated by the installation of WEACE Master Server
begin
  \# Load WEACE environment
  require '#{@WEACEEnvFile}'
  require 'WEACEToolkit/Master/DumpInfo'
  WEACE::Master::DumpInfo.new.dumpTerminal
rescue Exception
  puts \"WEACE Master Installation is corrupted: \#{$!}\"
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
