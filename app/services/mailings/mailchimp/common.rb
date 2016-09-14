module Mailings
  module Mailchimp
    module Common

      def prepare_merge_fields_batch(list_id, items, source = false)
        operations = []
        (1..items).each do |item_counter|
          ['NAME', 'URL', 'PRICE', 'IMAGE'].each do |var|
            merge_field = {
              method: "POST",
              path: "lists/#{list_id}/merge-fields",
              body: {
                name: "#{var}#{item_counter}",
                tag: "#{var}#{item_counter}",
                type: "text",
                options: {
                  size: 2000
                }
              }.to_json
            }
            operations = operations + [merge_field]
          end
        end

        if source
          ['SRC_NAME', 'SRC_URL', 'SRC_PRICE', 'SRC_IMAGE'].each do |var|
            merge_field = {
              method: "POST",
              path: "lists/#{list_id}/merge-fields",
              body: {
                name: var,
                tag: var,
                type: "text",
                options: {
                  size: 2000
                }
              }.to_json
            }
            operations = operations + [merge_field]
          end
        end

        operations
      end

      def recommendations_in_hash(trigger, width = nil, height = nil)
        merge_fields = {}
        counter = 1

        (trigger.source_items).each do |item|
          merge_fields["NAME#{counter}"] = item.name
          merge_fields["URL#{counter}"] = item.url
          merge_fields["PRICE#{counter}"] = "#{ActiveSupport::NumberHelper.number_to_rounded(item.price_at_location(trigger.client.location), precision: 0, delimiter: " ")} #{trigger.shop.currency}"
          merge_fields["IMAGE#{counter}"] = "src=\"#{(width && height ? item.resized_image(width, height) : item.image_url)}\""
          counter+=1
        end

        if trigger.source_item.present?
          merge_fields["SRC_NAME"] = trigger.source_item.name
          merge_fields["SRC_URL"] = trigger.source_item.url
          merge_fields["SRC_PRICE"] = "#{ActiveSupport::NumberHelper.number_to_rounded(trigger.source_item.price_at_location(trigger.client.location), precision: 0, delimiter: " ")} #{trigger.shop.currency}"
          merge_fields["SRC_IMAGE"] = "src=\"#{trigger.source_item.image_url}\""
        end

        merge_fields
      end

    end
  end
end

