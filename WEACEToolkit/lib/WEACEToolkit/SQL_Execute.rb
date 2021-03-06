#--
# Copyright (c) 2010 - 2012 Muriel Salvan (muriel@x-aeon.com)
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
    # Parameters::
    # * *iMySQLHost* (_String_): The name of the MySQL host
    # * *iDBName* (_String_): The name of the database of Redmine
    # * *iDBUser* (_String_): The name of the database user
    # * *iDBPassword* (_String_): The password of the database user
    # * *iSQLMethodParameters* (<em>list<Object></em>): The parameters to give the SQL method
    # * *iOptions* (<em>map<Symbol,Object></em>): Additional options [optional = {}]
    #   * *:RubyMySQLLibDir* (_String_): Ruby MYSQL's lib directory to try if Ruby MySQL is not natively accessible [optional = nil]
    #   * *:MySQLLibDir* (_String_): MySQL C-connector's library directory to try if ruby/MySQL is not natively accessible [optional = nil]
    #   * *:ExtraProcess* (_Boolean_): Do we span a new process if needed ? [optional = true]
    # Return::
    # * _Exception_: An error, or nil in case of success
    def executeTransaction(iMySQLHost, iDBName, iDBUser, iDBPassword, iSQLMethodParameters, iOptions = {})
      rError = nil

      lRubyMySQLLibDir = iOptions[:RubyMySQLLibDir]
      lMySQLLibDir = iOptions[:MySQLLibDir]
      lExtraProcess = iOptions[:ExtraProcess]
      if (lExtraProcess == nil)
        lExtraProcess = true
      end

      log_debug "Trying to create an SQL transaction #{iDBUser}@#{iDBName}@#{iMySQLHost} ..."
      lAlreadyExecuted = false
      # First, try directly
      lSuccess = true
      begin
        require 'mysql'
        log_debug 'Ruby-mysql accessible natively.'
      rescue Exception
        log_debug 'Ruby-mysql NOT accessible natively.'
        lSuccess = false
      end
      if (!lSuccess)
        # Try altering the environment if possible
        if (lRubyMySQLLibDir != nil)
          # Add this directory in the $LOAD_PATH, and try again
          $LOAD_PATH << lRubyMySQLLibDir
          begin
            require 'mysql'
            log_debug "Ruby-mysql accessible after adding #{lRubyMySQLLibDir} to load path."
            lSuccess = true
          rescue Exception
            log_debug "Ruby-mysql NOT accessible after adding #{lRubyMySQLLibDir} to load path."
          end
        end
        # Try the C-connector if possible
        if ((!lSuccess) and
            (lMySQLLibDir != nil))
          # We have to alter our libraries paths and try again
          setSystemLibsPath(getSystemLibsPath + [lMySQLLibDir])
          if (os == OS_LINUX)
            if (lExtraProcess)
              # Execute in a separate process, as $LD_LIBRARY_PATH can't be changed dynamically inside a process
              require 'rUtilAnts/ForeignProcess'
              rError, lResult = RUtilAnts::ForeignProcess::exec_cmd_other_session(
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
              log_debug "Ruby-mysql accessible after adding #{lRubyMySQLLibDir} to load path and #{lMySQLLibDir} to system's libraries paths."
              lSuccess = true
            rescue Exception
              log_debug "Ruby-mysql NOT accessible after adding #{lRubyMySQLLibDir} to load path and #{lMySQLLibDir} to system's libraries paths."
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
            # Make sure Mysql exceptioin are not returned as is, because they may be serialized and returned back to processes not having Mysql.
            rError = RuntimeError.new("Error while accessing the DB #{iDBUser}@#{iDBName}@#{iMySQLHost}: #{$!}. Backtrace: #{$!.backtrace.join("\n")}")
          end
          if (rError == nil)
            begin
              # Create a transaction
              lMySQL.query('start transaction')
              rError = execute(*([lMySQL] + iSQLMethodParameters))
              lMySQL.query('commit')
            rescue RuntimeError
              lMySQL.query('rollback')
              # Make sure Mysql exceptioin are not returned as is, because they may be serialized and returned back to processes not having Mysql.
              rError = RuntimeError.new("Error while executing transaction in DB #{iDBUser}@#{iDBName}@#{iMySQLHost}: #{$!}. Backtrace: #{$!.backtrace.join("\n")}")
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