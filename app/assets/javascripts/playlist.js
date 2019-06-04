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

	  this.firstTrack 		 = this.findByRole('track-listing')[0];
	  this.audioElement    = this.findByRole('audio-elem')[0];


	  this.audioElement.onended = this.playNextTrack.bind(this);
	  this.playlistWrapper.on("click", "[data-role='play-link']", this.onTrackClick.bind(this));

	  var first_track = this.findByRole('track-listing')[0];
		this.loadTrack(first_track);

	};

	ChfAudioPlaylist.prototype.playNextTrack = function() {
		var nextTrack = $("[data-currently-selected='true']").next()[0];
		if (nextTrack) {
			this.loadTrack(nextTrack);
			this.playAudio();
		}
	};

	ChfAudioPlaylist.prototype.onTrackClick = function(ev) {
		ev.preventDefault();
		var the_track = $(ev.target).parent();
		this.loadTrack(the_track);
		this.playAudio();
	};

	ChfAudioPlaylist.prototype.findByRole = function(role) {
		return this.playlistWrapper.find("[data-role='" + role + "']");
	};

	ChfAudioPlaylist.prototype.playAudio = function() {
		// See: https://stackoverflow.com/questions/9421505/switch-audio-source-with-jquery-and-html5-audio-tag
		// oncanplaythrough in case audio isn't fully loaded yet when we call this.
		this.audioElement.oncanplaythrough = this.audioElement.play();
	};

	ChfAudioPlaylist.prototype.loadTrack = function(track) {
		// css (for styling)
		this.findByRole('track-listing').removeClass("currently-selected");
		$(track).addClass("currently-selected");

		// data attribute (for identifying the item).
		// findByRole('track-listing').data('currently-selected', false);
		// $(track).data('currently-selected', true);
		this.findByRole('track-listing').attr('data-currently-selected', 'false');
		$(track).attr('data-currently-selected', 'true');

		this.findByRole('current-track-label').html( $(track).data('title'));
		this.findByRole('mp3-download')[0].href = $(track).data('mp3Url');
		this.findByRole('original-download')[0].href = $(track).data('mp3Url');
		this.findByRole('audio-mp3-source' )[0].src = $(track).data('mp3Url');
		this.findByRole('audio-webm-source')[0].src = $(track).data('webmUrl');

		// Tell HTML audio to load new stuff
		// See: https://stackoverflow.com/questions/9421505/switch-audio-source-with-jquery-and-html5-audio-tag
		this.audioElement.pause();
		this.audioElement.load();
	};

	$("[data-role='audio-playlist-wrapper']").each(function() {
		new ChfAudioPlaylist(this);
	});
 });
