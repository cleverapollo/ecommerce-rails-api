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

      def recommendations_in_hash(items, source_item, location, currency, utm_params = {}, width = nil, height = nil)
        merge_fields = {}
        counter = 1

        items.each do |item|
          merge_fields["NAME#{counter}"] = item.name
          merge_fields["URL#{counter}"] = UrlParamsHelper.add_params_to(item.url, utm_params)
          merge_fields["PRICE#{counter}"] = "#{ActiveSupport::NumberHelper.number_to_rounded(item.price_at_location(location), precision: 0, delimiter: " ")} #{currency}"
          merge_fields["IMAGE#{counter}"] = "src=\"#{(width && height ? item.resized_image(width, height) : item.image_url)}\""
          counter+=1
        end

        if source_item.present?
          merge_fields["SRC_NAME"] = source_item.name
          merge_fields["SRC_URL"] = source_item.url
          merge_fields["SRC_PRICE"] = "#{ActiveSupport::NumberHelper.number_to_rounded(source_item.price_at_location(location), precision: 0, delimiter: " ")} #{currency}"
          merge_fields["SRC_IMAGE"] = "src=\"#{source_item.image_url}\""
        end

        merge_fields
      end

      def delete_camping_and_list(api, campaign_id, list_id)
        api.delete_campaign(campaign_id)
        api.delete_list(list_id)
      end

    end
  end
end

