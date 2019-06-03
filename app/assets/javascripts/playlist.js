$( document ).ready(function() {

	setup();

	function da_select(key){
		return $("[data-role='" + key + "']");
	}

	function setup() {
		if (da_select('audio-playlist-wrapper').length = 0) {
			return;
		}
		$("[data-role='play-link']").click(user_clicked_on_a_track);
		var first_track = da_select('track-listing')[0];
		prepare_track_for_play(first_track);
		audio_element().onended = play_next_track;
	}

	function user_clicked_on_a_track(ev) {
		ev.preventDefault();
		var the_track = $(ev.target).parent();
		prepare_track_for_play(the_track);
		play_audio();
	}

	function prepare_track_for_play(track) {
		// css (for styling)
		da_select('track-listing').removeClass("currently-selected");
		$(track).addClass("currently-selected");

		// data attribute (for identifying the item).
		// da_select('track-listing').data('currently-selected', false);
		// $(track).data('currently-selected', true);
		da_select('track-listing').attr('data-currently-selected', 'false');
		$(track).attr('data-currently-selected', 'true');


		da_select('current-track-label').html( $(track).data('title'));
		da_select('mp3-download')[0].href = $(track).data('mp3Url');
		da_select('original-download')[0].href = $(track).data('mp3Url');
        da_select('audio-mp3-source' )[0].src = $(track).data('mp3Url');
        da_select('audio-webm-source')[0].src = $(track).data('webmUrl');
	}

	function audio_element() {
		return da_select('audio-elem')[0];
	}

	function play_audio() {
		// See : https://stackoverflow.com/questions/9421505/switch-audio-source-with-jquery-and-html5-audio-tag
		el = audio_element();
		el.pause();
		el.load();
		el.oncanplaythrough = el.play();
	}

	function play_next_track() {
		prepare_track_for_play($("[data-currently-selected='true']").next()[0]);
		play_audio();
	}
 });
