var chf = chf || {}

chf.load_from_opac = function() {
  // get bib number from form
  var bibnum = chf.get_bib_num();
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
      data = JSON.parse(request.responseText);
      data = JSON.stringify(data, null, 2);
      data = request.status + ': ' + data;
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
  return 'B10691054';
};

chf.display_data = function(data) {
  // insert into box below button.
  var data_box = document.createElement('div');
  data_box.setAttribute('class', 'well');
  var p = document.createElement('p');
  p.textContent = data;
  data_box.appendChild(p);
  document.getElementById('opac_data').appendChild(data_box);
};

Blacklight.onLoad(function() {
  // attach action to button
  var el = document.getElementById('load_opac_data');
  el.addEventListener('click', chf.load_from_opac);
});
