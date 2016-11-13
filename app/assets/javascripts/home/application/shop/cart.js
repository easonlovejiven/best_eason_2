//应援
$(function(){
        ;(function(){
            function fnCarsBoolean(){
              var aCheckSecounds=document.querySelectorAll('.js-checksecound');
              var oRealPrice=document.querySelector('.js-eventprice');
              var aDanger=document.querySelectorAll('.js-infodanger');
              bInfo=true;
              if(aDanger){
                for(var d=0;d<aDanger.length;d++){
                  if(aDanger[d].value==''){
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
            $('.js-buyItem').click(function(){
              if(bClicked){
                alert("不要重复提交订单！");
                return false;
              };
              fnCarsBoolean();
              bClicked = true;
              tid = setTimeout("doit()", 10000);
              if(bCarsSecound&&bInfo){
                $("form[name='shop']").submit();
              }else{
                bClicked = false;
                alert("请选择价格或者填写附加信息");
                return false;
              };
            });
            $('.js-minusFundings').click(function(){
              var oInput = $('.js-valueFunding').val();
              oInput--;
              if(oInput<1){
                oInput =1;
              }
              $('input.js-valueFunding').val(oInput);
            })
            $('.js-addFunding').click(function(){
              var oInput=$('.js-valueFunding').val();
              oInput++;
              $('input.js-valueFunding').val(oInput);
            });
            //oid 某个分类下的类型    price 价格
            $('.js-showtypeFunding').on('click','.otag-type',function(){
              $('.js-showtypeFunding .otag-type').removeClass('selected');
              var $type=$(this);
              var $price=$('.js-showpriceFunding');
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
            $('.js-showpriceFunding').on('click','.otag-type',function(){
              $('.js-showpriceFunding .otag-type').removeClass('selected');
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
              oTicketSold.text(participator_json[oDataoId]);
              oPostPrice.val(oDataoId);
            })
            $('.js-valueFunding').change(function(){
              var oInput=$('.js-valueFunding').val();
              if(oInput < 1){
                oInput = 1;
              }
              $('.js-valueFunding').val(oInput);
            });
        })();
      })
