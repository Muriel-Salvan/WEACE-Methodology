#--
# Copyright (c) 2010 - 2012 Muriel Salvan (muriel@x-aeon.com)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

# Methods used in Mediawiki testing

module WEACE

  module Test

    module Slave

      module Adapters

        module Redmine

          module Common

            # Get the Product's configuration to give the plugin for testing
            #
            # Return::
            # * <em>map<Symbol,Object></em>: The Product configuration
            def getProductConfig
              return {
                :RedmineDir => '/path/to/Redmine',
                :RubyMySQLLibDir => '/path/to/rubymysql',
                :MySQLLibDir => '/path/to/mysql',
                :DBHost => 'DBHost',
                :DBName => 'DBName',
                :DBUser => 'DBUser',
                :DBPassword => 'DBPassword',
              }
            end

            # Prepare test suite for anything common to any SlaveProduct/Redmine test suite
            #
            # Parameters::
            # * *CodeBlock*: The code to call once prepared
            def prepareRedmineExecution
              # We catch MySQL calls
              WEACE::Test::Common::changeMethod(
                WEACE::Common,
                :beginMySQLTransaction,
                :beginMySQLTransaction_Regression
              ) do
                yield
              end
            end

            # Check connection data
            # This part is common to any test suite on SlaveProduct/Redmine
            def checkConnectionData
              assert($Variables[:MySQLExecs] != nil)
              assert($Variables[:MySQLExecs].kind_of?(Array))
              assert_equal(1, $Variables[:MySQLExecs].size)
              lMySQLExec = $Variables[:MySQLExecs][0]
              assert(lMySQLExec.kind_of?(Hash))
              assert_equal('DBHost', lMySQLExec[:Host])
              assert_equal('DBName', lMySQLExec[:DBName])
              assert_equal('DBUser', lMySQLExec[:DBUser])
              assert_equal('DBPassword', lMySQLExec[:DBPassword])
            end

          end

        end

      end

    end

  end

end
