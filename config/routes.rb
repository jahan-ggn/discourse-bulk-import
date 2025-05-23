# frozen_string_literal: true

DiscourseBulkImport::Engine.routes.draw do
  get "/examples" => "examples#index"
  # define routes here
end

Discourse::Application.routes.draw { mount ::DiscourseBulkImport::Engine, at: "discourse-bulk-import" }
