Blacklight.onLoad(function() {
  $('[data-map="item"]').each(function(i, element) {

    // get viewer module from protocol value and capitalize to match class name
    var viewerName = $(element).data().protocol,
      viewer;

    // get new viewer instance and pass in element
    viewer = new window['GeoBlacklight']['Viewer'][viewerName](element);
    var bounds_old = L.bboxToBounds("-180.0 -86.0 180.0 86.0");

    /**
    *   Switch all the checkboxes under the Category checkbox to whatever the category checkbox is
    */
    function swapCheckValue(group, checked){
        for(let i = 0; i< group.length; i++){
            item = group[i];
            item.checked = checked;
            ruby_data = $(item).attr("data_val");
            text = ruby_data;
            name = text.substring(text.indexOf("checkboxes")+14, text.indexOf("\"}"));
            north = parseFloat(text.substring(text.indexOf("data\"=>[[\"")+10,text.indexOf("\", \"")));
            result = text.substring(text.indexOf("\", \"")+4);
            text = text.substring(text.indexOf("\", \"")+4);
            west = parseFloat(text.substring(0,text.indexOf("\"]")));
            text = text.substring(text.indexOf("\"], [\"")+6);
            south = parseFloat(text.substring(0,text.indexOf("\", \"")));
            text = text.substring(text.indexOf("\", \"")+4);
            east = parseFloat(text.substring(0,text.indexOf("\"]")));
            var bounds = L.bboxToBounds(north + " " + west + " " + south + " " + east);
            if(checked){
                if(!item.attributes.name.nodeValue.includes("-all")){
                    viewer.removeSingleBoundsOverlay(name);
                    viewer.addBoundsOverlaySingle(bounds, name);
                }
            }else{
                 viewer.removeSingleBoundsOverlay(name);
             }
        }
    }

    /**
     * Add behaviour for all checkbox that can select / deselect all fo the checkboxes
     * of a type and gets unchecked if one of the sub checkboxes gets unchecked.
     */
    function addAllControl(allIdSelector, itemClassSelector) {

        $(allIdSelector).click(function() {
            if ($(this).is(':checked')) {
                swapCheckValue($('input[type="checkbox"]' + itemClassSelector), true);
            } else {
                swapCheckValue($('input[type="checkbox"]' + itemClassSelector), false);
            }
        });
        $("input[type='checkbox']").on("change",function(){
                if ($(this).is(':checked')) {
                    if(!this.attributes.name.nodeValue.includes("-all")){
                        viewer.removeSingleBoundsOverlay(this.attributes.name.nodeValue);
                        viewer.addBoundsOverlaySingle(bounds_old, this.attributes.name.nodeValue);
                    }
                } else {
                                    viewer.removeSingleBoundsOverlay(this.attributes.name.nodeValue);
                }
        });
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
                viewer.removeSingleBoundsOverlay(this.attributes.name.nodeValue);
            }
            else {
                $(allIdSelector)[0].indeterminate = true;
            }
        });
    }
    function addBBox(){
        swapCheckValue($('input[type="checkbox"]' + '.bbox'), true);
        //swapCheckValue($('input[type="checkbox"]' + '.line'), true);
        //swapCheckValue($('input[type="checkbox"]' + '.point'), true);
        //swapCheckValue($('input[type="checkbox"]' + '.polygon'), true);
    }

    addBBox();
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
