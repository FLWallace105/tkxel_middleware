$(document).ready(function() {

});

function reset_form(){
    document.forms[0].reset();
}


$(function() {

    $( '.filter-btn' ).on( 'click', function() {
        if($(".filter-btn .drp-arrow-down").css('display') == 'none') {
            $(".drp-arrow-down").css('display','inline');
            $(".drp-arrow-up").css('display','none');
            count =2;
            return;

        }
        if($(".filter-btn .drp-arrow-down").css('display') == 'inline') {
            $(".drp-arrow-down").css('display','none');
            $(".drp-arrow-up").css('display','inline');
            count =2;
            return;
        }

    });
});
$(document).click(function(e) {
    // Check if click was triggered on or within #menu_content



        if($(".filter-btn .drp-arrow-down").css('display') == 'none') {
            $(".drp-arrow-down").css('display','inline');
            $(".drp-arrow-up").css('display','none');
            count=0;
            return;


    }

});
$( document ).ready(function() {
    if ($('table').attr('id') == 'table-timeline')
    {
        $(".time-line").css('height',document.getElementById('table-timeline').offsetHeight-5);
    }
    // $.notify({
    //     title: '<strong>Heads up!</strong>',
    //     message: 'You can use any of bootstraps other alert styles as well by default.'
    // },{
    //     type: 'danger'
    // });
    // $.notify({
    //     title: '<strong>Heads up!</strong>',
    //     message: 'You can use any of bootstraps other alert styles as well by default.'
    // },{
    //     type: 'success'
    // });
});


