class CreateWorkPdfJob < ActiveJob::Base
  queue_as :jobs_server

  class_attribute :working_dir
  self.working_dir = Rails.root + "tmp" + "pdf_create"

  def perform(on_demand_record)
    FileUtils.mkdir_p(working_dir)
    tmp_file = Tempfile.new("pdf_#{on_demand_record.work_id}", working_dir).tap { |t| t.binmode }
    CHF::WorkPdfCreator.new(on_demand_record.work_id).write_pdf_to_stream(tmp_file)
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
