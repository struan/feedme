function item_read(response) {
    var data = $.parseJSON( response );
    if ( data.success == 1 ) {
        var item_id = '#item_' + data.id;
        var el = $(item_id);
        el.removeClass('unread');
        el.addClass('read');
        el.children('.unread_end').removeClass();
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

Zepto(function($) {
    $(document).on('scroll', check_for_read );
    $('li.item');
});
