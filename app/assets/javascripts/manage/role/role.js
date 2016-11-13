
$(document).ready(function(){
  var initDom = function() {
    $("label[for=\"manage_role_name\"]").attr("class", "col-md-1 control-label")
    $("label[for=\"manage_role_description\"]").attr("class", "col-md-1 control-label")
    
    if ( /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent) ) {
      // do something... 
    } else {
      $("#margin-left-text").height( $("#main-select").height()+50 )
    }
  }()

  var getRowValueByField = function(field){
    // console.log("field = "+field)
    var $rowDoms = $(".checkbox[action="+field+"]")
    var rowVal = 0
    $rowDoms.each(function(){
      rowVal += (this.checked == true ? parseInt($(this).val()) : 0)
    })
    // console.log("rowVal = "+rowVal)
    return rowVal
  }

  var updateDomNumsValueByField = function(field,value){
    $("#"+field+"_num").val(parseInt(value))
  }

  var refreshCol = function(){
    $(".col.checkbox").each(function(k,v){
      var val = Math.pow(2,k)
      var $colDoms = $(".checkbox[value="+val+"]")
      var colChecked = true
      $colDoms.each(function(){
        if (this.checked == false) {
          colChecked = false
          return false
        }
      })
      this.checked = colChecked
    }); 
  }

  var refreshRow = function(){
    $(".row.checkbox").each(function(){
      var field = $(this).attr("data-name")
      var rowVal = getRowValueByField(field)
      this.checked = (rowVal == 127 ? true : false)
      $(this).on("click", function(){
        var field = $(this).attr("data-name")
        var $rowDoms = $(".checkbox[action="+field+"]")
        var checked = this.checked    
        $rowDoms.each(function(){
          this.checked = checked
        })
        var rowVal = getRowValueByField(field)
        updateDomNumsValueByField(field, rowVal)
      })      
    })
  }

  var refreshAll = function(){
    $("#colall").each(function(){
      var allChecked = true
      var $allDoms = $(".checkbox").not("#colall")
      $allDoms.each(function(){
        if (this.checked == false) {
          allChecked = false
          return false
        }     
      })
      this.checked = allChecked   
    })
  }

  refreshCol()
  refreshRow()
  refreshAll()

  $(".col.checkbox").each(function(k,v){
    var val = Math.pow(2,k)
    var $colDoms = $(".checkbox[value="+val+"]")
    $(this).on("click", function(){
      var checked = this.checked
      $colDoms.each(function(){
        this.checked = checked
        var field = $(this).attr("action")
        var rowVal = getRowValueByField(field)
        updateDomNumsValueByField(field, rowVal)
      })
      refreshRow()
      refreshAll()    
    });
  });

  $(".row.checkbox").each(function(){
    $(this).on("click", function(){
      var field = $(this).attr("data-name")
      var $rowDoms = $(".checkbox[action="+field+"]")
      var checked = this.checked    
      $rowDoms.each(function(){
        this.checked = checked
      })
      var rowVal = getRowValueByField(field)
      updateDomNumsValueByField(field, rowVal)
      refreshCol()
      refreshAll()
    });     
  })

  $("#colall").click(function(){  
    var checked = this.checked
    var $allDoms = $(".checkbox").not("#colall")
    $allDoms.each(function(){
      this.checked = checked
    })
    $(".row.checkbox").each(function(){
      var field = $(this).attr("data-name")
      var rowVal = getRowValueByField(field)
      updateDomNumsValueByField(field, rowVal)
    })
  })

  $(".checkbox").not(".row.checkbox").not(".col.checkbox").not("#colall").each(function(){
    $(this).on('click',function(){
      var field = $(this).attr("action")
      var rowVal = getRowValueByField(field)
      updateDomNumsValueByField(field, rowVal)
    })
  })

})
