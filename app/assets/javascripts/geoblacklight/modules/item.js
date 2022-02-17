Blacklight.onLoad(function() {
  $('[data-map="item"]').each(function(i, element) {

    // get viewer module from protocol value and capitalize to match class name
    var viewerName = $(element).data().protocol,
      viewer;

    // get new viewer instance and pass in element
    viewer = new window['GeoBlacklight']['Viewer'][viewerName](element);

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
        $("input[type='checkbox']").on("change",function()){
                if ($(this).is(':checked')) {
                    var bounds = L.bboxToBounds("-180.0 -86.0 180.0 86.0");
                                    viewer.addBoundsOverlay(bounds);
                } else {
                    var bounds = L.bboxToBounds("-180.0 -86.0 180.0 86.0");
                                    viewer.map.removeLayer(bounds);
                }
        }
        $('input[type="checkbox"]' + itemClassSelector).change(function() {
            var allInputs = $('input[type="checkbox"]' + itemClassSelector);
            if(allInputs.length == allInputs.filter(":checked").length) {
                $(allIdSelector).prop('checked', true);
                $(allIdSelector)[0].indeterminate = false;

                //var bounds = L.bboxToBounds("-180.0 -86.0 180.0 86.0");
                //viewer.addBoundsOverlay(bounds);
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

  $('.truncate-abstract').each(function(i, element) {
      
    var lines = 12 * parseFloat(getComputedStyle(element).fontSize);
    if (element.getBoundingClientRect().height < lines) return;
    var id = element.id || 'truncate-' + i;

    element.id = id;
    $(element).addClass('collapse');

    var control = $('<button class="btn btn-link p-0 border-0 read_more" data-toggle="collapse" aria-expanded="false" data-target="#' + id + '" aria-controls="' + id + '">'+I18n.t('item.read_more')+'</button>');

    $(element).on('shown.bs.collapse', function() {
      control.text(I18n.t('item.close'));
    });
    $(element).on('hidden.bs.collapse', function() {
      control.text(I18n.t('item.read_more'));
    });

    control.collapse();
    control.insertAfter(element);
  });

});
