jQuery(function() {

	setup();

	function setup () {
		jQuery('.track_listing .title').click(user_clicked_on_a_track);
		var first_track = jQuery('.track_listing')[0];
		prepare_track_for_play(first_track);
		audio_element().onended = play_next_track;
	}

	function user_clicked_on_a_track(ev) {
		var the_track = jQuery(ev.target).parent();
		prepare_track_for_play(the_track);
		play_audio();
	}

	function prepare_track_for_play(track) {
		jQuery('.track_listing').removeClass("currently_selected");
		jQuery(track).addClass("currently_selected");
		jQuery('.current-track-label').html( jQuery(track).data('title'));
		jQuery('.now_playing_info a.mp3_download'     )[0].href = jQuery(track).data('mp3Url');
		jQuery('.now_playing_info a.original_download')[0].href = '/downloads/' + jQuery(track).data('memberId');
		jQuery('.show-page-audio-playlist-wrapper audio source')[0].src = jQuery(track).data('mp3Url');
		jQuery('.show-page-audio-playlist-wrapper audio source')[1].src = jQuery(track).data('webmUrl');
	}

	function audio_element() {
		return jQuery('.show-page-audio-playlist-wrapper audio')[0];
	}

	function play_audio() {
		// See : https://stackoverflow.com/questions/9421505/switch-audio-source-with-jquery-and-html5-audio-tag
		el = audio_element();
		el.pause();
		el.load();
		el.oncanplaythrough = el.play();
	}

	function play_next_track() {
		prepare_track_for_play(jQuery('.currently_selected').next()[0]);
		play_audio();
	}
});