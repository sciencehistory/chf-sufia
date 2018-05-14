class CreateWorkZipJob < ActiveJob::Base
  queue_as :jobs_server

  def perform(on_demand_record)
    working_dir = CHF::WorkZipCreator.working_dir

    FileUtils.mkdir_p(working_dir)
    tmp_file = Tempfile.new("zip_#{on_demand_record.work_id}", working_dir).tap { |t| t.binmode }
    CHF::WorkZipCreator.new(on_demand_record.work_id).create_zip(filepath: tmp_file.path, callback: lambda do |progress_i:, progress_total:|
      on_demand_record.update(progress: progress_i, progress_total: progress_total)
    end)
    tmp_file.rewind

    on_demand_record.write_from_path(tmp_file.path)
    on_demand_record.update(status: "success", byte_size: tmp_file.size())
  rescue StandardError => e
    Rails.application.log_error(e)
    on_demand_record.update(status: "error", error_info: {class: e.class.name, message: e.message, backtrace: e.backtrace}.to_json)
  ensure
    tmp_file.close
    tmp_file.unlink
  end
end
