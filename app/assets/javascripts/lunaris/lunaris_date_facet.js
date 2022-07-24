//= require bootstrap-datepicker.min.js
//= require bootstrap-datepicker-en-CA.min.js
//= require bootstrap-datepicker.fr.min.js

Blacklight.onLoad(function() {
    var lang = "en_CA";
    if (window.location.pathname.endsWith('/fr'))
    {
        lang = "fr";
    }
    var datePickerOpts = {
        autoclose: true,
        clearBtn: true,
        format: 'yyyy-mm-dd',
        immediateUpdates: true,
        language: lang,
        todayBtn: true
    };

    $('#date_from').datepicker(datePickerOpts);

    $('#date_to').datepicker(datePickerOpts);

    var form = $('#filter-date');
    form.submit(function(event) {
        var from = $('#date_from').val();
        var to = $('#date_to').val();
        var filter = $("#f_dct_issued_s_");
        filter.val(from + "to" + to);
    });

});
