$(function(){
  var oCheckAll=document.querySelector('.js-checkall');   //全选
  var aCheckParent=document.querySelectorAll('.js-checkparent');
  var aCheck=document.querySelectorAll('.js-check');          //checkbox按钮
  var oShopcount=document.getElementById('js-shopcount');
  var oShopPrice=document.getElementById('js-shopprice');
  var aTr=document.getElementsByClassName('js-tr');               //整行
  var oClearShopCar=document.getElementById('js-clearshopcar');       //清空按钮
  var oShopTr=document.getElementsByClassName('js-shoptr');         //整个购物车   清除的时候使用
  var aCheckone=document.getElementsByClassName('js-checkone');
  //清空购物车
  var $oShopTr2=$('.js-shoptr');
  $('#js-clearshopcar').click(function(){
    $oShopTr2.children().remove();
    fnGetEnd();
  })
  //如果没有选中，弹出提示
  var bEndPri=false;
  $('.js-checkout').click(function(event){
    for(var i=0;i<aCheck.length;i++){
      if(aCheck[i].checked){
        bEndPri=true;
      }
    }
    if($('#js-shopcount').text() === '0'){
      bEndPri = false;
    }
    if(!bEndPri){
      alert('请选择一个有效的商品');
      event.preventDefault();
      return false;
    }
  });
  //限购
  function getLimit(obj){
    var that = obj;
    var countInput = obj.querySelector('.js-length');
    var Val = countInput.value;
    if(that.querySelector('.js-shopId').getAttribute('data-shopEvents') == 'shop_products'){
        that.querySelector('.js-shopId').setAttribute('data-shopEvents','products')
      }
    if(that.querySelector('.js-shopId').getAttribute('data-shopEvents')== 'shop_events'){
      that.querySelector('.js-shopId').setAttribute('data-shopEvents','events');
    }
    $.ajax({
      url:'/shop/'+that.querySelector('.js-shopId').getAttribute('data-shopEvents')+'/'+that.querySelector('.js-shopId').value+'/cart_ticket_type',
      type:'get',
      dataType:'json',
      async:false,
      success:function(msg){
        MaxShopVal = msg.each_limit;
        MaxEventsVal = msg.surplus;
      }
    });
    if(MaxEventsVal >0){      //有剩余
      if(MaxEventsVal > MaxShopVal){   //剩余的比限制的大，留限制的
        if(Val > MaxShopVal){              //输入比限制的大，留限制的
          countInput.value = MaxShopVal;
        }else{                              //输入的比限制的小，留输入的
          countInput.value = Val;
        }
      }else{                              //剩余的比限制的小，留剩余的
        if(Val > MaxEventsVal){           //输入的比剩余的大，留剩余的
          countInput.value = MaxEventsVal;
        }else{                          //输入比剩余的小，留输入的
          countInput.value = Val;
        }
      }
    }else{                      //没有剩余
      countInput.value = 0;
      $(that).find('.js-shopminus').attr('disabled',true);
      $(that).find('.js-length').attr('disabled',true);
      $(that).find('.js-shopadd').attr('disabled',true);
      $(that).find('.js-checkone').attr('disabled',true);
      $(that).find('.js-checkone').attr('checked',false);
    }
    // if(MaxShopVal > MaxEventsVal){        //限购的比剩余的大， 留剩余
    //   if(Val > MaxEventsVal){             //输入比剩余的大  ，留剩余的
    //     countInput.value = MaxEventsVal;
    //   }else if(Val <= 0){
    //     countInput.value = 0;
    //     that.disabled = true;
    //   }else{
    //     countInput.value = Val;
    //   }
    // }else{                               //限购的比剩余的小， 留限购
    //   if(Val > MaxShopVal){
    //     countInput.value = MaxShopVal;
    //   }else if(Val <= 0){
    //     countInput.value = 0;
    //     that.disabled = true;
    //   }else{
    //     countInput.value = Val;
    //   }
    // }
    fnGetPrice(that);
  }
   //获取单行价格
  function fnGetPrice(aTr){
    var price=aTr.querySelector('.js-unitprice');//单价
    var relprice=aTr.querySelector('.js-realprice');//实价
    var countInput=aTr.querySelector('.js-length');//数目
    var endPrice = (parseInt(countInput.value)*parseFloat(price.innerHTML)).toFixed(2);
    if(isNaN(endPrice)){
      endPrice = 0.00;
    }
    relprice.innerHTML= endPrice;
  }
  //获取总价格
  function fnGetEnd(){
    var endCount=0;
    var endPrice=0;
    for(var i=0;i<aTr.length;i++){
      if(aTr[i].getElementsByTagName('input')[0].checked&&aTr[i].getElementsByTagName('input')[0].disabled === false){
        endCount+=parseInt(aTr[i].querySelector('.js-length').value);
        endPrice+=parseFloat(aTr[i].querySelector('.js-realprice').innerHTML);
      }
    }
    oShopcount.innerHTML=endCount;
    oShopPrice.innerHTML=endPrice.toFixed(2);
  }
  //点击时候判断反选的层级
  for(var i=0;i<aCheckone.length;i++){
    aCheckone[i].addEventListener('click',fnCheckBoolean,false);
  }
  //判断反选
  function fnCheckBoolean(){
    var oDataId=this.getAttribute('data-group');
    var aDataId=document.querySelectorAll('[data-group="'+oDataId+'"]');
    var oParDataId=document.querySelector('[data-group="'+oDataId+'"]');
    var aNewArray=[];
    var aDis = 1;
    for(var k=1;k<aDataId.length;k++){
      if(aDataId[k].checked){
        aNewArray.push(aDataId[k]);
      }
      if(aDataId[k].disabled){
        aDis += 1;
      }
    }
    if(aNewArray.length==(aDataId.length-aDis)){
      oParDataId.checked=true;
    }else{
      oParDataId.checked=false;
    }
  }
  for(var i=0;i<aCheck.length;i++){
    aCheck[i].onclick=function(){
      if(this.className.indexOf('js-checkall')>=0){
        for(var j=0;j<aCheck.length;j++){
          aCheck[j].checked=this.checked;
        }
      }
      if(this.className.indexOf('js-checkparent')>=0){
        for(var k=0;k<aCheck.length;k++){
          if(aCheck[k].getAttribute('data-group')==this.getAttribute('data-group')){
            aCheck[k].checked=this.checked;
          }
        }
      }
      // if(!this.checked){
      //   oCheckAll.checked=false;
      // }
      var aNewArray=[];
      var aDis = 0;
      for(var n=0;n<aCheck.length-1;n++){
        if(aCheck[n].disabled){
          aCheck[n].checked = false;
          aDis += 1;
        }
        if(aCheck[n].checked){
          aNewArray.push(aCheck[n]);
        }
      }
      if(aNewArray.length==(aCheck.length-aDis-1)){
        oCheckAll.checked=true;
      }else{
        oCheckAll.checked=false;
      }
      for(var j=0;j<aCheckone.length;j++){
        if(aCheckone[j].checked){
          var that = aCheckone[j].parentNode.parentNode;
          var MaxShopVal = parseInt(that.querySelector('.js-length').getAttribute('data-maxVal'));
          var MaxEventsVal = 99999999;
          getLimit(that);
          fnGetPrice(aCheckone[j].parentNode.parentNode);
        }
        fnGetEnd();
      };
    }
  }
  for(var i=0;i<aTr.length;i++){
    aTr[i].onclick=function(e){
      var e=e||window.event;
      var el=e.target||e.srcElement;
      var clas=el.className;
      var that = this;
      var MaxShopVal = parseInt(that.querySelector('.js-length').getAttribute('data-maxVal'));
      var MaxEventsVal = 99999999;
      getLimit(that);
      var countInput=that.querySelector('.js-length');
      var value=parseInt(countInput.value);
      if(clas.indexOf('js-shopminus')>=0){
        value--;
        if(value < 1){
          value = 1;
        }
        countInput.value = value;
        getLimit(that);
        fnGetPrice(this);
      }
      fnGetPrice(this);
      if(clas.indexOf('js-shopadd')>=0){
        value++;
        if(MaxShopVal > MaxEventsVal){        //货量少
          if(value > MaxEventsVal){
            countInput.value = MaxEventsVal;
          }else{
            countInput.value = value;
          }
        }else{                               //货量充足
          if(value > MaxShopVal){
            countInput.value = MaxShopVal;
          }else{
            countInput.value = value;
          }
        }
        getLimit(that);
        fnGetPrice(this);
      }
      var That = this;
      if(clas.indexOf('js-shopCarDelete')>=0){
        $("a[data-confirm]").on('confirm:complete', function (e, answer) {
          if (answer) {
            var strGroup=That.querySelector('[data-group]').getAttribute('data-group');
            if($('[data-group='+strGroup+']').length==2){
              $(That).prev().remove();
            }
            $(That).next().remove();
            $(That).remove();
          }
          fnGetEnd();
        });
      }
      countInput.setAttribute('value',countInput.value);
      fnGetEnd();
    };
    aTr[i].querySelector('.js-length').onkeyup=function(event){
      var val=parseInt(this.value);
      var that = this.parentNode.parentNode.parentNode;
      var MaxShopVal = parseInt(this.parentNode.parentNode.parentNode.querySelector('.js-length').getAttribute('data-maxVal'));
      var MaxEventsVal = 99999999;
      // if(isNaN(val) || val<=0 || val==''){
      //   this.value = 1;
      // }
      if(event.keyCode >=48 && event.keyCode <= 57){
        getLimit(that);
      }else{
        fnGetPrice(that);
        fnGetEnd();
      }
    };
    aTr[i].querySelector('.js-length').onblur = function(){
      var val=parseInt(this.value);
      var that = this.parentNode.parentNode.parentNode;
      var MaxShopVal = parseInt(this.parentNode.parentNode.parentNode.querySelector('.js-length').getAttribute('data-maxVal'));
      var MaxEventsVal = 99999999;
      if(isNaN(val) || val<=0 || val==''){
        this.value = 1;
      }
      getLimit(that);
      fnGetPrice(that);
      fnGetEnd();
    };
    fnGetPrice(aTr[i]);
    fnGetEnd();
  }
})
