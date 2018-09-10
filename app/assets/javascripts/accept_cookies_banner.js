var chf = chf || {}
$( document ).ready(function() {
    if (jQuery('.accept_cookies_banner_nav').length) {
        chf.set_up_accept_cookies_banner();
    }
});
chf.set_up_accept_cookies_banner = function () {
    if (! chf.cookies_already_accepted_by_user()) {
        jQuery('.accept_cookies_banner_nav').fadeIn(1000);
    }
    jQuery ('.i-accept-link').click(chf.user_accepts_our_cookies);
}
chf.cookies_already_accepted_by_user = function () {
    return document.cookie.match(/user_accepts_our_cookies=true/) != null;
}
chf.user_accepts_our_cookies = function(event) {
    event.preventDefault();
    var expiraton_str = new Date(new Date()
        .setFullYear(new Date()
        .getFullYear() + 3))
        .toString();
    document.cookie = "user_accepts_our_cookies=true; path=/; expires=" + expiraton_str
    jQuery('.accept_cookies_banner_nav').fadeOut(1000);
}
chf.user_does_not_accept_our_cookies = function() {
    // This is useful for testing; just call this function
    // from the console and you can test repeatedly.
    document.cookie = "user_accepts_our_cookies=false;"
    jQuery('.accept_cookies_banner_nav').fadeIn(1000);
}