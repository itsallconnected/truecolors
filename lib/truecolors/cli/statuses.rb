# frozen_string_literal: true

require_relative 'base'

module Truecolors::CLI
  class Statuses < Base
    include ActionView::Helpers::NumberHelper

    option :days, type: :numeric, default: 90
    option :batch_size, type: :numeric, default: 1_000, aliases: [:b], desc: 'Number of records in each batch'
    option :continue, type: :boolean, default: false, desc: 'If remove is not completed, execute from the previous continuation'
    option :clean_followed, type: :boolean, default: false, desc: 'Include the status of remote accounts that are followed by local accounts as candidates for remove'
    option :skip_status_remove, type: :boolean, default: false, desc: 'Skip status remove (run only cleanup tasks)'
    option :skip_media_remove, type: :boolean, default: false, desc: 'Skip remove orphaned media attachments'
    option :compress_database, type: :boolean, default: false, desc: 'Compress database and update the statistics. This option locks the table for a long time, so run it offline'
    desc 'remove', 'Remove unreferenced statuses'
    long_desc <<~LONG_DESC
      Remove statuses that are not referenced by local user activity, such as
      ones that came from relays, or belonging to users that were once followed
      by someone locally but no longer are.

      It also removes orphaned records and performs additional cleanup tasks
      such as updating statistics and recovering disk space.

      This is a computationally heavy procedure that creates extra database
      indices before commencing, and removes them afterward.
    LONG_DESC
    def remove
      fail_with_message 'Cannot run with this batch_size setting, must be at least 1' if options[:batch_size] < 1

      remove_statuses
      vacuum_and_analyze_statuses
      remove_orphans_media_attachments
      remove_orphans_conversations
      vacuum_and_analyze_conversations
    end

    private

    def remove_statuses
      return if options[:skip_status_remove]

      start_at = Time.now.to_f

      max_id   = Truecolors::Snowflake.id_at(options[:days].days.ago, with_random: false)

      unless options[:continue] && ActiveRecord::Base.connection.table_exists?('statuses_to_be_deleted')
        say('Extract the deletion target from statuses... This might take a while...')

        ActiveRecord::Base.connection.create_table('statuses_to_be_deleted', force: true)

        # Skip accounts followed by local accounts
        clean_followed_sql = 'AND NOT EXISTS (SELECT 1 FROM follows WHERE statuses.account_id = follows.target_account_id)' unless options[:clean_followed]

        ActiveRecord::Base.connection.exec_insert(<<-SQL.squish, 'SQL', [max_id])
          INSERT INTO statuses_to_be_deleted (id)
          SELECT statuses.id FROM statuses WHERE deleted_at IS NULL AND NOT local AND uri IS NOT NULL AND (id < $1)
          AND NOT EXISTS (SELECT 1 FROM statuses AS statuses1 WHERE statuses.id = statuses1.in_reply_to_id)
          AND NOT EXISTS (SELECT 1 FROM statuses AS statuses1 WHERE statuses1.id = statuses.reblog_of_id AND (statuses1.uri IS NULL OR statuses1.local))
          AND NOT EXISTS (SELECT 1 FROM statuses AS statuses1 WHERE statuses.id = statuses1.reblog_of_id AND (statuses1.uri IS NULL OR statuses1.local OR statuses1.id >= $1))
          AND NOT EXISTS (SELECT 1 FROM status_pins WHERE statuses.id = status_id)
          AND NOT EXISTS (SELECT 1 FROM mentions WHERE statuses.id = mentions.status_id AND mentions.account_id IN (SELECT accounts.id FROM accounts WHERE domain IS NULL))
          AND NOT EXISTS (SELECT 1 FROM favourites WHERE statuses.id = favourites.status_id AND favourites.account_id IN (SELECT accounts.id FROM accounts WHERE domain IS NULL))
          AND NOT EXISTS (SELECT 1 FROM bookmarks WHERE statuses.id = bookmarks.status_id AND bookmarks.account_id IN (SELECT accounts.id FROM accounts WHERE domain IS NULL))
          #{clean_followed_sql}
        SQL

        say('Removing temporary database indices to restore write performance...')
      end

      say('Beginning statuses removal... This might take a while...')

      klass = Class.new(ApplicationRecord) do |c|
        c.table_name = 'statuses_to_be_deleted'
      end

      Object.const_set(:StatusToBeDeleted, klass)

      scope     = StatusToBeDeleted
      processed = 0
      removed   = 0
      progress  = create_progress_bar(scope.count.fdiv(options[:batch_size]).ceil)

      scope.reorder(nil).in_batches(of: options[:batch_size]) do |relation|
        ids        = relation.pluck(:id)
        processed += ids.count
        removed   += Status.unscoped.where(id: ids).delete_all
        progress.increment
      end

      progress.stop

      ActiveRecord::Base.connection.drop_table('statuses_to_be_deleted')

      say("Done after #{Time.now.to_f - start_at}s, removed #{removed} out of #{processed} statuses.", :green)
    end

    def remove_orphans_media_attachments
      return if options[:skip_media_remove]

      start_at = Time.now.to_f

      say('Beginning removal of now-orphaned media attachments to free up disk space...')

      scope     = MediaAttachment.unattached.created_before(options[:days].pred.days.ago)
      processed = 0
      removed   = 0
      progress  = create_progress_bar(scope.count)

      scope.find_each do |media_attachment|
        media_attachment.destroy!

        removed += 1
      rescue => e
        progress.log pastel.red("Error processing #{media_attachment.id}: #{e}")
      ensure
        progress.increment
        processed += 1
      end

      progress.stop

      say("Done after #{Time.now.to_f - start_at}s, removed #{removed} out of #{processed} media_attachments.", :green)
    end

    def remove_orphans_conversations
      start_at = Time.now.to_f

      unless options[:continue] && ActiveRecord::Base.connection.table_exists?('conversations_to_be_deleted')
        say('Creating temporary database indices...')

        ActiveRecord::Base.connection.add_index(:statuses, :conversation_id, name: :index_statuses_conversation_id, algorithm: :concurrently, if_not_exists: true)

        say('Extract the deletion target from conversations... This might take a while...')

        ActiveRecord::Base.connection.create_table('conversations_to_be_deleted', force: true)

        ActiveRecord::Base.connection.exec_insert(<<-SQL.squish, 'SQL')
          INSERT INTO conversations_to_be_deleted (id)
          SELECT id FROM conversations WHERE NOT EXISTS (SELECT 1 FROM statuses WHERE statuses.conversation_id = conversations.id)
        SQL

        say('Removing temporary database indices to restore write performance...')
        ActiveRecord::Base.connection.remove_index(:statuses, name: :index_statuses_conversation_id, if_exists: true)
      end

      say('Beginning orphans removal... This might take a while...')

      klass = Class.new(ApplicationRecord) do |c|
        c.table_name = 'conversations_to_be_deleted'
      end

      Object.const_set(:ConversationsToBeDeleted, klass)

      scope     = ConversationsToBeDeleted
      processed = 0
      removed   = 0
      progress  = create_progress_bar(scope.count.fdiv(options[:batch_size]).ceil)

      scope.in_batches(of: options[:batch_size]) do |relation|
        ids        = relation.pluck(:id)
        processed += ids.count
        removed   += Conversation.unscoped.where(id: ids).delete_all
        progress.increment
      end

      progress.stop

      ActiveRecord::Base.connection.drop_table('conversations_to_be_deleted')

      say("Done after #{Time.now.to_f - start_at}s, removed #{removed} out of #{processed} conversations.", :green)
    ensure
      say('Removing temporary database indices to restore write performance...')
      ActiveRecord::Base.connection.remove_index(:statuses, name: :index_statuses_conversation_id, if_exists: true)
    end

    def vacuum_and_analyze_statuses
      if options[:compress_database]
        say('Running "VACUUM FULL ANALYZE statuses"...')
        ActiveRecord::Base.connection.execute('VACUUM FULL ANALYZE statuses')
        say('Running "REINDEX TABLE statuses"...')
        ActiveRecord::Base.connection.execute('REINDEX TABLE statuses')
      else
        say('Running "ANALYZE statuses"...')
        ActiveRecord::Base.connection.execute('ANALYZE statuses')
      end
    end

    def vacuum_and_analyze_conversations
      if options[:compress_database]
        say('Running "VACUUM FULL ANALYZE conversations"...')
        ActiveRecord::Base.connection.execute('VACUUM FULL ANALYZE conversations')
        say('Running "REINDEX TABLE conversations"...')
        ActiveRecord::Base.connection.execute('REINDEX TABLE conversations')
      else
        say('Running "ANALYZE conversations"...')
        ActiveRecord::Base.connection.execute('ANALYZE conversations')
      end
    end
  end
end
