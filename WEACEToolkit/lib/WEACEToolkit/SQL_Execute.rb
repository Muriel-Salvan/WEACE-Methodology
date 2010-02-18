#--
# Copyright (c) 2010 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  # This class should the parent class of any class defining SQL operations
  # Subclasses should only implement execute method.
  class SQL_Execute

    # Start a MySQL transaction, connecting first to the database.
    # This transaction will call the execute method to perform SQL queries, with the given parameters as signature (with the additional first parameter: the SQL connection object).
    # !!! It is important that classes inheriting this one may be Marshalled (meaning they should contain no singleton and no code block), as it might be necessary to serialize the call to give it to an external process.
    #
    # Parameters:
    # * *iMySQLHost* (_String_): The name of the MySQL host
    # * *iDBName* (_String_): The name of the database of Redmine
    # * *iDBUser* (_String_): The name of the database user
    # * *iDBPassword* (_String_): The password of the database user
    # * *iSQLMethodParameters* (<em>list<Object></em>): The parameters to give the SQL method
    # * *iOptions* (<em>map<Symbol,Object></em>): Additional options [optional = {}]
    # ** *:RubyMySQLLibDir* (_String_): Ruby MYSQL's lib directory to try if Ruby MySQL is not natively accessible [optional = nil]
    # ** *:MySQLLibDir* (_String_): MySQL C-connector's library directory to try if ruby/MySQL is not natively accessible [optional = nil]
    # ** *:ExtraProcess* (_Boolean_): Do we span a new process if needed ? [optional = true]
    # Return:
    # * _Exception_: An error, or nil in case of success
    def executeTransaction(iMySQLHost, iDBName, iDBUser, iDBPassword, iSQLMethodParameters, iOptions = {})
      rError = nil

      lRubyMySQLLibDir = iOptions[:RubyMySQLLibDir]
      lMySQLLibDir = iOptions[:MySQLLibDir]
      lExtraProcess = iOptions[:ExtraProcess]
      if (lExtraProcess == nil)
        lExtraProcess = true
      end

      logDebug "Trying to create an SQL transaction #{iDBUser}@#{iDBName}@#{iMySQLHost} ..."
      lAlreadyExecuted = false
      # First, try directly
      lSuccess = true
      begin
        require 'mysql'
        logDebug 'Ruby-mysql accessible natively.'
      rescue Exception
        logDebug 'Ruby-mysql NOT accessible natively.'
        lSuccess = false
      end
      if (!lSuccess)
        # Try altering the environment if possible
        if (lRubyMySQLLibDir != nil)
          # Add this directory in the $LOAD_PATH, and try again
          $LOAD_PATH << lRubyMySQLLibDir
          begin
            require 'mysql'
            logDebug "Ruby-mysql accessible after adding #{lRubyMySQLLibDir} to load path."
            lSuccess = true
          rescue Exception
            logDebug "Ruby-mysql NOT accessible after adding #{lRubyMySQLLibDir} to load path."
          end
        end
        # Try the C-connector if possible
        if ((!lSuccess) and
            (lMySQLLibDir != nil))
          # We have to alter our libraries paths and try again
          $rUtilAnts_Platform_Info.setSystemLibsPath($rUtilAnts_Platform_Info.getSystemLibsPath + [lMySQLLibDir])
          if ($rUtilAnts_Platform_Info.os == OS_LINUX)
            if (lExtraProcess)
              # Execute in a separate process, as $LD_LIBRARY_PATH can't be changed dynamically inside a process
              require 'rUtilAnts/ForeignProcess'
              rError, lResult = RUtilAnts::ForeignProcess::execCmdOtherSession(
                "export LD_LIBRARY_PATH='#{ENV['LD_LIBRARY_PATH']}'",
                self,
                :executeTransaction,
                [
                  iMySQLHost, iDBName, iDBUser, iDBPassword, iSQLMethodParameters, iOptions.merge({:ExtraProcess => false})
                ]
              )
              if (rError == nil)
                rError = lResult
              end
              # Don't try to execute it the normal way
              lAlreadyExecuted = true
              lSuccess = true
            end
          else
            begin
              require 'mysql'
              logDebug "Ruby-mysql accessible after adding #{lRubyMySQLLibDir} to load path and #{lMySQLLibDir} to system's libraries paths."
              lSuccess = true
            rescue Exception
              logDebug "Ruby-mysql NOT accessible after adding #{lRubyMySQLLibDir} to load path and #{lMySQLLibDir} to system's libraries paths."
            end
          end
        end
      end
      if (lSuccess)
        if (!lAlreadyExecuted)
          begin
            # Connect to the db
            lMySQL = Mysql::new(iMySQLHost, iDBUser, iDBPassword, iDBName)
          rescue Exception
            rError = $!
          end
          if (rError == nil)
            begin
              # Create a transaction
              lMySQL.query("start transaction")
              execute(*([lMySQL] + iSQLMethodParameters))
              rError = yield(lMySQL)
              lMySQL.query("commit")
            rescue RuntimeError
              lMySQL.query("rollback")
              rError = $!
            end
          end
        end
      else
        rError = RuntimeError.new("Using Ruby MySQL is impossible. Please make sure it is among your system libraries path. Ruby library path tried: #{lRubyMySQLLibDir}. MySQL C-connector path tried: #{lMySQLLibDir}.")
      end

      return rError
    end

  end

end