# frozen_string_literal: true

# name: discourse-bulk-import
# about: TODO
# meta_topic_id: TODO
# version: 0.0.1
# authors: Discourse
# url: TODO
# required_version: 2.7.0

enabled_site_setting :discourse_bulk_import_enabled

module ::DiscourseBulkImport
  PLUGIN_NAME = "discourse-bulk-import"
end

require_relative "lib/discourse_bulk_import/engine"

after_initialize do
  # Code which should run after Rails has finished booting
end
