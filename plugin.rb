# frozen_string_literal: true

# name: discourse-bulk-import
# about: A plugin that allows admins to upload a JSON file and import users, topics, posts, and tags in bulk.
# version: 0.0.1
# authors: Jahan Gagan
# url: https://github.com/jahan-ggn/discourse-bulk-import

enabled_site_setting :discourse_bulk_import_enabled

add_admin_route 'bulk_import.title', 'bulk-import'

module ::DiscourseBulkImport
  PLUGIN_NAME = "discourse-bulk-import"
end

require_relative "lib/discourse_bulk_import/engine"

register_asset "stylesheets/common/common.scss"

after_initialize do
  Discourse::Application.routes.append do
    get "/admin/plugins/bulk-import" => "bulk_import#index",
        :constraints => StaffConstraint.new
  end
end
