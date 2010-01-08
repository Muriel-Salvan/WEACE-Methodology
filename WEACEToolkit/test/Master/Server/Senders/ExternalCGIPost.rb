#--
# Copyright (c) 2009 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

require 'net/http'

module Net

  class HTTP

    # Method used to replace post_form
    #
    # Parameters:
    # * *iURL* (_String_): URL of the post
    # * *iParams* (<em>map<String,String></em>): Set of variables given as POST
    # Return:
    # * _Object_: The HTTP response
    def self.post_form_Regression(iURL, iParams)
      if ($Variables[:HTTPPosts] == nil)
        $Variables[:HTTPPosts] = []
      end
      $Variables[:HTTPPosts] << [ iURL.to_s, iParams ]

      return WEACE::Test::Master::Senders::ExternalCGIPost::DummyHTTPAnswer.new
    end

  end

end

module WEACE

  module Test

    module Master

      module Senders

        class ExternalCGIPost < ::Test::Unit::TestCase

          include WEACE::Test::Master::Senders::Common

          # Class used to simulate an HTTP response
          class DummyHTTPAnswer

            # Get the response type
            #
            # Return:
            # * _Object_: The response type
            def response
              # TODO: Don't know really much about this constructor. Maybe change values ?
              return Net::HTTPOK.new(1,2,3)
            end

            # Get the response entity
            #
            # Return:
            # * _String_: The response's body
            def entity
              return 'CGI_EXIT: OK'
            end

          end

          include WEACE::Test::Master::Senders::Common

          # Give additional execution parameters to be given to executeSender method
          #
          # Return:
          # * <em>map<Symbol,Object></em>: The additional parameters
          def getExecutionParameters
            return {
              :InstantiateVariables => {
                :ExternalCGIURL => 'http://ExternalURL'
              }
            }
          end

          # Prepare for execution.
          # Use this method to bypass methods to better track WEACE behaviour.
          #
          # Parameters:
          # * *CodeBlock*: The code to call once preparation is done
          def prepareExecution
            WEACE::Test::Common::changeSingletonMethod(
              Net::HTTP,
              :post_form,
              :post_form_Regression,
              true
            ) do
              yield
            end
          end

          # Get back the User ID and the Actions once sent.
          # This method is also used to assert some specific parts of the execution.
          #
          # Return:
          # * _String_: The User ID
          # * <em>map<String,map<String,list<list<String>>>></em>: The Actions
          def getUserActions
            assert($Variables[:HTTPPosts] != nil)
            assert_equal(1, $Variables[:HTTPPosts].size)
            lPostURL, lPostInfo = $Variables[:HTTPPosts][0]
            assert_equal('http://ExternalURL', lPostURL)
            assert(lPostInfo.kind_of?(Hash))
            assert(lPostInfo['actions'] != nil)

            return lPostInfo['userid'], Marshal.load(lPostInfo['actions'])
          end

        end

      end

    end

  end

end