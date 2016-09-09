var chf = chf || {}

chf.load_from_opac = function() {
  // get bib number from form
  var bibnum = chf.get_bib_num();
  if (bibnum === null) { return; }
  // TODO: get resource type from form
  // get json response.
  var request = new XMLHttpRequest();
  request.open('GET', '/opac_data/' + bibnum + '.json', true);

  request.onload = function() {
    if (request.status >= 200 && request.status < 400) {
      // Success!
      data = JSON.parse(request.responseText);
      data = JSON.stringify(data, null, 2);
      chf.display_data(data);
    } else {
      // We reached our target server, but it returned an error
      data = request.status + ': ' + 'bad request';
      chf.display_data(data);
    }
  };

  request.onerror = function() {
    var data = 'Opac API connection error'
    chf.display_data(data);
  };

  request.send();
};

chf.get_bib_num = function() {
  //return '123';
  //return 'B10691054';
  var html_col = document.getElementsByClassName('generic_work_bib_external_id');
  if (html_col.length > 1) {
    chf.display_data('Too many bib numbers provided');
    return null;
  } else if (html_col.length < 1) {
    chf.display_data('No bib numbers provided');
    return null;
  } else {
    return html_col.item(0).value;
  }
};

chf.display_data = function(data) {
  // insert into box below button.
  p = chf.get_data_container();
  p.textContent = data;
};

chf.get_data_container = function() {
  var pre = document.getElementById('opac_data_message');
  if (pre === null) {
    var data_box = document.createElement('div');
    data_box.setAttribute('class', 'well');
    document.getElementById('opac_data').appendChild(data_box);
    p = document.createElement('p');
    data_box.appendChild(p);
    pre = document.createElement('pre');
    p.appendChild(pre);
    pre.setAttribute('id', 'opac_data_message');
  }
  return pre;
}

Blacklight.onLoad(function() {
  // attach action to button
  var el = document.getElementById('load_opac_data');
  if (el) { el.addEventListener('click', chf.load_from_opac) };
});
