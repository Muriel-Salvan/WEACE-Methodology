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

          include WEACE::Common

          module MiscUtils

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
                  logErr "User #{iUserName} is not allowed to perform operations."
                  raise RuntimeError, "User #{iUserName} is not allowed to perform operations."
                end
              end

              return rUserID
            end

            # Get the Ticket ID based on its subject
            #
            # Parameters:
            # * *iSQL* (_Object_): The SQL connection
            # * *iSubject* (_String_): Subject to look for
            # Return:
            # * _String_: Corresponding Ticket ID
            def getTicketID(iSQL, iSubject)
              rTicketID = nil

              iSQL.query(
                "select id
                 from issues
                 where
                   subject = '#{iSubject}'").each do |iRow|
                rTicketID = iRow[0]
              end
              # If the Ticket does not exist, error
              if (rTicketID == nil)
                logErr 'Ticket WEACE_Toolkit_Log does not exist.'
                raise RuntimeError, 'Ticket WEACE_Toolkit_Log does not exist.'
              end

              return rTicketID
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
        
          # Connect to Redmine's database
          #
          # Parameters:
          # * *iSQLExecuteObject* (_Object_): The object containing the SQL execution
          # * *iSQLMethodParameters* (<em>list<Object></em>): The parameters to give the SQL method
          # Return:
          # * _Exception_: An error, or nil in case of success
          def executeRedmine(iSQLExecuteObject, iSQLMethodParameters)
            return beginMySQLTransaction(
              @ProductConfig[:DBHost],
              @ProductConfig[:DBName],
              @ProductConfig[:DBUser],
              @ProductConfig[:DBPassword],
              iSQLExecuteObject,
              iSQLMethodParameters,
              :RubyMySQLLibDir => @ProductConfig[:RubyMySQLLibDir],
              :MySQLLibDir => @ProductConfig[:MySQLLibDir]
            )
          end

        end
        
      end
      
    end
    
  end
  
end
