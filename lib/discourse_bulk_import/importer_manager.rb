# frozen_string_literal: true

class ImporterManager
  def initialize(data)
    @data = data
    @log = []
    @success_count = 0
  end

  def run
    @data.each_with_index do |topic_data, idx|
      title = topic_data["topic_title"]
      topic_label = I18n.t("bulk_import.topic_label", index: idx + 1, title: title)

      begin
        validate_topic!(topic_data)

        ActiveRecord::Base.transaction do
          first_post_data = topic_data["posts"].first
          topic_user = find_or_create_user(first_post_data)
          guardian = Guardian.new(topic_user)
          tags = topic_data["topic_tags"] || []

          topic = TopicCreator.create(
            topic_user,
            guardian,
            title: title,
            category: topic_data["topic_category_id"],
            created_at: first_post_data["created_at"],
            import_mode: true
          )

          unless topic&.persisted?
            raise I18n.t(
              "bulk_import.errors.topic_creation_failed",
              errors: topic&.errors&.full_messages&.join(", ") || I18n.t("bulk_import.errors.unknown")
            )
          end

          DiscourseTagging.tag_topic_by_names(topic, guardian, tags) if tags.any?

          topic_data["posts"].each_with_index do |post_data, pidx|
            begin
              user = find_or_create_user(post_data)
              PostCreator.create!(
                user,
                topic_id: topic.id,
                raw: post_data["raw"],
                created_at: post_data["created_at"]
              )
            rescue => post_err
              short_raw = post_data["raw"][0..40].gsub("\n", " ").strip
              raise I18n.t(
                "bulk_import.errors.post_failed",
                index: pidx + 1,
                username: post_data["username"],
                error: post_err.message,
                raw: short_raw.inspect
              )
            end
          end
        end

        @success_count += 1
      rescue => e
        formatted_error = e.message.include?("\n") ?
          "\n" + e.message.lines.map { |line| "  - #{line.strip.sub(/\A-+\s*/, '')}" }.join("\n") :
          e.message

        @log << I18n.t("bulk_import.errors.topic_failed", label: topic_label, error: formatted_error)
      end
    end

    {
      total: @data.size,
      successful: @success_count,
      failed: @data.size - @success_count,
      log: @log.empty? ? nil : @log
    }
  end

  private

  def validate_topic!(topic_data)
    errors = []
    title = topic_data["topic_title"].to_s.strip
    min_title_length = SiteSetting.min_topic_title_length

    errors << I18n.t("bulk_import.errors.missing_title") if title.empty?
    errors << I18n.t("bulk_import.errors.title_too_short", actual: title.length, min: min_title_length) if title.length < min_title_length

    unless topic_data["topic_category_id"].is_a?(Integer)
      errors << I18n.t("bulk_import.errors.invalid_category")
    end

    posts = topic_data["posts"]
    if !posts.is_a?(Array) || posts.empty?
      errors << I18n.t("bulk_import.errors.missing_posts")
    else
      posts.each_with_index do |post, i|
        %w[username email name raw created_at].each do |field|
          if post[field].to_s.strip.empty?
            errors << I18n.t("bulk_import.errors.missing_post_field", index: i + 1, field: field)
          end
        end

        min_length = (i.zero?) ? SiteSetting.min_first_post_length : SiteSetting.min_post_length
        raw_length = post["raw"].to_s.strip.length
        if raw_length < min_length
          errors << I18n.t("bulk_import.errors.post_too_short", index: i + 1, actual: raw_length, min: min_length)
        end
      end
    end

    raise errors.join("\n") unless errors.empty?
  end

  def find_or_create_user(user_info)
    username = user_info["username"]
    user = User.find_by_username(username)
    return user if user

    user = User.new(
      username: username,
      email: user_info["email"],
      name: user_info["name"],
      active: true,
      approved: true
    )
    user.save!(validate: false)
    user
  end
end
