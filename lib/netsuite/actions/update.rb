# https://system.netsuite.com/help/helpcenter/en_US/Output/Help/SuiteCloudCustomizationScriptingWebServices/SuiteTalkWebServices/update.html
module NetSuite
  module Actions
    class Update
      include Support::Requests

      attr_reader :response_hash

      def initialize(klass, attributes)
        @klass      = klass
        @web_services_preferences = {}

        if attributes.has_key?(:run_suite_scripts)
          @web_services_preferences[:run_suite_scripts] = attributes.delete(:run_suite_scripts)
        end

        @attributes = attributes
      end

      def request(credentials={})
        connection_params = { web_services_preferences: @web_services_preferences }
        NetSuite::Configuration.connection(connection_params, credentials).call :update, :message => request_body
      end

      # <platformMsgs:update>
      #   <platformMsgs:record internalId="980" xsi:type="listRel:Customer">
      #     <listRel:companyName>Shutter Fly Corporation</listRel:companyName>
      #   </platformMsgs:record>
      # </platformMsgs:update>
      def request_body
        hash = {
          'platformMsgs:record' => {
            :content! => updated_record.to_record,
            '@xsi:type' => updated_record.record_type
          }
        }

        if updated_record.respond_to?(:internal_id) && updated_record.internal_id
          hash['platformMsgs:record']['@platformMsgs:internalId'] = updated_record.internal_id
        end

        if updated_record.respond_to?(:external_id) && updated_record.external_id
          hash['platformMsgs:record']['@platformMsgs:externalId'] = updated_record.external_id
        end

        hash
      end

      def updated_record
        @updated_record ||= @klass.new(@attributes)
      end

      def success?
        @success ||= response_hash[:status][:@is_success] == 'true'
      end

      def response_body
        @response_body ||= response_hash[:base_ref]
      end

      def response_errors
        if response_hash[:status] && response_hash[:status][:status_detail]
          @response_errors ||= errors
        end
      end

      def response_hash
        @response_hash ||= @response.to_hash[:update_response][:write_response]
      end

      def errors
        error_obj = response_hash[:status][:status_detail]
        error_obj = [error_obj] if error_obj.class == Hash
        error_obj.map do |error|
          NetSuite::Error.new(error)
        end
      end

      module Support
        def update(options = {}, credentials = {}, web_services_preferences = {})

          if web_services_preferences.has_key?(:run_suite_scripts)
            options.merge!(run_suite_scripts: web_services_preferences[:run_suite_scripts])
          end

          options.merge!(:internal_id => internal_id) if respond_to?(:internal_id) && internal_id

          if !options.include?(:external_id) && (respond_to?(:external_id) && external_id)
            options[:external_id] = external_id
          end

          options.merge!(:external_id => external_id) if respond_to?(:external_id) && external_id

          response = NetSuite::Actions::Update.call([self.class, options], credentials)
          @errors = response.errors
          response.success?
        end
      end
    end
  end
end
