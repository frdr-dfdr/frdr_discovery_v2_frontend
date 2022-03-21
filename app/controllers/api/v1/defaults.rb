module API 
  module V1
    module Defaults
      extend ActiveSupport::Concern

      included do
        prefix "platform"
	#version "v1", using: :path
	content_type :json, 'application/json; charset=UTF-8'
	content_type :txt, 'text/html; charset=UTF-8'	
        default_format :json
        format :json
        formatter :json, 
             Grape::Formatter::ActiveModelSerializers

        helpers do
          def permitted_params
            @permitted_params ||= declared(params, 
               include_missing: false)
          end

          def logger
            Rails.logger
          end
        end

        rescue_from ActiveRecord::RecordNotFound do |e|
          error_response(message: e.message, status: 404)
        end

        rescue_from ActiveRecord::RecordInvalid do |e|
          error_response(message: e.message, status: 422)
        end
      end
    end
  end
end
