require_dependency Rails.root.join('lib','chf','reports','metadata_completion_report')

namespace :chf do

  desc 'Rough count metadata completion'
  task metadata_report: :environment do
    report = CHF::Reports::MetadataCompletionReport.new
    report.run
    path = File.path("/var/sufia/reports/metadata/")
    FileUtils.mkdir_p(path) unless File.exists?(path)
    fn = "completion-#{Date.today.strftime('%Y-%m-%d-%T')}.txt"
    File.open(File.join(path, fn), 'w') do |f|
      f.write(report.get_output)
      f.write("\n")
    end
  end

  desc 'Re-generate all derivatives'
  task create_derivatives: :environment do

    # Hack to monkey-patch MiniMagick to always add the 'quiet'
    # option to every imagemagick command line.
    class MiniMagick::Tool
      class_attribute :quiet_arg
      self.quiet_arg = false

      prepend(Module.new do
        def command
          if quiet_arg
            [*executable, *(['-quiet'] + args)]
          else
            super
          end
        end
      end)
    end
    MiniMagick::Tool.quiet_arg = true


    progress_bar = ProgressBar.create(:total => Sufia.primary_work_type.count, format: "%t: |%B| %p%% %e")
    Sufia.primary_work_type.all.find_each do |work|
      work.file_sets.each do |fs|
        fs.files.each do |file|
          filename = CurationConcerns::WorkingDirectory.find_or_retrieve(file.id, fs.id)
          fs.create_derivatives(filename)
        end
      end
      progress_bar.increment
    end
    MiniMagick::Tool.quiet_arg = false
  end

  desc 'Migrate titles and merge descriptions'
  task single_value_migration: :environment do
    CHF::Metadata::SingleValueMigration.run
    puts 'migration complete'
  end

  desc 'Reindex everything'
  task reindex: :environment do
    CHF::Indexer.new.reindex_everything(progress_bar: true, final_commit: true)
  end

  desc 'report translated titles'
  task translated: :environment do
    reporter = CHF::Metadata::TranslatedTitleUpdate.new
    reporter.run
    reporter.matches.each do |id, line|
      puts "#{id}:"
      line.each do |key, val|
        puts "  #{key}: #{val}"
      end
    end
    puts "total: #{reporter.matches.size}"
  end

  desc 'Reindex Collections'
  task reindex_collections: :environment do
    # reindex only Collections
    # not a frequent task but useful in upgrade to sufia 7.3
    # There aren't enough of them to really need batches, etc.

    progress_bar = ProgressBar.create(:total => Collection.count, format: "%t: |%B| %p%% %e")

    Collection.find_each do |coll|
      coll.update_index
      progress_bar.increment
    end

    $stderr.puts 'reindex_collections complete'
  end

  desc 'Reindex all GenericWorks'
  task reindex_works: :environment do
    # Like :reindex, but only GenericWorks, makes it faster,
    # plus let's us use other solr techniques to make it faster,
    # and allows us to add a progress bar easily.

    add_batch_size = ENV['ADD_BATCH_SIZE'] || 50

    progress_bar = ProgressBar.create(:total => GenericWork.count, format: "%t: |%B| %p%% %e")
    solr_service_conn = ActiveFedora::SolrService.instance.conn
    batch = []

    GenericWork.find_each do |work|
      batch << work.to_solr

      if batch.count % add_batch_size == 0
        solr_service_conn.add(batch, softCommit: true, commit: false)
        batch.clear
      end
      progress_bar.increment
    end
    if batch.present?
      solr_service_conn.add(batch, softCommit: true, commit: false)
      batch.clear
    end
    $stderr.puts "Issuing a solr commit..."
    solr_service_conn.commit

    $stderr.puts 'reindex_works complete'
  end

  desc 'csv report of related_urls'
  task :related_url_csv, [:output_path] => :environment do |t, args|
    output = args[:output_path] || "related_urls.csv"
    CHF::Metadata::RelatedUrlReport.new.to_csv(output)
  end

  namespace :admin do

    desc 'Grant admin role to existing user.'
    task :grant, [:email] => :environment do |t, args|
      begin
        CHF::Utils::Admin.grant(args[:email])
      rescue ActiveRecord::RecordNotFound
        abort("User #{args[:email]} does not exist. Only an existing user can be promoted to admin")
      end
      puts "User: #{u.email} is an admin."
    end

    desc 'Revoke admin role from user.'
    task :revoke, [:email] => :environment do |t, args|
      CHF::Utils::Admin.revoke(args[:email])
      puts "User: #{u.email} is no longer an admin."
    end

    desc 'List all admin users'
    task list: :environment do
      puts "Admin users:"
      Role.find_by(name: 'admin').users.each { |u| puts "  #{u.email}" }
    end

  end

  namespace :user do

    desc 'Create a user without a password; they can request one from the UI'
    task :create, [:email] => :environment do |t, args|
      u = User.create!(email: args[:email])
      puts "User created with email address #{u.email}."
      puts "Please request a password via the 'Forgot your password?' page."
    end

    namespace :test do
      desc 'Create a test user with a password; not secure for actual users'
      task :create, [:email, :pass] => :environment do |t, args|
        u = User.create!(email: args[:email], password: args[:pass])
        puts "Test user created"
      end

    end
  end
end
