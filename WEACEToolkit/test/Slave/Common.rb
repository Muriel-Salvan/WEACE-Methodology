#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  module Test

    module Slave

      module Common

        include WEACE::Test::Common

        # Execute WEACE Slave Client
        #
        # Parameters:
        # * *iParameters* (<em>list<String></em>): The parameters to give WEACE Master Server
        # * *iOptions* (<em>map<Symbol,Object></em>): Additional options: [optional = {}]
        # ** *:Error* (_class_): The error class the execution is supposed to return [optional = nil]
        # ** *:Repository* (_String_): Name of the repository to be used [optional = 'Empty']
        # * _CodeBlock_: The code called once the server was run: [optional = nil]
        # ** *iError* (_Exception_): The error returned by the server, or nil in case of success
        def executeSlave(iParameters, iOptions = {}, &iCheckCode)
          # Parse options
          lExpectedErrorClass = iOptions[:Error]
          lRepositoryName = iOptions[:Repository]
          if (lRepositoryName == nil)
            lRepositoryName = 'Empty'
          end

          initTestCase do

            # Create a new WEACE repository by copying the wanted one
            setupTmpDir(File.expand_path("#{File.dirname(__FILE__)}/../Repositories/#{lRepositoryName}"), 'WEACETestRepository') do |iTmpDir|
              @WEACERepositoryDir = iTmpDir

              require 'WEACEToolkit/Slave/Client/WEACESlaveClient'
              lSlaveClient = WEACE::Slave::Client.new

              # Execute for real
              begin
                lError = lSlaveClient.execute(iParameters)
              rescue Exception
                # This way exception is shown on screen for better understanding
                assert_equal(nil, $!)
              end
              # Check
              if (lExpectedErrorClass == nil)
                assert_equal(nil, lError)
              else
                assert(lError.kind_of?(lExpectedErrorClass))
              end
              # Call additional checks from the test case itself
              if (iCheckCode != nil)
                iCheckCode.call(lError)
              end
            end

          end
        end

      end

    end

  end

end
