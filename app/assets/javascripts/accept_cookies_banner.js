var chf = chf || {}
$( document ).ready(function() {
    chf.set_up_accept_cookies_banner();
});
chf.set_up_accept_cookies_banner = function () {
    if (! chf.cookies_already_accepted_by_user()) {
        jQuery('.accept_cookies_banner_nav').fadeIn(1000);
    }
    jQuery ('.i-accept-link').click(chf.user_accepts_our_cookies);
}
chf.cookies_already_accepted_by_user = function () {
    // TODO:
    // 1) consider adding a path and/or expiration date.
    // 2) consider including jquery cookie library;
    // may work more consistently across browsers.
    return document.cookie.match(/user_accepts_our_cookies=true/) != null;
}
chf.user_accepts_our_cookies = function() {
    document.cookie = "user_accepts_our_cookies=true;"
    jQuery('.accept_cookies_banner_nav').fadeOut(1000);
}
chf.user_does_not_accept_our_cookies = function() {
    // This is useful for testing; just call this function
    // from the console and you can test repeatedly.
    document.cookie = "user_accepts_our_cookies=false;"
    jQuery('.accept_cookies_banner_nav').fadeIn(1000);
}