/* Somewhat hacky, written by we who aren't great at JS, based on JQuery
   and using an HTML5 audio element.

   An audio player with playlist below, where clicking on an item from the playlist
   loads in audio player (and starts playing). When one track finishes, starts playing
   the next automatically.

   Clicking a track to 'load' it in player also sets download links for currently
   playing track.
*/

$( document ).ready(function() {

	function ChfAudioPlaylist(playlistWrapper) {
	  this.playlistWrapper = $(playlistWrapper);

	  this.firstTrack 		 = this.da_select('track-listing')[0];
	  this.audioElement    = this.da_select('audio-elem')[0];


	  this.audioElement.onended = this.play_next_track.bind(this);
	  this.playlistWrapper.on("click", "[data-role='play-link']", this.user_clicked_on_a_track.bind(this));

	  var first_track = this.da_select('track-listing')[0];
		this.prepare_track_for_play(first_track);

	};

	ChfAudioPlaylist.prototype.play_next_track = function() {
		this.prepare_track_for_play($("[data-currently-selected='true']").next()[0]);
		this.play_audio();
	};

	ChfAudioPlaylist.prototype.user_clicked_on_a_track = function(ev) {
		ev.preventDefault();
		var the_track = $(ev.target).parent();
		this.prepare_track_for_play(the_track);
		this.play_audio();
	};

	ChfAudioPlaylist.prototype.da_select = function(role) {
		return this.playlistWrapper.find("[data-role='" + role + "']");
	};

	ChfAudioPlaylist.prototype.play_audio = function() {
		// See : https://stackoverflow.com/questions/9421505/switch-audio-source-with-jquery-and-html5-audio-tag
		this.audioElement.pause();
		this.audioElement.load();
		this.audioElement.oncanplaythrough = this.audioElement.play();
	};

	ChfAudioPlaylist.prototype.prepare_track_for_play = function(track) {
		// css (for styling)
		this.da_select('track-listing').removeClass("currently-selected");
		$(track).addClass("currently-selected");

		// data attribute (for identifying the item).
		// da_select('track-listing').data('currently-selected', false);
		// $(track).data('currently-selected', true);
		this.da_select('track-listing').attr('data-currently-selected', 'false');
		$(track).attr('data-currently-selected', 'true');

		this.da_select('current-track-label').html( $(track).data('title'));
		this.da_select('mp3-download')[0].href = $(track).data('mp3Url');
		this.da_select('original-download')[0].href = $(track).data('mp3Url');
		this.da_select('audio-mp3-source' )[0].src = $(track).data('mp3Url');
		this.da_select('audio-webm-source')[0].src = $(track).data('webmUrl');
	};

	$("[data-role='audio-playlist-wrapper']").each(function() {
		new ChfAudioPlaylist(this);
	});
 });
