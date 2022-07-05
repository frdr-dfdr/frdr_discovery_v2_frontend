Blacklight.onLoad(function() {

    var form = $('#filter-date');
    form.submit(function(event) {
        var from = $('#date_from').val();
        var to = $('#date_to').val();
        var filter = $("#f_dct_issued_s_");
        filter.val(from + "to" + to);
    });

});
