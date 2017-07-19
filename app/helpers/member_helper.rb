# helpers for rendering things related to display of 'members' or children
# of works, on a work page. A member can be a file set or a child work.
module MemberHelper
  # returns a <ul> with <li>s suitable to be used inside a bootstrap
  # dropdown-toggle, representing download options for the member passed in.
  # also includes a rights statement from parent.
  #
  # first arg member is normally required, but can be passed as nil for
  # creating a blank template for JS filling, as in viewer.
  #
  # used in show_page_image and image_viewer.
  #
  # Originally was a partial instead of a helper, and probably more readable
  # that way, but performance impact of partial was too much, on work pages
  # that wanted to display many members and call these many times. Not entirely
  # sure why partial so much slower than helper, even in production config.
  def member_download_menu(member, parent:)
    list_elements = []

    if parent.has_rights_statement?
      list_elements <<
        content_tag("li",
          link_to(parent.rights_url,
                    target: "_blank",
                    class: 'rights-statement-inline') do
            safe_join([image_tag(parent.rights_icon, class: "rights-statement-logo"),
                       " ",
                       content_tag("span", parent.rights_icon_label, class: "rights-statement-label")])
          end
        )
      list_elements << "<li class='divider'></li>".html_safe
    end

    list_elements << '<li class="dropdown-header">Download this image</li>'.html_safe

    list_elements << content_tag("li",
                      link_to("Original Image", ( member ? main_app.download_path(member.representative_id) : "#" ),
                        target: "_new",
                        id: "file_download",
                        data: {
                          content_hook: "dl-original-link",
                          # These action/labels are what sufia/hyrax uses, although
                          # a bit weird. https://github.com/samvera/hyrax/blob/1e504c200fd9c39120f514ac33cd42cd843de9fa/app/assets/javascripts/hyrax/ga_events.js
                          analytics_category: "Work",
                          analytics_action: "download-tiff",
                          analytics_label: parent.id
                        })
                      )

    if CHF::Env.lookup(:use_image_server_downloads)
      list_elements << content_tag("li",
                        link_to("Full-size JPEG",
                          (member ? riiif_image_url(member.riiif_file_id, format: "jpg", size: "full") : "#"),
                          target: "_new",
                          data: {
                            content_hook: "dl-jpeg-link",
                            analytics_category: "Work",
                            analytics_action: "download-jpg",
                            analytics_label: parent.id
                          })
                        )
    end

    content_tag("ul", safe_join(list_elements), class: "dropdown-menu")
  end
end
