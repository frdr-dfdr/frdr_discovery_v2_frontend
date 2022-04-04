//= require geoblacklight/viewers/wms
//= require leaflet


Blacklight.onLoad(function() {
  $('[data-map="item"]').each(function(i, element) {

    // get viewer module from protocol value and capitalize to match class name
    var viewerName = $(element).data().protocol,
      viewer;

    // get new viewer instance and pass in element
    viewer = new window['GeoBlacklight']['Viewer'][viewerName](element);
    var test_bounds = L.bboxToBounds("-180.0 -86.0 180.0 86.0");

    // set hover listeners on map
        $(".hover-display")
          .on('mouseenter', function() {
            text = $(this).attr("data_val");
            all = JSON.parse(text.replaceAll("=>",":"));
            var name = "hover-item"
            if(this.htmlFor.includes("bbox")){
                data = all["data"];
                north = parseFloat(data[0][0]);
                west = parseFloat(data[0][1]);
                south = parseFloat(data[1][0]);
                east = parseFloat(data[1][1]);
                var bounds = L.bboxToBounds(west + " " + south + " " + east + " " + north);
                viewer.addBoundsOverlaySingle(bounds,name)
            }else if(this.htmlFor.includes("point")){
                data = all["data"];
                data = data.replace("[","").replace("]","");
                var point = data.split(", ")
                viewer.addPointOverlay(point, name);
            }
          })
          .on('mouseleave', function() {
            var name = "hover-item"
            viewer.removeSingleBoundsOverlay(name);
          });
    /**
    *   Switch all the checkboxes under the Category checkbox to match the category checkbox when it is clicked
    */
    function swapCheckValue(group, checked){
        for(let i = 0; i< group.length; i++){
            item = group[i];
            item.checked = checked;
            if(item.attributes.name.nodeValue.includes("-all")){
                continue;
            }
            text = $(item).attr("data_val");
            all = JSON.parse(text.replaceAll("=>",":"));
            if(item.attributes.name.nodeValue.includes("bbox")){
                generateBBox(all,checked);
            }else if(item.attributes.name.nodeValue.includes("line")){
                generateLine(all,checked);
            }else if(item.attributes.name.nodeValue.includes("point")){
                generatePoint(all,checked);
            }else{
                generatePolygon(all,checked);
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
                text = $(this).attr("data_val");
                all = JSON.parse(text.replaceAll("=>",":"));
                name = all["checkboxes"];
                if ($(this).is(':checked')) {
                    if(!this.attributes.name.nodeValue.includes("-all")){
                        if(this.attributes.name.nodeValue.includes("bbox")){
                            generateBBox(all,true);
                        } else if(this.attributes.name.nodeValue.includes("point")){
                            generatePoint(all,true);
                        } else if(this.attributes.name.nodeValue.includes("line")){
                            generateLine(all,true);
                        } else{
                            generatePolygon(all,true);
                        }
                    }
                } else {
                    viewer.removeSingleBoundsOverlay(name);
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
    function addBBox(){
        swapCheckValue($('input[type="checkbox"]' + '.bbox'), true);
        //swapCheckValue($('input[type="checkbox"]' + '.line'), true);
        swapCheckValue($('input[type="checkbox"]' + '.point'), true);
        //swapCheckValue($('input[type="checkbox"]' + '.polygon'), true);
    }

    /**
    *  Create or remove bounding box overlay from map. Layer name is bbox name.
    */
    function generateBBox(all,checked){
        name = all["checkboxes"];
        data = all["data"];
        north = parseFloat(data[0][0]);
        west = parseFloat(data[0][1]);
        south = parseFloat(data[1][0]);
        east = parseFloat(data[1][1]);
        var bounds = L.bboxToBounds(west + " " + south + " " + east + " " + north);
        viewer.removeSingleBoundsOverlay(name);
        if(checked){
                viewer.addBoundsOverlaySingle(bounds, name);
            }
    }

    /**
    *  Create or remove a point overlay from map. Layer name is point name.
    */
    function generatePoint(all,checked){
        name = all["checkboxes"];
        data = all["data"];
        data = data.replace("[","").replace("]","");
        point = data.split(", ")
        viewer.removeSingleBoundsOverlay(name);
        if(checked){
            viewer.addPointOverlay(point,name);
        }
    }

    /**
    *  TODO Convert this dummy function to a real one when we start processing polylines
    */
    function generateLine(all,checked){
        name = all["checkboxes"];
        viewer.removeSingleBoundsOverlay(name);
        if(checked){
            viewer.addBoundsOverlaySingle(test_bounds, name);
        }
    }

    /**
    *  TODO Convert this dummy function to a real one when we start processing polygons
    */
    function generatePolygon(all,checked){
        name = all["checkboxes"];
        viewer.removeSingleBoundsOverlay(name);
        if(checked){
            viewer.addBoundsOverlaySingle(test_bounds, name);
        }
    }

    addBBox();
    addAllControl('#bbox-all', '.bbox');
    addAllControl('#line-all', '.line');
    addAllControl('#point-all', '.point');
    addAllControl('#polygon-all', '.polygon');

    $(".download-select").change( function(){
            var file = $(".download-select option:selected");
            var text = $(".download-select option:selected").text();
            var val = $(".download-select option:selected").val();
            addPreviewLayer(val);
          });

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
