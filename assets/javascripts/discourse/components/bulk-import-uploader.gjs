import Component from "@ember/component";
import { action } from "@ember/object";
import { alias } from "@ember/object/computed";
import { getOwner } from "@ember/owner";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import DModal from "discourse/components/d-modal";
import icon from "discourse/helpers/d-icon";
import UppyUpload from "discourse/lib/uppy/uppy-upload";
import { i18n } from "discourse-i18n";

export default class BulkImportUploader extends Component {
  @service dialog;
  @service modal;

  modalIsVisible = false;
  modalResult = null;

  @alias("uppyUpload.uploading") addDisabled;

  constructor() {
    super(...arguments);
    this.isUploading = false;

    this.uppyUpload = new UppyUpload(getOwner(this), {
      id: "bulk-import-uploader",
      type: "json",
      uploadUrl: "/bulk_import",
      preventDirectS3Uploads: true,
      validateUploadedFilesOptions: {
        skipValidation: true,
      },
      perFileData: () => ({ action_key: this.actionKey }),
      onBeforeUpload: () => {
        this.set("isUploading", true);
      },
      uploadDone: (result) => {
        this.set("isUploading", false);
        this._onUploadSuccess(result);
      },
      onUploadError: (err) => {
        this.set("isUploading", false);
        i18n("admin.bulk_import.dialog.upload_error", {
          error: err.toString(),
        });
      },
    });
  }

  @action
  setupUploader(element) {
    this.uppyUpload.setup(element);
  }

  _onUploadSuccess(result) {
    try {
      this.setProperties({
        modalResult: result,
        modalIsVisible: true,
      });
    } catch (e) {
      i18n("admin.bulk_import.dialog.upload_error", { error: e.toString() });
    }
  }

  @action
  closeModal() {
    this.set("modalIsVisible", false);
  }

  <template>
    <div class="bulk-import-uploader-container">
      <div class="bulk-import-card">
        <h2 class="import-title">
          {{i18n "admin.bulk_import.title"}}
        </h2>
        <p class="import-description">
          {{i18n "admin.bulk_import.description"}}
        </p>
      </div>

      {{#if this.addDisabled}}
        <div style="margin: 16px 0; text-align: center;">
          <div class="spinner medium"></div>
          <p>{{i18n "admin.bulk_import.uploading"}}</p>
        </div>
      {{else}}
        <label class="btn btn-default {{if this.addDisabled 'disabled'}}">
          {{icon "upload"}}
          {{i18n "admin.bulk_import.form.upload"}}
          <input
            {{didInsert this.uppyUpload.setup}}
            class="hidden-upload-field"
            type="file"
            accept=".json,application/json"
          />
        </label>
      {{/if}}

      {{#if this.modalIsVisible}}
        <DModal
          @title={{i18n "admin.bulk_import.modal.title"}}
          @closeModal={{this.closeModal}}
        >
          <:body>
            <h2>{{this.modalResult.message}}</h2>

            <ul>
              <li><b>{{i18n "admin.bulk_import.modal.total"}}:</b>
                {{this.modalResult.total}}</li>
              <li><b>{{i18n "admin.bulk_import.modal.successful"}}:</b>
                {{this.modalResult.successful}}</li>
              <li><b>{{i18n "admin.bulk_import.modal.failed"}}:</b>
                {{this.modalResult.failed}}</li>
            </ul>

            {{#if this.modalResult.log}}
              <h3>{{i18n "admin.bulk_import.modal.log"}}</h3>
              <ul>
                {{#each this.modalResult.log as |line|}}
                  <li><pre>{{line}}</pre></li>
                {{/each}}
              </ul>
            {{/if}}
          </:body>
          <:footer>
            <DButton
              @label="admin.bulk_import.modal.ok"
              class="btn-primary"
              @action={{this.closeModal}}
            />
          </:footer>
        </DModal>
      {{/if}}
    </div>
  </template>
}
