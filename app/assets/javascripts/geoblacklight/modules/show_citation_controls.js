Blacklight.onLoad(function() {

    $('#copy-citation-button').click(function() {
        navigator.clipboard.writeText($("#apa-citation").text().trim()).then(function() {
            $("#apa-citation-copied").show().fadeOut(2800);
        }, function() {
            $("#apa-citation-failed").show().fadeOut(2800);
        });
    });

});
