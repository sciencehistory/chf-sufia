$( document ).ready(function() {

  // A JS 'class' for handling download UI

  function ChfOnDemandDownloader(work_id, type) {
    this.work_id = work_id;
    this.deriv_type = type;
  }

  ChfOnDemandDownloader.prototype.fetchForStatus = function() {
    var _self = this;

    fetch("/works/" + this.work_id + "/pdf").then(function(response) {
      return response.json();
    }).then(function(json) {
      if (json.status == "success") {
        if (existing = _self.getModal(true)) {
          existing.modal("hide");
        }
        window.location = json.url;
      } else if (json.status == "in_progress") {
        _self.updateProgress(json);
        _self.getModal().modal("show");
        // wait, then check again....
        _self.nextFetch = setTimeout(function() {
          _self.fetchForStatus();
        }, 2000);
      } else {
        json_error = JSON.parse(json.error_info);
        throw json_error.class + ": " + json_error.message;
      }
    }).catch(function(error) {
      _self.handleError(error);
    });
  };

  ChfOnDemandDownloader.prototype.getModal = function(lazy) {
    var _self = this;
    if (_self.modalElement) {
      return _self.modalElement;
    } else if (lazy) {
      return undefined;
    }
    //create a new bootstrap modal
    var modalEl = $('\
      <div class="modal on-demand-download" role="dialog"> \
        <div class="modal-dialog" role="document">\
          <div class="modal-content">\
            <div class="modal-header">\
              <span class="modal-title">Preparing your ' + _self.deriv_type.toUpperCase() + ' download</span>\
            </div>\
            <div class="modal-body">\
              <div data-progress-placeholder></div>\
              <p>Large downloads may take some time to prepare. We appreciate your patience.</p>\
            </div>\
            <div class="modal-footer">\
              <button type="button" class="btn btn-primary" data-dismiss="modal">Cancel</button>\
            </div>\
          </div>\
        </div>\
      </div> \
    ');
    $("body").append(modalEl);

    modalEl.modal({
      backdrop: true,
      show: false
    });

    // make sure any fetches get cancelled if modal is cancelled.
    modalEl.on('hidden.bs.modal', function (e) {
      if (_self.nextFetch) {
        clearTimeout(_self.nextFetch);
        _self.nextFetch = null;
      }
      // and destroy the element so we can create a new one later on another
      // click, without interfering. JQuery-based dev is a bit hacky...
      _self.modalElement.remove();
      _self.modalElement = null;
    })

    _self.modalElement = modalEl;

    return _self.modalElement;
  };

  ChfOnDemandDownloader.prototype.updateProgress = function(json_response) {
    html = "";

    if (json_response.progress && json_response.progress_total) {
      html = '<div class="progress">' +
                '<div class="progress-bar" role="progressbar" aria-valuemin="0" aria-valuenow="' +
                    json_response.progress + '" aria-valuemax="' + json_response.progress_total + '"' +
                    'style="width: ' + Math.floor((json_response.progress / json_response.progress_total) * 100) + '%;"' +
                    '>' +
                '</div>' +
              '</div>';
    } else {
      html = '<div class="progress progress-striped active">\
              <div class="progress-bar"  role="progressbar" aria-valuenow="100" aria-valuemin="0" aria-valuemax="100" style="width: 100%">' +
              '</div>\
            </div>';
    }
    this.getModal().find("*[data-progress-placeholder]").html(html);
  };

  ChfOnDemandDownloader.prototype.handleError = function(error) {
    console.log("Error fetching on-demand derivative: " + error);
    this.getModal().find(".modal-body").html(
      '<h1 class="h2"><i class="fa fa-warning text-danger"></i> A software error occured.</h1>' +
      '<p class="text-danger">We\'re sorry, your download can not be delivered at this time.</p>'
    );
  };

  $(document).on('click', '*[data-download-deriv-type]', function(e) {
    e.preventDefault();

    var type = $(e.target).data("download-deriv-type");
    var id   = $(e.target).data("download-whole-work-deriv");

    var downloader = new ChfOnDemandDownloader(id, type);
    downloader.fetchForStatus();
  });
});
