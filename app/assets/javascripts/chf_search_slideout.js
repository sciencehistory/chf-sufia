
// Arg should be container `form` object
function ChfSearchSlideout(element) {
  var _self = this;
  this.element = $(element);
  this.element.on("click touch hover", function() {
    _self.open();
  });

  // for some reason IE is not having it with focusin event.
  var ua = window.navigator.userAgent;
  if ( ua.indexOf("MSIE ") > -1 || ua.indexOf("Trident/") > -1) {
    this.element.find("input").on("focus", function() {
      _self.open();
    });
  } else {
    this.element.on("focusin", function() {
      _self.open();
    });
  }
};

ChfSearchSlideout.prototype.animationTime = 180;

ChfSearchSlideout.prototype.drawerElement = function() {
  return $(this.element).find('.search-options');
};

ChfSearchSlideout.prototype.open = function() {
  this.element.removeClass("closed").addClass("opened");
  this.installLeaveHandlers();
  this.drawerElement().slideDown(this.animationTime);
};

ChfSearchSlideout.prototype.close = function() {
  if (this.forceExpanded) {
    return;
  }

  this.element.removeClass("opened").addClass("closed");
  this.drawerElement().slideUp(this.animationTime);
  this.removeLeaveHandlers();
};

ChfSearchSlideout.prototype.navbarBreakpoint = function() {
  return 739;
};

ChfSearchSlideout.prototype.onResize = function() {
  if ( $(window).width() <= this.navbarBreakpoint()) {
    this.element.addClass("force-expanded");
    if (this.element.hasClass("closed")) {
      this.open();
    }
    this.forceExpanded = true;
  } else {
    this.element.removeClass("force-expanded");
    this.forceExpanded = false;
  }
};

ChfSearchSlideout.prototype.installLeaveHandlers = function() {
  var _self = this;
  this.element.on("mouseleave.chfSearchSlideout", function() {
    // if the text box or another input is focused, don't close.
    if (! $.contains(_self.element.get(0), $(':focus').get(0))) {
      _self.close();
    }
  });
  $("body").on("click.chfSearchSlideout touch.chfSearchSlideout focusin.chfSearchSlideout", function(e) {
    if (! $.contains(_self.element.get(0), e.target)) {
      _self.close();
    }
  });
};

ChfSearchSlideout.prototype.removeLeaveHandlers = function() {
  this.element.off(".chfSearchSlideout");
  $("body").off(".chfSearchSlideout");
};


jQuery(document).ready(function($) {
  var slideout = new ChfSearchSlideout($(".masthead .nav-search-form"));
  // If navbar is collapsed, put search slider dropdown down.
  $(window).on("load resize", function(e) {
    slideout.onResize();
  });
});
