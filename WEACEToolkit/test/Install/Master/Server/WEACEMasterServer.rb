#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
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
            include WEACE::Toolbox

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
                :AddRegressionMasterProviders => true
              ) do |iError|
                # Test the installation file
                lInstallFileName = "#{@WEACERepositoryDir}/Install/InstalledComponents/MasterServer.inst.rb"
                assert(File.exists?(lInstallFileName))
                lInstallInfo = getMapFromFile(lInstallFileName)
                assert(lInstallInfo.kind_of?(Hash))
                assert(lInstallInfo[:InstallationDate] != nil)
                assert_equal('The WEACE Master Server.', lInstallInfo[:Description])
                assert_equal('murielsalvan@users.sourceforge.net', lInstallInfo[:Author])
                assert_equal('', lInstallInfo[:InstallationParameters])
                assert_equal('DummyMasterProvider', lInstallInfo[:ProviderID])
                # Test the configuration file
                lConfigFileName = "#{@WEACERepositoryDir}/Config/MasterServer.conf.rb"
                assert(File.exists?(lConfigFileName))
                lConfigInfo = getMapFromFile(lConfigFileName)
                assert(lConfigInfo.kind_of?(Hash))
                assert_equal([], lConfigInfo[:WEACESlaveClients])
              end
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
                :AddRegressionMasterProviders => true
              ) do |iError|
                assert_equal(true, $Variables[:MasterProviderDummyFlag])
                # Test the installation file
                lInstallFileName = "#{@WEACERepositoryDir}/Install/InstalledComponents/MasterServer.inst.rb"
                assert(File.exists?(lInstallFileName))
                lInstallInfo = getMapFromFile(lInstallFileName)
                assert(lInstallInfo.kind_of?(Hash))
                assert(lInstallInfo[:InstallationDate] != nil)
                assert_equal('The WEACE Master Server.', lInstallInfo[:Description])
                assert_equal('murielsalvan@users.sourceforge.net', lInstallInfo[:Author])
                assert_equal('--flag', lInstallInfo[:InstallationParameters])
                assert_equal('DummyMasterProviderWithParams', lInstallInfo[:ProviderID])
                # Test the configuration file
                lConfigFileName = "#{@WEACERepositoryDir}/Config/MasterServer.conf.rb"
                assert(File.exists?(lConfigFileName))
                lConfigInfo = getMapFromFile(lConfigFileName)
                assert(lConfigInfo.kind_of?(Hash))
                assert_equal([], lConfigInfo[:WEACESlaveClients])
              end
            end

            # Test installing the Master Server with a Provider having some parameters values
            def testMasterServerWithProviderHavingParametersValues
              executeInstall(['--install', 'Master/Server/WEACEMasterServer', '--', '--provider', 'DummyMasterProviderWithParamsValues', '--', '--dummyvar', 'testvalue'],
                :AddRegressionMasterProviders => true
              ) do |iError|
                assert_equal('testvalue', $Variables[:MasterProviderDummyVar])
                # Test the installation file
                lInstallFileName = "#{@WEACERepositoryDir}/Install/InstalledComponents/MasterServer.inst.rb"
                assert(File.exists?(lInstallFileName))
                lInstallInfo = getMapFromFile(lInstallFileName)
                assert(lInstallInfo.kind_of?(Hash))
                assert(lInstallInfo[:InstallationDate] != nil)
                assert_equal('The WEACE Master Server.', lInstallInfo[:Description])
                assert_equal('murielsalvan@users.sourceforge.net', lInstallInfo[:Author])
                assert_equal('--dummyvar testvalue', lInstallInfo[:InstallationParameters])
                assert_equal('DummyMasterProviderWithParamsValues', lInstallInfo[:ProviderID])
                # Test the configuration file
                lConfigFileName = "#{@WEACERepositoryDir}/Config/MasterServer.conf.rb"
                assert(File.exists?(lConfigFileName))
                lConfigInfo = getMapFromFile(lConfigFileName)
                assert(lConfigInfo.kind_of?(Hash))
                assert_equal([], lConfigInfo[:WEACESlaveClients])
              end
            end

            # Test installing the Master Server with a Provider giving CGI abilities
            def testMasterServerWithCGIProvider
              executeInstall(['--install', 'Master/Server/WEACEMasterServer', '--', '--provider', 'DummyMasterProviderWithCGI', '--', '--repository', '%{WEACERepositoryDir}/CGI'],
                :AddRegressionMasterProviders => true
              ) do |iError|
                # Test the installation file
                lInstallFileName = "#{@WEACERepositoryDir}/Install/InstalledComponents/MasterServer.inst.rb"
                assert(File.exists?(lInstallFileName))
                lInstallInfo = getMapFromFile(lInstallFileName)
                assert(lInstallInfo.kind_of?(Hash))
                assert(lInstallInfo[:InstallationDate] != nil)
                assert_equal('The WEACE Master Server.', lInstallInfo[:Description])
                assert_equal('murielsalvan@users.sourceforge.net', lInstallInfo[:Author])
                assert_equal("--repository #{@WEACERepositoryDir}/CGI", lInstallInfo[:InstallationParameters])
                assert_equal('DummyMasterProviderWithCGI', lInstallInfo[:ProviderID])
                # Test the configuration file
                lConfigFileName = "#{@WEACERepositoryDir}/Config/MasterServer.conf.rb"
                assert(File.exists?(lConfigFileName))
                lConfigInfo = getMapFromFile(lConfigFileName)
                assert(lConfigInfo.kind_of?(Hash))
                assert_equal([], lConfigInfo[:WEACESlaveClients])
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
  \# Add WEACE Toolkit path to Ruby's path
  $LOAD_PATH << '#{File.expand_path(@WEACELibDir)}'
  require 'WEACEToolkit/Master/Server/ShowWEACEMasterInfo'
  WEACE::Master::Dump_HTML.new.dumpWEACEMasterInfo_HTML
rescue Exception
  puts \"WEACE Master Installation is corrupted: \#{$!}\"
end
",
                  lCGIContent
                )
              end
            end

          end

        end

      end

    end

  end

end
