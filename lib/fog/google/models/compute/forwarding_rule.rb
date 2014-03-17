require 'fog/core/model'

module Fog
  module Compute
    class Google

      class ForwardingRule < Fog::Model

        identity :name

        attribute :kind, :aliases => 'kind'
        attribute :self_link, :aliases => 'selfLink'
        attribute :id, :aliases => 'id'
        attribute :creation_timestamp, :aliases => 'creationTimestamp'
        attribute :description, :aliases => 'description'
        attribute :region, :aliases => 'region'
        attribute :ip_address, :aliases => 'IPAddress'
        attribute :ip_protocol, :aliases => 'IPProtocol'
        attribute :port_range, :aliases => 'portRange'
        attribute :target, :aliases => 'target'

        def save
          requires :name, :region, :port_range, :target

          options = {
            'description' => description,
            'region' => region,
            'IPAddress' => ip_address,
            'IPProtocol' => ip_protocol,
            'portRange' => port_range,
            'target' => target
          }

          service.insert_forwarding_rule(name, region, options).body
          data = service.backoff_if_unfound {service.get_forwarding_rule(name, region).body}
          service.forwarding_rules.merge_attributes(data)
        end

        def destroy
          requires :name, :region
          operation = service.delete_forwarding_rule(name, region)
          # wait until "RUNNING" or "DONE" to ensure the operation doesn't fail, raises exception on error
          Fog.wait_for do
            operation = service.get_region_operation(region, operation.body["name"])
            operation.body["status"] != "PENDING"
          end
          operation
        end

        def reload
          requires :name, :region

          return unless data = begin
            collection.get(name, region)
          rescue Excon::Errors::SocketError
            nil
          end

          new_attributes = data.attributes
          merge_attributes(new_attributes)
          self
        end

        RUNNING_STATE = "READY"
      end
    end
  end
end
