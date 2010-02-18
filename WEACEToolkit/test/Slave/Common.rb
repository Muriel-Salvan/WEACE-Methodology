#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

# Require the file defining exceptions
require 'WEACEToolkit/Slave/Client/WEACESlaveClient'

module WEACE

  # We define dummy methods and classes that will replace some real ones to better track their behaviour.
  module Common

    # Class that replaces SQL connections to track queries
    class DummySQLConnection

      # The list of calls that have been performed on this connection
      #   list< [ String, String ] >
      attr_reader :CallsList

      # Constructor
      #
      # Parameters:
      # * *ioCallsList* (<em>list<[String,String]></em>): The list of calls to complete
      # * *iDummyAnswers* (<em>list<list<list<String>>></em>: The list of rows to return when asked
      def initialize(ioCallsList, iDummyAnswers)
        @CallsList, @DummyAnswers = ioCallsList, iDummyAnswers
        @IdxAnswers = 0
        @ID = 0
      end

      # Perform a query
      #
      # Parameters:
      # * *iText* (_String_): Text of the query
      # Return:
      # * <em>list<list<String>></em>: The rows returned by the query
      def query(iText)
        rRows = []

        @CallsList << [ 'query', iText ]
        if (@DummyAnswers[@IdxAnswers] == nil)
          @CallsList << [ 'error', "Query \"#{iText}\" was supposed to return rows, but none were prepared by the WEACE regression." ]
        else
          rRows = @DummyAnswers[@IdxAnswers]
          @IdxAnswers += 1
        end

        return rRows
      end

      # Return a new ID
      #
      # Return:
      # * _Integer_: The new ID
      def insert_id
        rID = @ID

        @CallsList << [ 'insert_id', @ID ]
        @ID += 1

        return rID
      end

    end

    # Method that replaces the beginMySQLTransaction method to track connections and queries using MySQL
    #
    # Parameters:
    # * *iMySQLHost* (_String_): The name of the MySQL host
    # * *iDBName* (_String_): The name of the database of Redmine
    # * *iDBUser* (_String_): The name of the database user
    # * *iDBPassword* (_String_): The password of the database user
    # * *iSQLExecuteObject* (_Object_): The object containing the SQL execution
    # * *iSQLMethodParameters* (<em>list<Object></em>): The parameters to give the SQL method
    # * *iOptions* (<em>map<Symbol,Object></em>): Additional options [optional = {}]
    # ** *:RubyMySQLLibDir* (_String_): Ruby MYSQL's lib directory to try if Ruby MySQL is not natively accessible [optional = nil]
    # ** *:MySQLLibDir* (_String_): MySQL C-connector's library directory to try if ruby/MySQL is not natively accessible [optional = nil]
    # ** *:ExtraProcess* (_Boolean_): Do we span a new process if needed ? [optional = true]
    # Return:
    # * _Exception_: An error, or nil in case of success
    def beginMySQLTransaction_Regression(iMySQLHost, iDBName, iDBUser, iDBPassword, iSQLExecuteObject, iSQLMethodParameters, iOptions = {})
      rError = nil

      if ($Variables[:MySQLExecs] == nil)
        $Variables[:MySQLExecs] = []
      end
      # The list of calls that will be performed during this connection
      lCalls = []
      $Variables[:MySQLExecs] << {
        :Host => iMySQLHost,
        :DBName => iDBName,
        :DBUser => iDBUser,
        :DBPassword => iDBPassword,
        :Calls => lCalls
      }
      lDummySQL = DummySQLConnection.new(lCalls, $Context[:DummySQLAnswers])
      begin
        rError = iSQLExecuteObject.execute(*([lDummySQL] + iSQLMethodParameters))
      rescue Exception
        # Do this to track the error.
        lDummySQL.query("rollback: #{$!} (#{$!.backtrace.join("\n")})")
      end
      # Remove whitspaces from the queries
      lCalls.each do |ioCallInfo|
        iCallType, iCallData = ioCallInfo
        if (iCallType == 'query')
          ioCallInfo[1] = iCallData.split.join(' ')
        end
      end

      return rError
    end

  end

  module Test

    module Slave

      module Common

        include WEACE::Test::Common

        # Check that a given matching pattern of calls match effectively a given list of calls
        # If the matching pattern is a Regexp, that the Call is matched using this Regexp. Otherwise an equality test is made.
        # It raises assert exceptions in cases of failures
        #
        # Parameters:
        # * *iCallsMatch* (<em>list<[String,Object]></em>): The calls matching patterns
        # * *iCalls* (<em>list<[String,Object]></em>): The calls to test against the patterns
        def checkCallsMatch(iCallsMatch, iCalls)
          if (iCallsMatch.size != iCalls.size)
            logErr "Mismatch Call data:\nExpected #{iCallsMatch.size} lines:\n#{iCallsMatch.inspect}\nReceived #{iCalls.size} lines:\n#{iCalls.inspect}"
          end
          assert_equal(iCallsMatch.size, iCalls.size)
          lIdxCall = 0
          iCalls.each do |iCallInfo|
            iCallType, iCallData = iCallInfo
            iCallMatchType, iCallMatchData = iCallsMatch[lIdxCall]
            # First, types must match exactly
            assert_equal(iCallMatchType, iCallType)
            # Then we differentiate the Regexp case
            if (iCallMatchData.kind_of?(Regexp))
              # The data should be a String
              assert(iCallData.kind_of?(String))
              # Match using the RegExp
              lMatchData = iCallData.match(iCallMatchData)
              if (lMatchData == nil)
                logErr "Mismatch Call data:\nExpected:\n#{iCallMatchData}\nReceived:\n#{iCallData}"
                assert(false)
              else
                assert(true)
              end
            else
              # Exact matching test
              assert_equal(replaceVars(iCallMatchData), iCallData)
            end
            lIdxCall += 1
          end
        end

        # Execute WEACE Slave Client
        #
        # Parameters:
        # * *iParameters* (<em>list<String></em>): The parameters to give WEACE Slave Client
        # * *iOptions* (<em>map<Symbol,Object></em>): Additional options: [optional = {}]
        # ** *:Error* (_class_): The error class the execution is supposed to return [optional = nil]
        # ** *:Repository* (_String_): Name of the repository to be used [optional = 'Dummy/SlaveClientInstalled']
        # ** *:AddRegressionActions* (_Boolean_): Do we add Actions defined from the regression ? [optional = false]
        # ** *:InstallActions* (<em>list<[String,String,String]></em>): List of Actions to install: [ ProductID, ToolID, ActionID ]. [optional = nil]
        # ** *:ConfigureProducts* (<em>list<[String,String,map<Symbol,Object>]></em>): The list of Product/Tool to configure: [ ProductID, ToolID, Parameters ]. [optional = nil]
        # * _CodeBlock_: The code called once the server was run: [optional = nil]
        # ** *iError* (_Exception_): The error returned by the server, or nil in case of success
        def executeSlave(iParameters, iOptions = {}, &iCheckCode)
          # Parse options
          lExpectedErrorClass = iOptions[:Error]
          lRepositoryName = iOptions[:Repository]
          if (lRepositoryName == nil)
            lRepositoryName = 'Dummy/SlaveClientInstalled'
          end
          lAddRegressionActions = iOptions[:AddRegressionActions]
          if (lAddRegressionActions == nil)
            lAddRegressionActions = false
          end
          lInstallActions = iOptions[:InstallActions]
          lConfigureProducts = iOptions[:ConfigureProducts]

          initTestCase do
            # Create a new WEACE repository by copying the wanted one
            setupTmpDir(File.expand_path("#{File.dirname(__FILE__)}/../Repositories/#{lRepositoryName}"), 'WEACETestRepository') do |iTmpDir|
              @WEACERepositoryDir = iTmpDir
              WEACE::Slave::Client.changeClient(
                @WEACERepositoryDir,
                lAddRegressionActions,
                lInstallActions,
                lConfigureProducts
              ) do
                # Execute for real now that it has been modified
                require 'WEACEToolkit/Slave/Client/WEACESlaveClient'
                lSlaveClient = WEACE::Slave::Client.new
                # Change instance variables
                lSlaveClient.instance_variable_set(:@WEACEInstallDir, "#{@WEACERepositoryDir}/Install")
                lSlaveClient.instance_variable_set(:@WEACEConfigDir, "#{@WEACERepositoryDir}/Config")

                begin
                  if (debugActivated?)
                    lError = lSlaveClient.execute(['-d']+iParameters)
                  else
                    lError = lSlaveClient.execute(iParameters)
                  end
                rescue Exception
                  # This way exception is shown on screen for better understanding
                  assert_equal(nil, $!)
                end

                # Check result
                if (lExpectedErrorClass == nil)
                  if (lError != nil)
                    logErr "Unexpected error: #{lError.class}: #{lError}"
                    if (lError.backtrace == nil)
                      logErr 'No backtrace'
                    else
                      logErr lError.backtrace.join("\n")
                    end
                  end
                  assert_equal(nil, lError)
                else
                  if (lError == nil)
                    logErr 'Unexpected success.'
                  elsif (!lError.kind_of?(lExpectedErrorClass))
                    logErr "Unexpected error: #{lError.class}: #{lError}"
                    if (lError.backtrace == nil)
                      logErr 'No backtrace'
                    else
                      logErr lError.backtrace.join("\n")
                    end
                  end
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

end
