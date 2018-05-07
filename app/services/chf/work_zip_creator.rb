require 'zip'

module CHF
  # Create a ZIP of full-size JPGs of all images in a work.
  #
  # If a work contains child items, only one single representative image for each
  # child is included.
  class WorkZipCreator
    class_attribute :working_dir
    self.working_dir = Pathname.new(Dir.tmpdir) + "scihist_zip_create"

    attr_reader :work_id

    def initialize(work_id)
      @work_id = work_id
    end


    # Writes zip to specified path, if path not given will write to a tempfile, and return
    # it _without_ closing/unlinking it.
    def create_zip(filepath: nil, callback: nil)
      if filepath.nil?
        # See http://thinkingeek.com/2013/11/15/create-temporary-zip-file-send-response-rails/
        # for explanation of the way we are using Zip library that looks weird.

        FileUtils.mkdir_p working_dir
        tmp_file = Tempfile.new("zip-#{work_id}", working_dir).tap { |t| t.binmode }
        Zip::OutputStream.open(tmp_file) { |z| }
        filepath = tmp_file.path
      end

      tmp_comment_file = Tempfile.new("zip-#{work_id}-comment", working_dir)
      tmp_comment_file.write(comment_text)
      tmp_comment_file.rewind

      count = members_to_include.size

      Zip::File.open(filepath, Zip::File::CREATE) do |zipfile|
        zipfile.comment = comment_text

        zipfile.add("about.txt", tmp_comment_file)

        members_to_include.each_with_index do |member, index|
          filename = "#{format '%03d', index+1}-#{work_id}-#{member.id}.jpg"
          img_data = open(url_or_path_for_member(member), "rb")
          zipfile.add(filename, img_data)

          # We don't really need to update on every page, the front-end is only polling every two seconds anyway
          if callback && (index % 3 == 0 || index == count - 1)
            callback.call(progress_total: count, progress_i: index + 1)
          end
        end
      end

      return tmp_file
    ensure
      tmp_comment_file.close
      tmp_comment_file.unlink
    end

    protected

    def work_presenter
      @work_presenter ||= begin
        solr_doc = SolrDocument.find(work_id)
        presenter = CurationConcerns::GenericWorkShowPresenter.new(solr_doc, Ability.new(nil))
      end
    end

    def members_to_include
      work_presenter.public_member_presenters
    end

    def comment_text
      @comment_text ||= <<~EOS
        Courtesy of the Science History Institute, https://sciencehistory.org

        #{work_presenter.title.first}
        #{CHF::Env.lookup!(:app_url_base)}/works/#{work_id}

        Prepared on #{Time.now}
        EOS
    end

    # The stack API is a mess here, and sadly our home-grown image service API is NOT
    # working out well for expanded use cases.
    def url_or_path_for_member(member)
      if [nil, "legacy", :legacy].include? CHF::Env.lookup(:image_server_downloads)
        CurationConcerns::DerivativePath.derivative_path_for_reference(member.representative_file_set_id, "jpeg")
      elsif CHF::Env.lookup(:image_server_downloads).to_s == "dzi_s3"
        CreateDerivativesOnS3Service.s3_url(
          file_set_id: member.representative_file_set_id,
          file_checksum: member.representative_checksum,
          type_key: "dl_full_size"
        )
      else
        raise TypeError, "Don't know how to get JPG source for CHF::Env.lookup(:image_server_downloads): `#{CHF::Env.lookup(:image_server_downloads).inspect}`"
      end
    end
  end
end
