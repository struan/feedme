function manual_item_read(response) {
    var el = item_read(response);
    if ( el ) {
        el.remove();
    }
}

function item_read(response) {
    var data = $.parseJSON( response );
    if ( data.success == 1 ) {
        var item_id = '#item_' + data.id;
        var el = $(item_id);
        el.removeClass('unread');
        el.addClass('read');
        el.children('.unread_end').removeClass();
        return el;
    }
}

function check_for_read() {
    var viewHeight = $(window).height();
    var screenTop = $('body').scrollTop();
    var screenBottom = viewHeight + screenTop;

    $('.unread_end').each( function() {
        var el = $(this);
        if ( el.offset().top < screenBottom ) {
            var item_id = el.attr('id');
            item_id = item_id.replace('item_end_', '');
            $.post('/viewed', { id: item_id }, item_read );
        }
    });
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

Zepto(function($) {
    $(document).on('scroll', check_for_read );
    $('.mark_as_read').on('click', mark_as_read);
    $('ul.feedlist li').on('click', toggle_fetch);
    $('li.item');
});
