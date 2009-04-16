# Usage: This file is used by others.
# Do not call it directly.
#
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
        
          # Create a new Ruby session to execute the executeSQL method in a new environment
          #
          # Parameters:
          # * *iMySQLHost* (_String_): The name of the MySQL host
          # * *iDBName* (_String_): The name of the database of Redmine
          # * *iDBUser* (_String_): The name of the database user
          # * *iDBPassword* (_String_): The password of the database user
          # * *Parameters* (<em>list<String></em>): Additional parameters
          def execMySQLOtherSession(iMySQLHost, iDBName, iDBUser, iDBPassword, *iParameters)
            execCmdOtherSession(". #{$WEACEToolkitDir}/Slave/Adapters/Redmine/DBEnv.sh", self, 'execMySQL', iMySQLHost, iDBName, iDBUser, iDBPassword, *iParameters)
          end

          # Get the User ID based on its name
          #
          # Parameters:
          # * *iSQL* (_Object_): The SQL connection
          # * *iUserName* (_String_): User name to look for
          # Return:
          # * _String_: Corresponding user ID
          def getUserID(iSQL, iUserName)
            rUserID = nil
            
            iSQL.query(
              "select id
               from users
               where
                 login = '#{iUserName}'").each do |iRow|
              rUserID = iRow[0]
            end
            # If the user does not exist, create it if it is Scripts_Validator or Scripts_Developer
            if (rUserID == nil)
              if ((iUserName == 'Scripts_Validator') or
                  (iUserName == 'Scripts_Developer'))
                rUserID = createUser(iSQL, iUserName)
              else
                logExc RuntimeError, "User #{iUserName} is not allowed to perform operations."
              end
            end
            
            return rUserID
          end
          
          # Create a user, and get its ID back
          #
          # Parameters:
          # * *iSQL* (_Object_): The SQL connection
          # * *iUserName* (_String_): User name to look for
          # Return:
          # * _String_: Corresponding user ID
          def createUser(iSQL, iUserName)
            rUserID = nil
              
            iSQL.query(
              "insert
                 into users
                 ( login,
                   hashed_password,
                   firstname,
                   lastname,
                   mail,
                   mail_notification,
                   admin,
                   status,
                   language,
                   created_on,
                   updated_on)
                 values (
                   #{iUserName},
                   'd443f2ee6aa7c899023abb3f3fad2240000ed021',
                   '#{iUserName}',
                   '#{iUserName}',
                   '#{iUserName}',
                   0,
                   0,
                   1,
                   'en',
                   '#{DateTime.now.strftime('%Y-%m-%d %H:%M:%S')}',
                   '#{DateTime.now.strftime('%Y-%m-%d %H:%M:%S')}'
                 )")
            rUserID = iSQL.insert_id()
            
            return rUserID
          end
          
        end
        
      end
      
    end
    
  end
  
end
