Blacklight.onLoad(function() {
    var forms = $('.facet_search_form');
    forms.submit(function(event) {
        var field_name = $(event.target).children('.field-name').val();

        // Match ': (Value With Spaces and Other Chars)'
        var matchSearchValue = ':\\s*\\(([\\w\\s~`@#$%^&*-=+|\\[\\]{};\':",.<>\\/?]+)\\*\\)';
        var matchField = new RegExp(field_name + matchSearchValue);
        var matchAndThenField = new RegExp(' AND ' + field_name + matchSearchValue);
        var q = $(event.target).children('[name="q"]');
        var facet_search_value = $("#facet-search-" + field_name).val().trim();
        var facet_search_query = field_name + ': (' + facet_search_value + '*)';
        var replacement_value = "";

        if (!q.val() && !facet_search_value) {
            // No query and no new search so nothing to do.
            return;
        } else if (!q.val()) {
            // The query is empty so add this search as the only thing.
            q.val(facet_search_query);
        } else if (matchAndThenField.test(q.val())) {
            // There is a matching AND field search so replace it
            if (facet_search_value) {
                replacement_value = ' AND ' + facet_search_query;
            }
            q.val(q.val().replace(matchAndThenField, replacement_value));
        } else if (matchField.test(q.val())) {
            // There is a matching field search without an AND
            if (facet_search_value) {
                replacement_value = facet_search_query;
            }
            q.val(q.val().replace(matchField, replacement_value));
        } else {
            // We have no matching existing search so append this one.
            q.val(q.val() + ' AND ' + facet_search_query);
        }

    });

});
