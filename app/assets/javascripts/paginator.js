(function() {
  Danbooru.Paginator = {};
  
  Danbooru.Paginator.next_page = function() {
    var href = $(".paginator a[rel=next]").attr("href");
    if (href) {
      window.location = href;
    }
  }

  Danbooru.Paginator.prev_page = function() {
    var href = $(".paginator a[rel=prev]").attr("href");
    if (href) {
      window.location = href;
    }
  }
})();

$(function() {
  if ($(".paginator").length) {
    $(document).bind("keydown.right", Danbooru.Paginator.next_page);
    $(document).bind("keydown.left", Danbooru.Paginator.prev_page);
  }
});

