Blacklight.onLoad(function() {

    /**
     * Add behaviour for all checkbox that can select / deselect all fo the checkboxes
     * of a type and gets unchecked if one of the sub checkboxes gets unchecked.
     */
    function addAllControl(allIdSelector, itemClassSelector) {
        $(allIdSelector).click(function() {
            if ($(this).is(':checked')) {
                $('input[type="checkbox"]' + itemClassSelector).prop('checked', true);
            } else {
                $('input[type="checkbox"]' + itemClassSelector).prop('checked', false);
            }
        });

        $('input[type="checkbox"]' + itemClassSelector).change(function() {
            var allInputs = $('input[type="checkbox"]' + itemClassSelector);
            if(allInputs.length == allInputs.filter(":checked").length) {
                $(allIdSelector).prop('checked', true);
                $(allIdSelector)[0].indeterminate = false;
            }
            else if(allInputs.filter(":checked").length == 0) {
                $(allIdSelector).prop('checked', false);
                $(allIdSelector)[0].indeterminate = false;
            }
            else {
                $(allIdSelector)[0].indeterminate = true;
            }
        });
    }

    addAllControl('#bbox-all', '.bbox');
    addAllControl('#line-all', '.line');
    addAllControl('#point-all', '.point');
    addAllControl('#polygon-all', '.polygon');

});
