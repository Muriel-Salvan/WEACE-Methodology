# Check http://weacemethod.sourceforge.net for details.
#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under BSD LICENSE. No warranty is provided.
#++

module WEACE

  module Slave

    module Adapters
    
      module Redmine
      
        module Common
        
          # Exec some Ruby code in the MySQL environment
          #
          # Parameters:
          # * *iRubyExecFileName* (_String_): Name of the Ruby file to execute after having set the environment for MySQL
          # * *iUserID* (_String_): User ID of the script adding this info
          # * *iMySQLHost* (_String_): The name of the MySQL host
          # * *iDBName* (_String_): The name of the database of Redmine
          # * *iDBUser* (_String_): The name of the database user
          # * *iDBPassword* (_String_): The password of the database user
          # * *Parameters*: Remaining parameters
          # * *Block*: The code to execute once connected to MySQL
          def execMySQL(iRubyExecFileName, iUserID, iMySQLHost, iDBName, iDBUser, iDBPassword, *iParameters)
            if (iRubyExecFileName != $0)
              # We were included.
              # Don't accept that, as the environment might not be set up correctly.
              execCmd(". #{$WEACEToolkitDir}/Slave/Adapters/Redmine/DBEnv.sh; ruby -w #{iRubyExecFileName} #{iUserID} #{iMySQLHost} #{iDBName} #{iDBUser} #{iDBPassword} #{iParameters.join(' ')")
            else
              # Go on
              require 'rubygems'
              require 'mysql'
              # Connect to the db
              lMySQL = Mysql::new(iMySQLHost, iDBUser, iDBPassword, iDBName)
              # Create a transaction
              lMySQL.query("start transaction")
              begin
                yield(lMySQL)
                lMySQLConnection.query("commit")
              rescue RuntimeError
                lMySQLConnection.query("rollback")
                raise
              end
            end
          end

          # Get the User ID based on its name
          #
          # Parameters:
          # * *iMySQL* (_Mysql_): The MySQL connection
          # * *iUserName* (_String_): User name to look for
          # Return:
          # * _String_: Corresponding user ID
          def getUserID(iMySQL, iUserName)
            rUserID = nil
            
            iMySQL.query(
              "select id
               from users
               where
                 login = '#{iUserName}'").each do |iRow|
              rUserID = iRow[0]
            end
            
            return rUserID
          end
          
        end
        
      end
      
    end
    
  end
  
end
