var is_read_checked = {};

function manual_item_read(response) {
    var el = item_read(response);
    if ( el ) {
        el.remove();
    }
}

function item_read(response) {
    var data = response;
    if ( data.success == 1 ) {
        var item_id = '#item_' + data.id;
        var el = $(item_id);
        el.removeClass('unread');
        el.addClass('read');
        el.children('.unread_end').removeClass();
	is_read_checked[data.id] = 1;
        return el;
    }
}

function mark_as_read(e) {
    e.preventDefault();
    var el = $(e.srcElement);
    var item_id = el.parents('li.item').attr('id');
    item_id = item_id.replace('item_', '');
    $.post('/viewed', { id: item_id }, manual_item_read );
}

function toggle_fetch(e) {
    console.log(e);
    var t = $(e.target);
    var item_id = t.attr('id');
    item_id = item_id.replace('feed_', '');
    if ( t.hasClass('should_fetch') ) {
        $.post('/admin/fetch_off', { id: item_id }, function() { t.removeClass('should_fetch').addClass('nofetch'); } );
    } else {
        $.post('/admin/fetch_on', { id: item_id }, function() { t.removeClass('nofetch').addClass('should_fetch'); } );
    }
}

var observer = new IntersectionObserver(function(entries) {
	if(entries[0].isIntersecting === true)
    var el = entries[0].target;
    var item_id = el.id;
    item_id = item_id.replace('item_end_', '');
    if (!is_read_checked[item_id]) {
      $.post('/viewed', { id: item_id }, item_read );
    }
}, { threshold: [0] });


Zepto(function($) {
    observer.observe(document.querySelector(".unread_end"));
    $('.mark_as_read').on('click', mark_as_read);
    $('ul.feedlist li').on('click', toggle_fetch);
});
