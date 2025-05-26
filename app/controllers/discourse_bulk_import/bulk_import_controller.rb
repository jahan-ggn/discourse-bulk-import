# frozen_string_literal: true
require_relative "../../../lib/discourse_bulk_import/importer_manager.rb"

module ::DiscourseBulkImport
  class BulkImportController < ::ApplicationController
    requires_plugin PLUGIN_NAME

    def upload
      hijack do
        begin
          file = params[:file]

          if file.nil?
            render_json_error(I18n.t("admin.bulk_import.errors.no_file"), status: 400)
            next
          end

          data = JSON.parse(file.read)

          importer = ImporterManager.new(data)
          summary = importer.run

          render json: {
            success: true,
            message: I18n.t("bulk_import.modal.complete"),
            total: summary[:total],
            successful: summary[:successful],
            failed: summary[:failed],
            log: summary[:log]
          }
        rescue JSON::ParserError => e
          render_json_error(I18n.t("admin.bulk_import.errors.invalid_json", error: e.message), status: 400)
        rescue => e
          render_json_error(I18n.t("admin.bulk_import.errors.unexpected", error: e.message), status: 500)
        end
      end
    end

    def index
    end
  end
end
