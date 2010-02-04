#--
# Copyright (c) 2010 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module WEACE

  module Test

    module Install

      # Get variable options, based on the context we want for our regression
      # Method used to describe variable options in Components including GenericComponentTestBody.
      #
      # Return:
      # * <em>list<list<Object>></em>: List of options as given to the OptionParser.on method
      def self.getGenericComponentVarOptions
        rOptions = nil

        if ($Context[:ComponentInstall] != nil)
          if ($Context[:ComponentInstall][:AddFlagParameter])
            rOptions = [
              [
                :DummyFlag,
                '-f', '--dummyflag',
                'Dummy flag'
              ]
            ]
          elsif ($Context[:ComponentInstall][:AddVarParameter])
            rOptions = [
              [
                :DummyVar,
                '-v', '--dummyvar <VariableName>', String,
                'Dummy option'
              ]
            ]
          end
        end

        return rOptions
      end

      # This module is included by every Component that wants to track the way it is called.
      # This is meant to be used along eith test suites including WEACE::Test::Install::GenericComponent
      module GenericComponentTestBody

        # Error thrown by check
        class CheckError < RuntimeError
        end

        # Error thrown by execute
        class ExecError < RuntimeError
        end

        # Constructor
        def initialize
          # Put back methods if needed
          if (!self.respond_to?(:check))
            WEACE::Test::Install::GenericComponentTestBody::module_eval("alias :check :check_ORG")
          end
          if (!self.respond_to?(:execute))
            WEACE::Test::Install::GenericComponentTestBody::module_eval("alias :execute :execute_ORG")
          end
          if (!self.respond_to?(:getDefaultConfig))
            WEACE::Test::Install::GenericComponentTestBody::module_eval("alias :getDefaultConfig :getDefaultConfig_ORG")
          end
          # Move away methods if needed
          if ($Context[:ComponentInstall] != nil)
            if ($Context[:ComponentInstall][:NoCheck])
              WEACE::Test::Install::GenericComponentTestBody::module_eval("
                alias :check_ORG :check
                remove_method :check
                ")
            end
            if ($Context[:ComponentInstall][:NoExec])
              WEACE::Test::Install::GenericComponentTestBody::module_eval("
                alias :execute_ORG :execute
                remove_method :execute
                ")
            end
            if ($Context[:ComponentInstall][:NoDefaultConf])
              WEACE::Test::Install::GenericComponentTestBody::module_eval("
                alias :getDefaultConfig_ORG :getDefaultConfig
                remove_method :getDefaultConfig
                ")
            end
          end
        end

        # Check if we can install
        #
        # Return:
        # * _Exception_: An error, or nil in case of success
        def check
          rError = nil

          # Record everything we can
          if ($Variables[:ComponentInstall] == nil)
            $Variables[:ComponentInstall] = {}
          end
          if ($Variables[:ComponentInstall][:Calls] == nil)
            $Variables[:ComponentInstall][:Calls] = []
          end
          $Variables[:ComponentInstall][:Calls] << [ 'check', [] ]
          $Variables[:ComponentInstall][:AdditionalParams] = @AdditionalParameters
          if (defined?(@DummyFlag))
            $Variables[:ComponentInstall][:DummyFlag] = @DummyFlag
          end
          if (defined?(@DummyVar))
            $Variables[:ComponentInstall][:DummyVar] = @DummyVar
          end
          $Variables[:ComponentInstall][:ProviderEnv] = @ProviderEnv
          if (defined?(@ProductConfig))
            $Variables[:ComponentInstall][:ProductConfig] = @ProductConfig
          end
          if (defined?(@ToolConfig))
            $Variables[:ComponentInstall][:ToolConfig] = @ToolConfig
          end

          if (($Context[:ComponentInstall] != nil) and
              ($Context[:ComponentInstall][:CheckFail]))
            rError = CheckError.new('Error during check')
          end

          return rError
        end

        # Install for real.
        # This is called only when check method returned no error.
        #
        # Return:
        # * _Exception_: An error, or nil in case of success
        def execute
          rError = nil

          if ($Variables[:ComponentInstall] == nil)
            $Variables[:ComponentInstall] = {}
          end
          if ($Variables[:ComponentInstall][:Calls] == nil)
            $Variables[:ComponentInstall][:Calls] = []
          end
          $Variables[:ComponentInstall][:Calls] << [ 'execute', [] ]

          if (($Context[:ComponentInstall] != nil) and
              ($Context[:ComponentInstall][:ExecFail]))
            rError = ExecError.new('Error during execute')
          end

          return rError
        end

        # Get the default configuration
        #
        # Return:
        # * _String_: The default configuration text to put in the configuration file.
        def getDefaultConfig
          if ($Variables[:ComponentInstall] == nil)
            $Variables[:ComponentInstall] = {}
          end
          if ($Variables[:ComponentInstall][:Calls] == nil)
            $Variables[:ComponentInstall][:Calls] = []
          end
          $Variables[:ComponentInstall][:Calls] << [ 'getDefaultConfig', [] ]

          return "{}"
        end

      end

    end

  end

end
