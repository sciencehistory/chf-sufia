$( document ).ready(function() {

	setup();

	function setup() {
		if ($('.show-page-audio-playlist-wrapper').length == 0) {
			return;
		}
		$('.track_listing .title').click(user_clicked_on_a_track);
		var first_track = $('.track_listing')[0];
		prepare_track_for_play(first_track);
		audio_element().onended = play_next_track;
	}

	function user_clicked_on_a_track(ev) {
		var the_track = $(ev.target).parent();
		prepare_track_for_play(the_track);
		play_audio();
	}

	function prepare_track_for_play(track) {
		$('.track_listing').removeClass("currently_selected");
		$(track).addClass("currently_selected");
		$('.current-track-label').html( $(track).data('title'));
		$('.now_playing_info a.mp3_download'     )[0].href = $(track).data('mp3Url');
		$('.now_playing_info a.original_download')[0].href = '/downloads/' + $(track).data('memberId');
		$('.show-page-audio-playlist-wrapper audio source')[0].src = $(track).data('mp3Url');
		$('.show-page-audio-playlist-wrapper audio source')[1].src = $(track).data('webmUrl');
	}

	function audio_element() {
		return $('.show-page-audio-playlist-wrapper audio')[0];
	}

	function play_audio() {
		// See : https://stackoverflow.com/questions/9421505/switch-audio-source-with-jquery-and-html5-audio-tag
		el = audio_element();
		el.pause();
		el.load();
		el.oncanplaythrough = el.play();
	}

	function play_next_track() {
		prepare_track_for_play($('.currently_selected').next()[0]);
		play_audio();
	}
});