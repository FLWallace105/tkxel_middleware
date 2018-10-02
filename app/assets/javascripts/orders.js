$( document ).on('turbolinks:load', function() {
   $(function() {
       $('.datetimepicker').datetimepicker({
                format: 'MM/DD/YYYY'
       });
   });

    $('#sel1').change(function(){
            $(this).parent().submit();
        });
    $('#all-li').click(function(){
        localStorage.setItem("active_order_tab", "all");
    });

    $('#failure-li').click(function(){
        localStorage.setItem("active_order_tab", "failures");
    });

    if (localStorage.getItem("active_order_tab") == 'failures')
    {
        $('#failure-li a').click()
    }else
    {
        $('#all-li a').click()
    }
}

    );
