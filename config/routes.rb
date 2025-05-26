# frozen_string_literal: true

DiscourseBulkImport::Engine.routes.draw do
  post "/bulk_import" => "bulk_import#upload"
  get "/bulk/import" => "bulk_import#index"
end

Discourse::Application.routes.draw { mount ::DiscourseBulkImport::Engine, at: "/" }
