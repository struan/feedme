function item_read(response) {
    if ( response.success) {
        var item_id = '#item_' . response.id;
        var el = $(item_id);
        el.removeClass('read');
        el.addClass('unread');
        el.children('.unread_end').removeClass('unread_end');
    }
}

function check_for_read() {
    var viewHeight = $(window).height();
    var screenTop = $('body').scrollTop();
    var screenBottom = viewHeight + screenTop;

    $('.unread_end').each( function() {
        var el = $(this);
        if ( el.offset().top < screenBottom ) {
            var item_id = el.parent().attr('id');
            item_id = item_id.replace('item_', '');
            $.post('/viewed', { id: item_id }, item_read );
        }
    });
}

Zepto(function($) {
    $(document).on('scroll', check_for_read );
    $('li.item');
});
