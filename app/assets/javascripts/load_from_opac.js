var chf = chf || {}

chf.load_from_opac = function() {
  // get json response.
  var response = 'hello';
  // insert into box below button.
  var data_box = document.createElement('div');
  data_box.setAttribute('class', 'well');
  var p = document.createElement('p');
  p.textContent = response;
  data_box.appendChild(p);
  document.getElementById('opac_data').appendChild(data_box);
};

Blacklight.onLoad(function() {
  // attach action to button
  var el = document.getElementById('load_opac_data');
  el.addEventListener('click', chf.load_from_opac);
});
