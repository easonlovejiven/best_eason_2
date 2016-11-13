//商品
function shopData(url){
  $.ajax({
    url:url,
    type:'get',
    dataType:'json',
    success:function(msg){
      json = msg.price_types;
      participator_json = msg.participators;
      max_participator_json = msg.max_participators;
      each_json = msg.each_limit;
      freights_json = msg.freights_json;
      surplusEvents = max_participator_json[oDataoIdWrap]-participator_json[oDataoIdWrap];
    }
  })
}
function shopEndVal(sClass){
  var oInput = $('.'+sClass).val();
  shopData(url);
  if(isNaN(surplusEvents)){
    return false;
  }
  if(surplusEvents > 0){                //有剩余商品
    if(max_participator_json[oDataoIdWrap]===99999999){           //商品不限
      if(each_json[oDataoIdWrap] === 99999999){               //个人不限
        if(oInput > surplusEvents){                       //输入比剩余大   留剩余
          $('.'+sClass).val(surplusEvents);
        }else if(oInput < 0){
          $('.'+sClass).val(0);
        }else{
          $('.'+sClass).val(oInput);
        }
      }else{                                            //个人限制
        if(surplusEvents > each_json[oDataoIdWrap]){          //剩余比个人限制大  留个人限制
          if(oInput > each_json[oDataoIdWrap]){                   //输入比个人限制大   留个人限制
            $('.'+sClass).val(each_json[oDataoIdWrap]);
          }else if(oInput < 0){
            $('.'+sClass).val(0);                              //输入比个人限制小   留输入
          }else{
            $('.'+sClass).val(oInput);
          }
        }else{                                                 //剩余比个人限制小   留剩余
          if(oInput>surplusEvents){                                 //输入的比剩余的大， 留剩余的
            $('.'+sClass).val(surplusEvents);
          }else if(oInput < 0){                                                    //输入的比剩余的小，留输入
            $('.'+sClass).val(0);
          }else{
            $('.'+sClass).val(oInput);
          }
        }
      }
    }else{                                                //商品限制
      if(each_json[oDataoIdWrap] === 99999999){               //个人不限
        if(surplusEvents > max_participator_json[oDataoIdWrap]){          //剩余的比商品限制的大 留商品限制
          if(oInput > surplusEvents){                                 //输入的比剩余的大.留剩余的
            $('.'+sClass).val(surplusEvents);
          }else if(oInput<0){                                                        //输入的比剩余的小，留输入的
            $('.'+sClass).val(0);
          }else{
            $('.'+sClass).val(oInput);
          }
        }else{                                                            //剩余的比商品限制的小，留剩余的
          if(oInput > surplusEvents){                                   //输入比剩余的大，留剩余的
            $('.'+sClass).val(surplusEvents);
          }else if(oInput < 0){                                                          //输入比剩余的小，留输入
            $('.'+sClass).val(0);
          }else{
            $('.'+sClass).val(oInput);
          }
        }
      }else{                                            //个人限制
        if(each_json[oDataoIdWrap]<max_participator_json[oDataoIdWrap]){             //个人限制比商品限制小，留个人限制
          if(surplusEvents > each_json[oDataoIdWrap]){                                 //商品剩余比个人限制大，留个人限制
            if(oInput > each_json[oDataoIdWrap]){                                 //输入比个人限制大，留个人限制
              $('.'+sClass).val(each_json[oDataoIdWrap]);
            }else if(oInput < 0){                                                                //输入比个人限制小，留输入
              $('.'+sClass).val(0);
            }else{
              $('.'+sClass).val(oInput);
            }
          }else{                                                                          //商品剩余比个人限制小，留商品剩余
            if(oInput > surplusEvents){                                             //个人输入比商品剩余大,留商品剩余
              $('.'+sClass).val(surplusEvents);
            }else if(oInput < 0){                                                                    //个人输入比商品剩余小，留个人
              $('.'+sClass).val(0);
            }else{
              $('.'+sClass).val(oInput);
            }
          }
        }else{                                                                      //个人限制比商品限制大，留商品限制
          if(surplusEvents > max_participator_json[oDataoIdWrap]){            //剩余的比商品限制的大，留商品限制
            if(oInput >max_participator_json[oDataoIdWrap]){                  //输入比商品限制大，留商品限制
              $('.'+sClass).val(max_participator_json[oDataoIdWrap]);
            }else if(oInput < 0){                                                          //输入比商品限制小，留输入
              $('.'+sClass).val(0);
            }else{
              $('.'+sClass).val(oInput);
            }
          }else{                                                                //剩余比商品小，留剩余
            if(oInput > surplusEvents){                                           //输入比剩余的大，留剩余
              $('.'+sClass).val(surplusEvents);
            }else if(oInput < 0){                                                                //输入的比剩余的小，留输入
              $('.'+sClass).val(0);
            }else{
              $('.'+sClass).val(oInput);
            }
          }
        }
      }
    }
    $('.js-minus,.js-add').attr('disabled',false);
  }else{                                //没有剩余的了
    $('.'+sClass).val(0);
    $('.js-minus,.js-add').attr('disabled',true);
  }
  // if(max_participator_json[oDataoIdWrap] == 99999999){  //商品不限
  //   if(each_json[oDataoIdWrap] == 99999999){    //个人不限制
  //     if(oInput > surplusEvents){         //输入比剩余的大
  //       if(surplusEvents <= 0){
  //         $('.'+sClass).val(0);
  //       }else{
  //         $('.'+sClass).val(surplusEvents);
  //       }
  //     }else{                                //输入比剩余的小
  //       $('.'+sClass).val(oInput);
  //     }
  //   }else{                                         //个人限制
  //     if(surplusEvents >0)
  //     if(oInput >= each_json[oDataoIdWrap]){      //输入比个人限制大
  //       $('.'+sClass).val(each_json[oDataoIdWrap]);
  //     }else if(oInput <= 0){
  //       $('.'+sClass).val(0);
  //     }else{
  //       $('.'+sClass).val(oInput);
  //     }
  //   }
  // }else{       //商品限制
  //   if(each_json[oDataoIdWrap] < surplusEvents ){   //商品剩余比个人限制多
  //     if(oInput >= each_json[oDataoIdWrap]){
  //       $('.'+sClass).val(each_json[oDataoIdWrap]);
  //     }else if(oInput <= 0){
  //       $('.'+sClass).val(0);
  //     }else{
  //       $('.'+sClass).val(oInput);
  //     }
  //   }else{
  //     if(oInput >= surplusEvents){
  //       $('.'+sClass).val(surplusEvents);
  //     }else if(oInput <= 0){
  //       $('.'+sClass).val(0);
  //     }else{
  //       $('.'+sClass).val(oInput);
  //     }
  //   }
  // }
}
$(function(){
  ;(function(){
      function fnCarsBoolean(){
        var aCheckSecounds=document.querySelectorAll('.js-checksecound');
        var oRealPrice=document.querySelector('.js-eventprice');
        var aDanger=document.querySelectorAll('.js-infodanger');
        bInfo=true;
        if(aDanger){
          for(var d=0;d<aDanger.length;d++){
            if(aDanger[d].value.trim()==''){
              bInfo=false;
            }
          }
        }
        for(var n=0;n<aCheckSecounds.length;n++){
          if(aCheckSecounds[n].className.indexOf('selected')>=0){
            if(aCheckSecounds[n].getAttribute('data-price')==oRealPrice.innerHTML){
              bCarsSecound=true;
            }
          }
        }
      }
      $('#buy-item').click(function(){
        shopData(url);
        var diffV = surplusEvents-$('input.js-value').val();
        if(diffV < 0 ){
          alert('库存不足');
          return false;
        }
        if($('input.js-value').val() === '0'){
          alert('请添加数量');
          return false;
        }
        if(bClicked){
          alert("不要重复提交订单！");
          return false;
        }
        fnCarsBoolean();
        bClicked = true;
        tid = setTimeout("doit()", 10000);
        //$('#myModal').modal('hide')
        if($('#welfare-open').length){
          var price = $('.js-eventprice').text();
          var olength = $('.js-value').val();
          var welfare_o = (price*olength).toFixed(1);
          $('.js_welfare_price').text(welfare_o);
          if(bCarsSecound&&bInfo){
            bClicked = false;
            $('#welfare-open').modal('show');
          }else{
            bClicked = false;
            alert("请选择价格或者填写附加信息");
            return false;
          }
        }else{
          if(bCarsSecound&&bInfo){
            $("form[name='shop']").submit();
          }else{
            bClicked = false;
            alert("请选择价格或者填写附加信息");
            return false;
          }
        }
      });
      $('.js_welfare_open').click(function(){
        $(this).prop('disabled',true);
        $("form[name='shop']").submit();
      });
      $("#add-cart").click(function(){
        shopData(url);
        var diffV = surplusEvents-$('input.js-value').val();
        if(diffV < 0){
          alert('库存不足');
          return false;
        }
        if($('input.js-value').val() === '0'){
          alert('请添加数量');
          return false;
        }
        fnCarsBoolean();
        var shop_task_id = $("input[name='shop_task_id']").val();
        if(bCarsSecound&&bInfo){
          $.ajax({
            url: "/shop/carts/add.json",
            type: "post",
            data: $("form[name='shop']").serialize()+"&commit=add_cart"+"&shop_task_id="+shop_task_id,
            context: $(this),
            success: function(data){
              if(data.error){
                alert(data.error);
              }else{
                alert("已经将您的商品成功加入购物车！");
              }
            },
            error: function(){
              alert("处理失败！");
            }
          });
        }else{
          alert("请选择价格或者填写附加信息");
        }
      });
      $('.js-minus').click(function(){
        var oInput = $('.js-value').val();
        oInput--;
        if(oInput < 0){
          oInput = 0;
        }
        $('.js-value').val(oInput);
        shopEndVal('js-value');
      })
      $('.js-add').click(function(){
        var oInput=$('.js-value').val();
        oInput++;
        $('.js-value').val(oInput);
        shopEndVal('js-value');
      });
      $('.js-city').on('click',function(){
        var str=$(this).text();
        $('.js-changecity').text(str);
        $(this).addClass('selected').siblings().removeClass('selected');
      })
      $('.js-saveCity').click(function(){
        var str=$('.js-changecity').text();
        $('.js-citytext').text(str);
        var strPrice='¥'+freights_json[str];
        $('.js-cityPrice').text(strPrice);
      })
      //oid 某个分类下的类型    price 价格
      $('.js-showtype').on('click','.otag-type',function(){
        $('.js-showtype .otag-type').removeClass('selected');
        var $type=$(this);
        var $price=$('.js-showprice');
        $type.toggleClass('selected');
        var oId = $type.data('id');
        $price.find('.otag-type').remove();
        for(var i in json[oId]){
            var otag = ' <li class="otag-type js-checksecound" data-price="'+json[oId][i][1]+'" data-oid="'+i+'">'+
                    '<label for="data-1" class="task-label">'+
                        json[oId][i][0]+
                    '</label>'+
                    '<span class="otag-state"></span>'+
                  '</li>'
            $price.append(otag);
        }
      })
      $('.js-showprice').on('click','.otag-type',function(){
        $('.js-value').val('1');
        shopData(url);
        $('.js-showprice .otag-type').removeClass('selected');
        var $type=$(this);
        $type.toggleClass('selected');
        var oDataoId=$type.data('oid');    //odataoId   某个分类下的类型
        oDataoIdWrap = oDataoId;            //别的地方的调用
        var oTicketSold=$('.ticket-sold');   //已参与的人数
        var oTicketTotal=$('.ticket-total'); //总人数
        var oDataPrice=$type.data('price');   //价格
        var oPrice=$('.js-eventprice');       //价格容器
        var oPostPrice=$('.js-posteventprice');   //商品容器第几个商品
        oPrice.text(oDataPrice);
        surplusEvents = max_participator_json[oDataoIdWrap]-participator_json[oDataoIdWrap]; //剩余商品
        oTicketSold.text(participator_json[oDataoId]);  //已参与人数
        if($('#welfare-open').length){
          if(max_participator_json[oDataoId] == 99999999 ){
            oTicketTotal.text('不限');
          }else{
            oTicketTotal.text(max_participator_json[oDataoId]);
          };
        }else{
          if(max_participator_json[oDataoId] == 99999999 ){
            $('.js_limt_surplus').css('display','none');
          }else{
            $('.js_limt_text').text('该款价格商品剩余 '+surplusEvents+' 个');
            $('.js_limt_surplus').css('display','block');
          };
        }
        if($('#welfare-open').length){
          if(participator_json[oDataoId] >= max_participator_json[oDataoId]){
            $('#add-cart').attr('disabled',true);
            $('#buy-item').attr('disabled',true);
            // $('#add-cart').css('display','none');
            $('#buy-item').html('福利已抢空');
          }else{
            $('#add-cart').removeAttr('disabled');
            $('#buy-item').removeAttr('disabled');
            // $('#add-cart').css('display','inline-block');
            $('#buy-item').html('立即兑换');
          }
        }
        var oInput=$('.js-value').val();
        $('.js-value').val(oInput);
        shopEndVal('js-value');
        oPostPrice.val(oDataoId);
      })
      $('.js-value').keyup(function(){
        var oInput=parseInt($('.js-value').val());
        // if(isNaN(oInput) || oInput<=0 || oInput==''){
        //   oInput = 1;
        // }
        if(event.keyCode >=48 && event.keyCode <= 57){
          $('.js-value').val(oInput);
          shopEndVal('js-value');
        }
        // $('.js-value').val(oInput);
        // shopEndVal('js-value');
      });
      $('.js-value').blur(function(){
        var oInput=parseInt($('.js-value').val());
        if(isNaN(oInput) || oInput<=0 || oInput==''){
          oInput = 1;
        }
        // if(event.keyCode >=48 && event.keyCode <= 57){
        //   $('.js-value').val(oInput);
        //   shopEndVal('js-value');
        // }
        $('.js-value').val(oInput);
        shopEndVal('js-value');
      });
  })();
})
