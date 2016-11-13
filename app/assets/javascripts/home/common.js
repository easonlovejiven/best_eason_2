$(function () {
  // 活动开始和结束时间
  function dateInterval(dateStart, dateEnd){
    $(dateStart).datetimepicker({
      format: 'YYYY-MM-DD HH:mm',
      useCurrent: false //Important! See issue #1075
    });
    $(dateEnd).datetimepicker({
      format: 'YYYY-MM-DD HH:mm',
      useCurrent: false //Important! See issue #1075
    });
    $(dateStart).on("dp.change", function (e) {
      $(dateEnd).data("DateTimePicker").minDate(e.date);
    });
    $(dateEnd).on("dp.change", function (e) {
      $(dateStart).data("DateTimePicker").maxDate(e.date);
    });
  };
  dateInterval('#eventDateStart', '#eventDateEnd');
  dateInterval('#sellDateStart', '#sellDateEnd');

  function dataStart(cls) {
    $(cls).datetimepicker({
      format: 'YYYY-MM-DD HH:mm',
      useCurrent: false
    });
  };
  //危险字符替换
  function isDangerVal(str,options){
    var oDanger = str;
    options.ill = options.ill || '';
    options.chara = options.chara || '';
    var oRegExp = new RegExp(options.ill+options.chara,'g');
    oDanger = oDanger.replace(oRegExp,'');
    return oDanger;
  }
  if($('.js_danger_chara').length){
    $(document).on('change','.js_danger_chara',function(e){
      var str = $(this).val();
      str = isDangerVal(isDangerVal(str,{'ill':'集资','chara':'|(^(\\s*))'}),{'ill':'集资','chara':'|(^(\\s*))'});
      $(this).val(str);
    });
  }
  if($('.js_danger_val').length){
    $(document).on('change','.js_danger_val',function(e){
      var str = $(this).val();
      str = isDangerVal(str,{'ill':'集资'});
      $(this).val(str);
    });
  }
  //浏览器记住密码之后密码多次显示的问题
  $(window).load(function(){
    if($('.js_pass_val').length){
      if($('.js_pass_val').val()!==''){
        $('.js_pass_val').val('');
      }
    }
  });
  $('.js_tip_yes').click(function(){
    var str = window.location.host+'/home/users/edit';
    window.location.href='http://'+str;
  });
  $('.js_tip_no').click(function(){
    var str = window.location.host;
    window.location.href = 'http://'+str;
  });
  //搜索为空不能搜索
  if($('.js_search_val').length){
    $('.js_search_val').each(function(index){
      var searchVal = $(this).val().trim();
      if(searchVal === ''){
        $($('.js_search_btn')[index]).attr('disabled',true);
      }
      $(this).change(function(){
        var searchVal = $(this).val().trim();
        if(searchVal === ''){
          $($('.js_search_btn')[index]).attr('disabled',true);
        }else{
          $(this).val(searchVal);
          $($('.js_search_btn')[index]).attr('disabled',false);
        }
      });
    });
  }
  if ($('.getStart').length) {
    dataStart('.getStart');
  }
  //评论框，如果回复为空的话，不让点击发表
  if($('.js-topicTextarea').length){
    if($('.js-topicTextarea').val() == ''){
      $('.dynamic-publish').attr('disabled', true);
    }
    $('.js-topicTextarea').keyup(function(){
      if($('.js-topicTextarea').val().trim() == ''){
        $('.dynamic-publish').attr('disabled', true);
      }else{
        $('.dynamic-publish').attr('disabled', false);
      }
    });
    //解决按下不放的情况
    $('.js-topicTextarea').keydown(function(){
      if($('.js-topicTextarea').val().trim() == ''){
        $('.dynamic-publish').attr('disabled', true);
      }else{
        $('.dynamic-publish').attr('disabled', false);
      }
    });
  }
  // 是否需要设置快递信息-显示隐藏快递信息
  function showDeliveryTemp(id, ele){
    var deliveryInputChecked = $(id +':checked').data('val');
    if (deliveryInputChecked == '1') {
      $(ele).removeClass('hide');
    }else{
      $(ele).addClass('hide');
    }
  }
  if ($('#express-delivery-yes').length) {
    showDeliveryTemp("#express-delivery-yes", ".express-delivery");
  }
  $('.delivery-radios').on('change', 'input', function(){
    showDeliveryTemp("#express-delivery-yes", ".express-delivery");
  });

  // 免费活动不需要添加现价
  // if ($('.js-isFree')) {
  //   isFree();
  // }
  $('.js-isFree').on('change', function(){
    isFree()
  });
  $('.js-price-infos').on('cocoon:before-insert cocoon:after-insert', function(e, insertedItem) {
     isFree()
  });

  // 直播--图文&视频
  if ($('#video-yes').length) {
    showDeliveryTemp("#video-yes", ".sebject-options");
  }
  $('.subjects-radios').on('change', 'input', function(){
    showDeliveryTemp("#video-yes", ".sebject-options");
  });

  // 锚点定位
  $('[data-anchor="anchor-location"]').click(function(){
    // console.log($(this));
    var anchor = $(this).data('anchor-target');
    var top = $(anchor).offset().top;
    return document.documentElement.scrollTop = document.body.scrollTop = top - 109;
  });
  $('.input_number').keydown(function(event){
    if(!(event.keyCode>=48&&event.keyCode<=57||event.keyCode == 8 || event.keyCode>=96&&event.keyCode<=105)){
      return false;
    }
  });

  // 评论回复
  $('.comments-list').on('click', '.js-reply-show', function(){
    var $targetReplyShow = $(this).parents('[data-replay="replayBox"]').find('.reply-show');
    var flag = $targetReplyShow.hasClass('on');
    if (!flag) {
      $('.reply-show').slideUp().removeClass('on');
      $targetReplyShow.slideDown().addClass('on');
    };
    // console.log($targetReplyShow);
  });

  //回复的回复
  $('.js_dynamic_again').click(function(event){
    if($(this).parent().parent().find('.js_dynamic_text').val().trim() == ''){
      alert('内容不能为空');
      event.preventDefault();
      $('.js_dynamic_text').val('');
    }
  });
  //话题和投票切换
  $('.js_showArea').click(function(){
    $(this).addClass('text-hover');
    $('.js_showVote').removeClass('text-hover');
    $('.js_showArea_box').css('display','block');
    $('.js_showVote_box').css('display','none');
  });

  $('.js_showVote').click(function(){
    $(this).addClass('text-hover');
    $('.js_showArea').removeClass('text-hover','block');
    $('.js_showArea_box').css('display','none');
    $('.js_showVote_box').css('display','block');
  });
  function voteLength(){
    return $('.js_showVote_box').find('.js_vote_text').length;
  }
  $('.js_voteText_add').click(function(){
    var nVote = $('.js_showVote_box').find('.js_vote_text').length;
    var str = '<div class="form-group">'+
                '<div class="input-group">'+
                  '<input type="text" class="form-control js_vote_text" placeholder="选项:必填,10字以内" maxlength="10"/>'+
                  '<div class="input-group-btn js_voteText_delete">'+
                    '<a class="btn btn-default"><span class="text-highlight-r">删除</span></a>'+
                  '</div>'+
                '</div>'+
                '<p class="hide error">需填写</p>'+
              '</div>';
    $('.js_voteText_delete').each(function(){
      $(this).removeClass('box-hiden');
    });
    if(nVote == 9){
      $('.js_voteText_add').addClass('box-hiden');
    }
    $('.js_voteText_box').append(str);
  });

  $('.js_voteText_box').on('click','.js_voteText_delete',function(){
    var nVote = $('.js_voteText_box').find('.js_vote_text').length;
    if(nVote == 3){
      $('.js_voteText_delete').each(function(){
        $(this).addClass('box-hiden');
      });
    }
    $('.js_voteText_add').removeClass('box-hiden');
    $(this).closest('.form-group').remove();
  });
  //传说中的倒计时
  function tickSeconds(oClass,s){
      var oVal=document.querySelector('.'+oClass+'');
      timer=setInterval(function(){
        s--;
        if(s<=0){
          clearInterval(timer);
          window.location.href='/';
        }else{
          oVal.innerHTML = s;
        }
      },1000);
  }
  //图片大小验证
  $('.js_describe_img').change(function(){
    filefujianChange(this,10);
  });
  function filefujianChange(target,count) {
   var fileSize = 0;
   var isIE = /msie/i.test(navigator.userAgent) && !window.opera;
   if (isIE && !target.files) {
     var filePath = target.value;
     var fileSystem = new ActiveXObject("Scripting.FileSystemObject");
     var file = fileSystem.GetFile (filePath);
     fileSize = file.Size;
   } else {
    fileSize = target.files[0].size;
    }
    var size = fileSize / 1024 /1000;
    if(size>count){
     alert("图片必须小于"+count+"M");
     target.value="";
     return
    }
    var name=target.value;
    var fileName = name.substring(name.lastIndexOf(".")+1).toLowerCase();
    if(fileName !="jpg" && fileName !="jpeg" && fileName !="png" && fileName !="gif" ){
      alert("格式需是jpg/jpeg/gif/png");
        target.value="";
        return
    }
  }
  //检查问答的正确性
  function checkqa(obj){
    var str=$(obj).attr('data-id');
    var request=$.ajax({
      url:'/',
      type:"PUT",
      data:{id:str}
    });
    request.done(function(msg){
      if(str==msg){
        obj.css('color','red');
      }
      obj.parents('.js-questionpa').find('.js-question').each(function(){
        if($(this).attr('data-id')==msg){
          $(this).css('color','blue');
        }
        $(this).attr('disabled','true');
      });
    });
  }
  // $('.js-question').on('click',function(){
  //   var _this=this;
  //   checkqa(_this);
  // });
  //直播倒计时
  //2014/09/20 00:00:00
  function GetRTime(time){
      var EndTime= new Date(time);
      var NowTime = new Date();
      var t =EndTime.getTime() - NowTime.getTime();
      var d=0;
      var h=0;
      var m=0;
      var s=0;
      if(t>0){
        d=toDou(parseInt(t/1000/60/60/24,10));
        h=toDou(parseInt(t/1000/60/60%24,10));
        m=toDou(parseInt(t/1000/60%60,10));
        s=toDou(parseInt(t/1000%60,10));
        d1=parseInt(d/10);
        d2=d%10;
        h1=parseInt(h/10);
        h2=h%10;
        m1=parseInt(m/10);
        m2=m%10;
        s1=parseInt(s/10);
        s2=s%10;
      $('.time').find("span.label:eq(0)").html(d1);
      $('.time').find("span.label:eq(1)").html(d2);
      $('.time').find("span.label:eq(2)").html(h1);
      $('.time').find("span.label:eq(3)").html(h2);
      $('.time').find("span.label:eq(4)").html(m1);
      $('.time').find("span.label:eq(5)").html(m2);
      $('.time').find("span.label:eq(6)").html(s1);
      $('.time').find("span.label:eq(7)").html(s2);
      }
      return t;
  }
  function toDou(i){
    if(i<10){
      i='0'+i;
    }else{
      i=''+i;
    }
    return i;
  }
  function isUploaded(oClass){
    var uploadImg = $(oClass).val();
    if(uploadImg){
      //提交成功
      return true;
    }else{
      //提交失败
      $(oClass).parent().find('.js-textError').html('请上传图片');
      return false;
    }
  }
  // $('.js-checkForm').bind('submit',function(){
  //   if(isUploaded('.js-checkName') == false){
  //     return false;
  //   }
  // });

  //限制表情符号的输入。
  function emoji(dom,event,child){
    $(dom).on(event,child,function(e){
      var val=$(this).val();
      var allemoji =/[\u203c\u2049\u20e3\u2122\u2139\u2194\u2199\u21a9\u2195\u2196\u2197\u2198\u21aa\u231a\u231b\u23e9\u23ec\u23f0\u23f3\u24c2\u25aa\u23ea\u23eb\u25ab\u25b6\u25c0\u25fb\u25fe\u2600\u25fc\u25fd\u2601\u260e\u2611\u2614\u2615\u261d\u263a\u2648\u2653\u2660\u2663\u2665\u2649\u264a\u264b\u264c\u264d\u264e\u264f\u2650\u2651\u2652\u2666\u2668\u267b\u267f\u2693\u26a0\u26a1\u26aa\u26ab\u26bd\u26be\u26c4\u26c5\u26ce\u26d4\u26ea\u26f2\u26f3\u26f5\u26fa\u26fd\u2702\u2705\u2708\u270c\u270f\u2712\u2714\u2716\u2728\u2733\u2709\u270a\u270b\u2734\u2744\u2747\u274c\u274e\u2753\u2755\u2757\u2764\u2795\u2754\u2797\u27a1\u27b0\u2934\u2796\u2935\u2b05\u2b07\u2b1b\u2b06\u2b1c\u2b50\u2b55\u3030\u303d\u3297\u3299\u0028\u0029\ud83c\udd70\ud83c\udd71\ud83c\udd7e\ud83c\udd7f\ud83c\udd8e\ud83c\udd91\ud83c\udd9a\ud83c\udde7\ud83c\udd92\ud83c\udd93\ud83c\udd94\ud83c\udd95\ud83c\udd96\ud83c\udd97\ud83c\udd98\ud83c\udd99\ud83c\uddec\ud83c\uddee\ud83c\udde8\ud83c\udde9\ud83c\uddea\ud83c\uddeb\ud83c\uddf0\ud83c\uddf3\ud83c\uddf5\ud83c\uddf7\ud83c\uddef\ud83c\uddfa\ud83c\ude01\ud83c\uddf8\ud83c\uddf9\ud83c\ude02\ud83c\ude1a\ud83c\ude2f\ud83c\ude32\ud83c\ude3a\ud83c\ude50\ud83c\ude33\ud83c\ude34\ud83c\ude35\ud83c\ude36\ud83c\ude37\ud83c\ude38\ud83c\ude39\ud83c\ude51\ud83c\udf00\ud83c\udf20\ud83c\udf30\ud83c\udf01\ud83c\udf02\ud83c\udf03\ud83c\udf04\ud83c\udf05\ud83c\udf06\ud83c\udf07\ud83c\udf08\ud83c\udf09\ud83c\udf0a\ud83c\udf0b\ud83c\udf0c\ud83c\udf0d\ud83c\udf0e\ud83c\udf0f\ud83c\udf10\ud83c\udf11\ud83c\udf12\ud83c\udf13\ud83c\udf14\ud83c\udf15\ud83c\udf16\ud83c\udf17\ud83c\udf18\ud83c\udf19\ud83c\udf1a\ud83c\udf1b\ud83c\udf1c\ud83c\udf1d\ud83c\udf1e\ud83c\udf1f\ud83c\udf35\ud83c\udf37\ud83c\udf31\ud83c\udf32\ud83c\udf33\ud83c\udf34\ud83c\udf7c\ud83c\udf80\ud83c\udf38\ud83c\udf39\ud83c\udf3a\ud83c\udf3b\ud83c\udf3c\ud83c\udf3d\ud83c\udf3e\ud83c\udf3f\ud83c\udf40\ud83c\udf41\ud83c\udf42\ud83c\udf43\ud83c\udf44\ud83c\udf45\ud83c\udf46\ud83c\udf47\ud83c\udf48\ud83c\udf49\ud83c\udf4a\ud83c\udf4b\ud83c\udf4c\ud83c\udf4d\ud83c\udf4e\ud83c\udf4f\ud83c\udf50\ud83c\udf51\ud83c\udf52\ud83c\udf53\ud83c\udf54\ud83c\udf55\ud83c\udf56\ud83c\udf57\ud83c\udf58\ud83c\udf59\ud83c\udf5a\ud83c\udf5b\ud83c\udf5c\ud83c\udf5d\ud83c\udf5e\ud83c\udf5f\ud83c\udf60\ud83c\udf61\ud83c\udf62\ud83c\udf63\ud83c\udf64\ud83c\udf65\ud83c\udf66\ud83c\udf67\ud83c\udf68\ud83c\udf69\ud83c\udf6a\ud83c\udf6b\ud83c\udf6c\ud83c\udf6d\ud83c\udf6e\ud83c\udf6f\ud83c\udf70\ud83c\udf71\ud83c\udf72\ud83c\udf73\ud83c\udf74\ud83c\udf75\ud83c\udf76\ud83c\udf77\ud83c\udf78\ud83c\udf79\ud83c\udf7a\ud83c\udf7b\ud83c\udf93\ud83c\udfa0\ud83c\udf81\ud83c\udf82\ud83c\udf83\ud83c\udf84\ud83c\udf85\ud83c\udf86\ud83c\udf87\ud83c\udf88\ud83c\udf89\ud83c\udf8a\ud83c\udf8b\ud83c\udf8c\ud83c\udf8d\ud83c\udf8e\ud83c\udf8f\ud83c\udf90\ud83c\udf91\ud83c\udf92\ud83c\udfc4\ud83c\udfc6\ud83c\udfa1\ud83c\udfa2\ud83c\udfa3\ud83c\udfa4\ud83c\udfa5\ud83c\udfa6\ud83c\udfa7\ud83c\udfa8\ud83c\udfa9\ud83c\udfaa\ud83c\udfab\ud83c\udfac\ud83c\udfad\ud83c\udfae\ud83c\udfaf\ud83c\udfb0\ud83c\udfb1\ud83c\udfb2\ud83c\udfb3\ud83c\udfb4\ud83c\udfb5\ud83c\udfb6\ud83c\udfb7\ud83c\udfb8\ud83c\udfb9\ud83c\udfba\ud83c\udfbb\ud83c\udfbc\ud83c\udfbd\ud83c\udfbe\ud83c\udfbf\ud83c\udfc0\ud83c\udfc1\ud83c\udfc2\ud83c\udfc3\ud83c\udfca\ud83c\udfe0\ud83c\udfc7\ud83c\udfc8\ud83c\udfc9\ud83c\udff0\ud83d\udc00\ud83c\udfe1\ud83c\udfe2\ud83c\udfe3\ud83c\udfe4\ud83c\udfe5\ud83c\udfe6\ud83c\udfe7\ud83c\udfe8\ud83c\udfe9\ud83c\udfea\ud83c\udfeb\ud83c\udfec\ud83c\udfed\ud83c\udfee\ud83c\udfef\ud83d\udc3e\ud83d\udc40\ud83d\udc42\ud83d\udc01\ud83d\udc02\ud83d\udc03\ud83d\udc04\ud83d\udc05\ud83d\udc06\ud83d\udc07\ud83d\udc08\ud83d\udc09\ud83d\udc0a\ud83d\udc0b\ud83d\udc0c\ud83d\udc0d\ud83d\udc0e\ud83d\udc0f\ud83d\udc10\ud83d\udc11\ud83d\udc12\ud83d\udc13\ud83d\udc14\ud83d\udc15\ud83d\udc16\ud83d\udc17\ud83d\udc18\ud83d\udc19\ud83d\udc1a\ud83d\udc1b\ud83d\udc1c\ud83d\udc1d\ud83d\udc1e\ud83d\udc1f\ud83d\udc20\ud83d\udc21\ud83d\udc22\ud83d\udc23\ud83d\udc24\ud83d\udc25\ud83d\udc26\ud83d\udc27\ud83d\udc28\ud83d\udc29\ud83d\udc2a\ud83d\udc2b\ud83d\udc2c\ud83d\udc2d\ud83d\udc2e\ud83d\udc2f\ud83d\udc30\ud83d\udc31\ud83d\udc32\ud83d\udc33\ud83d\udc34\ud83d\udc35\ud83d\udc36\ud83d\udc37\ud83d\udc38\ud83d\udc39\ud83d\udc3a\ud83d\udc3b\ud83d\udc3c\ud83d\udc3d\ud83d\udcf7\ud83d\udcf9\ud83d\udc43\ud83d\udc44\ud83d\udc45\ud83d\udc46\ud83d\udc47\ud83d\udc48\ud83d\udc49\ud83d\udc4a\ud83d\udc4b\ud83d\udc4c\ud83d\udc4d\ud83d\udc4e\ud83d\udc4f\ud83d\udc50\ud83d\udc51\ud83d\udc52\ud83d\udc53\ud83d\udc54\ud83d\udc55\ud83d\udc56\ud83d\udc57\ud83d\udc58\ud83d\udc59\ud83d\udc5a\ud83d\udc5b\ud83d\udc5c\ud83d\udc5d\ud83d\udc5e\ud83d\udc5f\ud83d\udc60\ud83d\udc61\ud83d\udc62\ud83d\udc63\ud83d\udc64\ud83d\udc65\ud83d\udc66\ud83d\udc67\ud83d\udc68\ud83d\udc69\ud83d\udc6a\ud83d\udc6b\ud83d\udc6c\ud83d\udc6d\ud83d\udc6e\ud83d\udc6f\ud83d\udc70\ud83d\udc71\ud83d\udc72\ud83d\udc73\ud83d\udc74\ud83d\udc75\ud83d\udc76\ud83d\udc77\ud83d\udc78\ud83d\udc79\ud83d\udc7a\ud83d\udc7b\ud83d\udc7c\ud83d\udc7d\ud83d\udc7e\ud83d\udc7f\ud83d\udc80\ud83d\udc81\ud83d\udc82\ud83d\udc83\ud83d\udc84\ud83d\udc85\ud83d\udc86\ud83d\udc87\ud83d\udc88\ud83d\udc89\ud83d\udc8a\ud83d\udc8b\ud83d\udc8c\ud83d\udc8d\ud83d\udc8e\ud83d\udc8f\ud83d\udc90\ud83d\udc91\ud83d\udc92\ud83d\udc93\ud83d\udc94\ud83d\udc95\ud83d\udc96\ud83d\udc97\ud83d\udc98\ud83d\udc99\ud83d\udc9a\ud83d\udc9b\ud83d\udc9c\ud83d\udc9d\ud83d\udc9e\ud83d\udc9f\ud83d\udca0\ud83d\udca1\ud83d\udca2\ud83d\udca3\ud83d\udca4\ud83d\udca5\ud83d\udca6\ud83d\udca7\ud83d\udca8\ud83d\udca9\ud83d\udcaa\ud83d\udcab\ud83d\udcac\ud83d\udcad\ud83d\udcae\ud83d\udcaf\ud83d\udcb0\ud83d\udcb1\ud83d\udcb2\ud83d\udcb3\ud83d\udcb4\ud83d\udcb5\ud83d\udcb6\ud83d\udcb7\ud83d\udcb8\ud83d\udcb9\ud83d\udcba\ud83d\udcbb\ud83d\udcbc\ud83d\udcbd\ud83d\udcbe\ud83d\udcbf\ud83d\udcc0\ud83d\udcc1\ud83d\udcc2\ud83d\udcc3\ud83d\udcc4\ud83d\udcc5\ud83d\udcc6\ud83d\udcc7\ud83d\udcc8\ud83d\udcc9\ud83d\udcca\ud83d\udccb\ud83d\udccc\ud83d\udccd\ud83d\udcce\ud83d\udccf\ud83d\udcd0\ud83d\udcd1\ud83d\udcd2\ud83d\udcd3\ud83d\udcd4\ud83d\udcd5\ud83d\udcd6\ud83d\udcd7\ud83d\udcd8\ud83d\udcd9\ud83d\udcda\ud83d\udcdb\ud83d\udcdc\ud83d\udcdd\ud83d\udcde\ud83d\udcdf\ud83d\udce0\ud83d\udce1\ud83d\udce2\ud83d\udce3\ud83d\udce4\ud83d\udce5\ud83d\udce6\ud83d\udce7\ud83d\udce8\ud83d\udce9\ud83d\udcea\ud83d\udceb\ud83d\udcec\ud83d\udced\ud83d\udcee\ud83d\udcef\ud83d\udcf0\ud83d\udcf1\ud83d\udcf2\ud83d\udcf3\ud83d\udcf4\ud83d\udcf5\ud83d\udcf6\ud83d\udcfc\ud83d\udd00\ud83d\udcfa\ud83d\udcfb\ud83d\udd07\ud83d\udd09\ud83d\udd01\ud83d\udd02\ud83d\udd03\ud83d\udd04\ud83d\udd05\ud83d\udd06\ud83d\udd3d\ud83d\udd50\ud83d\udd0a\ud83d\udd0b\ud83d\udd0c\ud83d\udd0d\ud83d\udd0e\ud83d\udd0f\ud83d\udd10\ud83d\udd11\ud83d\udd12\ud83d\udd13\ud83d\udd14\ud83d\udd15\ud83d\udd16\ud83d\udd17\ud83d\udd18\ud83d\udd19\ud83d\udd1a\ud83d\udd1b\ud83d\udd1c\ud83d\udd1d\ud83d\udd1e\ud83d\udd1f\ud83d\udd20\ud83d\udd21\ud83d\udd22\ud83d\udd23\ud83d\udd24\ud83d\udd25\ud83d\udd26\ud83d\udd27\ud83d\udd28\ud83d\udd29\ud83d\udd2a\ud83d\udd2b\ud83d\udd2c\ud83d\udd2d\ud83d\udd2e\ud83d\udd2f\ud83d\udd30\ud83d\udd31\ud83d\udd32\ud83d\udd33\ud83d\udd34\ud83d\udd35\ud83d\udd36\ud83d\udd37\ud83d\udd38\ud83d\udd39\ud83d\udd3a\ud83d\udd3b\ud83d\udd3c\ud83d\udd67\ud83d\uddfb\ud83d\udd51\ud83d\udd52\ud83d\udd53\ud83d\udd54\ud83d\udd55\ud83d\udd56\ud83d\udd57\ud83d\udd58\ud83d\udd59\ud83d\udd5a\ud83d\udd5b\ud83d\udd5c\ud83d\udd5d\ud83d\udd5e\ud83d\udd5f\ud83d\udd60\ud83d\udd61\ud83d\udd62\ud83d\udd63\ud83d\udd64\ud83d\udd65\ud83d\udd66\ud83d\ude40\ud83d\ude45\ud83d\uddfc\ud83d\uddfd\ud83d\uddfe\ud83d\uddff\ud83d\ude00\ud83d\ude01\ud83d\ude02\ud83d\ude03\ud83d\ude04\ud83d\ude05\ud83d\ude06\ud83d\ude07\ud83d\ude08\ud83d\ude09\ud83d\ude0a\ud83d\ude0b\ud83d\ude0c\ud83d\ude0d\ud83d\ude0e\ud83d\ude0f\ud83d\ude10\ud83d\ude11\ud83d\ude12\ud83d\ude13\ud83d\ude14\ud83d\ude15\ud83d\ude16\ud83d\ude17\ud83d\ude18\ud83d\ude19\ud83d\ude1a\ud83d\ude1b\ud83d\ude1c\ud83d\ude1d\ud83d\ude1e\ud83d\ude1f\ud83d\ude20\ud83d\ude21\ud83d\ude22\ud83d\ude23\ud83d\ude24\ud83d\ude25\ud83d\ude26\ud83d\ude27\ud83d\ude28\ud83d\ude29\ud83d\ude2a\ud83d\ude2b\ud83d\ude2c\ud83d\ude2d\ud83d\ude2e\ud83d\ude2f\ud83d\ude30\ud83d\ude31\ud83d\ude32\ud83d\ude33\ud83d\ude34\ud83d\ude35\ud83d\ude36\ud83d\ude37\ud83d\ude38\ud83d\ude39\ud83d\ude3a\ud83d\ude3b\ud83d\ude3c\ud83d\ude3d\ud83d\ude3e\ud83d\ude3f\ud83d\ude4f\ud83d\ude80\ud83d\ude46\ud83d\ude47\ud83d\ude48\ud83d\ude49\ud83d\ude4a\ud83d\ude4b\ud83d\ude4c\ud83d\ude4d\ud83d\ude4e\ud83d\ude8a\ud83d\udd96\ud83c\udf2c\ud83c\udf2a\ud83c\udf9f\ud83d\ude80\ud83d\ude81\ud83d\ude82\ud83d\ude83\ud83d\ude84\ud83d\ude85\ud83d\ude86\ud83d\ude87\ud83d\ude88\ud83d\ude89\ud83d\ude8a\ud83d\ude81\ud83d\ude82\ud83d\ude83\ud83d\ude84\ud83d\ude85\ud83d\ude86\ud83d\ude87\ud83d\ude88\ud83d\ude89]/g;
      if(allemoji.test(val)){
        $(this).val(val.replace(allemoji,''));
      }
    });
  }

  emoji('.js-emoji','input');
  emoji("tbody","input",'.nested-fields .js-emoji');
  //个人中心发商品特殊符号限制
  function symbol(dom,event,child){
    $(dom).on(event,child,function(e){
      var val=$(this).val();
      var allemoji = /[\u203c\u2049\u20e3\u2122\u2139\u2194\u2199\u21a9\u2195\u2196\u2197\u2198\u21aa\u231a\u231b\u23e9\u23ec\ud83d\udd59\u23f3\ud83d\ude87\ud83d\udd32\u23ea\u23eb\ud83d\udd33\u25b6\u25c0\ud83d\udd33\ud83d\udd32\u2600\ud83d\udd32\ud83d\udd33\u2601\ud83d\udcde\u2611\u2614\u2615\u261d\u263a\u2648\u2653\u2660\u2663\u2665\u2649\u264a\u264b\u264c\u264d\u264e\u264f\u2650\u2651\u2652\u2666\u2668\u267b\u267f\ud83d\udea2\u26a0\u26a1\ud83d\udd34\ud83d\udd34\u26bd\u26be\u26c4\u2600\u2601\u26ce\ud83d\udea7\u26ea\u26f2\u26f3\u26f5\u26fa\u26fd\u2702\u2705\u2708\u270c\ud83d\udcdd\u2712\u2714\u274c\u2728\u2733\ud83d\udce9\u270a\u270b\u2734\u2744\u2728\u274c\u274c\u2753\u2755\u2757\u2764\u2795\u2754\u2797\u27a1\u27b0\u2197\u2796\u2198\u2b05\u2b07\ud83d\udd32\u2b06\ud83d\udd33\u2b50\u2b55\u3030\u303d\u3297\u3299()\ud83c\udd70\ud83c\udd71\ud83c\udd7e\ud83c\udd7f\ud83c\udd8e\ud83c\udd91\ud83c\udd9a\ud83c\udde7\ud83c\udd92\ud83c\udd93\ud83c\udd94\ud83c\udd95\ud83c\udd96\ud83c\udd97\ud83c\udd98\ud83c\udd99\ud83c\uddec\ud83c\uddee\ud83c\udde8\ud83c\udde9\ud83c\uddea\ud83c\uddeb\ud83c\uddf0\ud83c\uddf3\ud83c\uddf5\ud83c\uddf7\ud83c\uddef\ud83c\uddfa\ud83c\ude01\ud83c\uddf8\ud83c\uddf9\ud83c\ude02\ud83c\ude1a\ud83c\ude2f\ud83c\ude32\ud83c\ude3a\ud83c\ude50\ud83c\ude33\ud83c\ude34\ud83c\ude35\ud83c\ude36\ud83c\ude37\ud83c\ude38\ud83c\ude39\ud83c\ude51\ud83c\udf00\ud83c\udf20\ud83c\udf30\ud83c\udf01\ud83c\udf02\ud83c\udf03\ud83c\udf04\ud83c\udf05\ud83c\udf06\ud83c\udf07\ud83c\udf08\ud83c\udf03\ud83c\udf0a\ud83c\udf0b\ud83c\udf03\ud83c\udf0d\ud83c\udf0e\ud83c\udf0f\ud83c\udf10\ud83c\udf11\ud83c\udf12\ud83c\udf19\ud83c\udf19\ud83c\udf15\ud83c\udf16\ud83c\udf17\ud83c\udf18\ud83c\udf19\ud83c\udf1a\ud83c\udf19\ud83c\udf1c\ud83c\udf1d\ud83c\udf1e\ud83c\udf1f\ud83c\udf35\ud83c\udf37\ud83c\udf40\ud83c\udf32\ud83c\udf33\ud83c\udf34\ud83c\udf7c\ud83c\udf80\ud83c\udf38\ud83c\udf39\ud83c\udf3a\ud83c\udf3b\ud83c\udf3b\ud83c\udf3d\ud83c\udf3e\ud83c\udf40\ud83c\udf40\ud83c\udf41\ud83c\udf42\ud83c\udf43\ud83c\udf44\ud83c\udf45\ud83c\udf46\ud83c\udf47\ud83c\udf48\ud83c\udf49\ud83c\udf4a\ud83c\udf4b\ud83c\udf4c\ud83c\udf4d\ud83c\udf4f\ud83c\udf4f\ud83c\udf50\ud83c\udf51\ud83c\udf52\ud83c\udf53\ud83c\udf54\ud83c\udf55\ud83c\udf56\ud83c\udf57\ud83c\udf58\ud83c\udf59\ud83c\udf5a\ud83c\udf5b\ud83c\udf5c\ud83c\udf5d\ud83c\udf5e\ud83c\udf5f\ud83c\udf60\ud83c\udf61\ud83c\udf62\ud83c\udf63\ud83c\udf64\ud83c\udf65\ud83c\udf66\ud83c\udf67\ud83c\udf68\ud83c\udf69\ud83c\udf6a\ud83c\udf6b\ud83c\udf6c\ud83c\udf6d\ud83c\udf6e\ud83c\udf6f\ud83c\udf70\ud83c\udf71\ud83c\udf72\ud83c\udf73\ud83c\udf74\ud83c\udf75\ud83c\udf76\ud83c\udf78\ud83c\udf78\ud83c\udf78\ud83c\udf7a\ud83c\udf7b\ud83c\udf93\ud83c\udfa0\ud83c\udf81\ud83c\udf82\ud83c\udf83\ud83c\udf84\ud83c\udf85\ud83c\udf86\ud83c\udf87\ud83c\udf88\ud83c\udf89\ud83c\udf8a\ud83c\udf8b\ud83c\udf8c\ud83c\udf8d\ud83c\udf8e\ud83c\udf8f\ud83c\udf90\ud83c\udf91\ud83c\udf92\ud83c\udfc4\ud83c\udfc6\ud83c\udfa1\ud83c\udfa2\ud83d\udc1f\ud83c\udfa4\ud83c\udfa5\ud83c\udfa6\ud83c\udfa7\ud83c\udfa8\ud83c\udfa9\ud83c\udfaa\ud83c\udfab\ud83c\udfac\ud83c\udfa9\ud83c\udfae\ud83c\udfaf\ud83c\udfb0\ud83c\udfb1\ud83c\udfb2\ud83c\udfb3\ud83c\udfb4\ud83c\udfb5\ud83c\udfb6\ud83c\udfb7\ud83c\udfb8\ud83c\udfb9\ud83c\udfba\ud83c\udfbb\ud83c\udfb6\ud83c\udfbd\ud83c\udfbe\ud83c\udfbf\ud83c\udfc0\ud83c\udfc1\ud83c\udfc2\ud83c\udfc3\ud83c\udfca\ud83c\udfe0\ud83c\udfc7\ud83c\udfc8\ud83c\udfc9\ud83c\udff0\ud83d\udc00\ud83c\udfe0\ud83c\udfe2\ud83c\udfe3\ud83c\udfe4\ud83c\udfe5\ud83c\udfe6\ud83c\udfe7\ud83c\udfe8\ud83c\udfe9\ud83c\udfea\ud83c\udfeb\ud83c\udfec\ud83c\udfed\ud83c\udf76\ud83c\udfef\ud83d\udc63\ud83d\udc40\ud83d\udc42\ud83d\udc01\ud83d\udc02\ud83d\udc03\ud83d\udc04\ud83d\udc05\ud83d\udc06\ud83d\udc07\ud83d\udc08\ud83d\udc09\ud83d\udc0a\ud83d\udc0b\ud83d\udc0c\ud83d\udc0d\ud83d\udc0e\ud83d\udc0f\ud83d\udc10\ud83d\udc11\ud83d\udc12\ud83d\udc13\ud83d\udc14\ud83d\udc15\ud83d\udc16\ud83d\udc17\ud83d\udc18\ud83d\udc19\ud83d\udc1a\ud83d\udc1b\ud83d\udc1c\ud83d\udc1d\ud83d\udc1e\ud83d\udc1f\ud83d\udc20\ud83d\udc1f\ud83d\udc22\ud83d\udc23\ud83d\udc23\ud83d\udc23\ud83d\udc26\ud83d\udc27\ud83d\udc28\ud83d\udc36\ud83d\udc2a\ud83d\udc2b\ud83d\udc2c\ud83d\udc2d\ud83d\udc2e\ud83d\udc2f\ud83d\udc30\ud83d\udc31\ud83d\udc32\ud83d\udc33\ud83d\udc34\ud83d\udc35\ud83d\udc36\ud83d\udc37\ud83d\udc38\ud83d\udc39\ud83d\udc3a\ud83d\udc3b\ud83d\udc3c\ud83d\udc37\ud83d\udcf7\ud83c\udfa5\ud83d\udc43\ud83d\udc44\ud83d\ude1d\ud83d\udc46\ud83d\udc47\ud83d\udc48\ud83d\udc49\ud83d\udc4a\ud83d\udc4b\ud83d\udc4c\ud83d\udc4d\ud83d\udc4e\ud83d\udc4f\ud83d\udc50\ud83d\udc51\ud83d\udc52\ud83d\udc53\ud83d\udc54\ud83d\udc55\ud83d\udc56\ud83d\udc57\ud83d\udc58\ud83d\udc59\ud83d\udc55\ud83d\udc5b\ud83d\udc5c\ud83d\udc5d\ud83d\udc5f\ud83d\udc5f\ud83d\udc60\ud83d\udc61\ud83d\udc62\ud83d\udc63\ud83d\udc64\ud83d\udc65\ud83d\udc66\ud83d\udc67\ud83d\udc68\ud83d\udc69\ud83d\udc6a\ud83d\udc6b\ud83d\udc6c\ud83d\udc6d\ud83d\udc6e\ud83d\udc6f\ud83d\udc70\ud83d\udc71\ud83d\udc72\ud83d\udc73\ud83d\udc74\ud83d\udc75\ud83d\udc76\ud83d\udc77\ud83d\udc78\ud83d\udc79\ud83d\udc7a\ud83d\udc7b\ud83d\udc7c\ud83d\udc7d\ud83d\udc7e\ud83d\udc7f\ud83d\udc80\ud83d\udc81\ud83d\udc82\ud83d\udc83\ud83d\udc84\ud83d\udc85\ud83d\udc86\ud83d\udc87\ud83d\udc88\ud83d\udc89\ud83d\udc8a\ud83d\udc8b\ud83d\udce9\ud83d\udc97\ud83d\udc8d\ud83d\udc8e\ud83d\udc8f\ud83d\udc90\ud83d\udc91\ud83d\udc92\ud83d\udc93\ud83d\udc94\ud83d\udc93\ud83d\udc93\ud83d\udc97\ud83d\udc98\ud83d\udc99\ud83d\udc9a\ud83d\udc9b\ud83d\udc9c\ud83d\udc9d\ud83d\udc93\ud83d\udc9f\ud83d\udca0\ud83d\udca1\ud83d\udca2\ud83d\udca3\ud83d\udca4\ud83d\udca5\ud83d\udca6\ud83d\udca6\ud83d\udca8\ud83d\udca9\ud83d\udcaa\ud83d\ude16\ud83d\udcac\ud83d\udcad\ud83d\udcae\ud83d\udcaf\ud83d\udcb0\ud83d\udcb1\ud83d\udcb0\ud83d\udcb3\ud83d\udcb4\ud83d\udcb0\ud83d\udcb6\ud83d\udcb7\ud83d\udcb8\ud83d\udcb9\ud83d\udcba\ud83d\udcbb\ud83d\udcbc\ud83d\udcbd\ud83d\udcbd\ud83d\udcbf\ud83d\udcc0\ud83d\udcc1\ud83d\udcc2\ud83d\udcdd\ud83d\udcdd\ud83d\udcc5\ud83d\udcc6\ud83d\udcd8\ud83d\udcb9\ud83d\udcc9\ud83d\udcb9\ud83d\udcdd\ud83d\udccc\ud83d\udccd\ud83d\udcce\ud83d\udccf\ud83d\udcd0\ud83d\udcdd\ud83d\udcd8\ud83d\udcd8\ud83d\udcd8\ud83d\udcd8\ud83d\udcd8\ud83d\udcd8\ud83d\udcd8\ud83d\udcd8\ud83d\udcd8\ud83d\udcdb\ud83d\udcdc\ud83d\udcdd\ud83d\udcde\ud83d\udcdf\ud83d\udce0\ud83d\udce1\ud83d\udce2\ud83d\udce3\ud83d\udce4\ud83d\udce5\ud83c\udf81\ud83d\udce9\ud83d\udce9\ud83d\udce9\ud83d\udceb\ud83d\udceb\ud83d\udcec\ud83d\udced\ud83d\udcee\ud83d\udcef\ud83d\udcf0\ud83d\udcf1\ud83d\udcf2\ud83d\udcf3\ud83d\udcf4\ud83d\udcf5\ud83d\udcf6\ud83d\udcfc\ud83d\udd00\ud83d\udcfa\ud83d\udcfb\ud83d\udd07\ud83d\udd09\ud83d\udd01\ud83d\udd02\ud83d\udd03\ud83d\udd04\ud83d\udd05\ud83d\udd06\ud83d\udd3d\ud83d\udd50\ud83d\udd0a\ud83d\udd0b\ud83d\udd0c\ud83d\udd0d\ud83d\udd0d\ud83d\udd12\ud83d\udd12\ud83d\udd11\ud83d\udd12\ud83d\udd13\ud83d\udd14\ud83d\udd15\ud83d\udd16\ud83d\udd17\ud83d\udd18\u2b05\ud83d\udd1a\ud83d\udd1b\ud83d\udd1c\ud83d\udd1d\ud83d\udd1e\ud83d\udd1f\ud83d\udd20\ud83d\udd21\ud83d\udd22\ud83d\udd23\ud83d\udd24\ud83d\udd25\ud83d\udd26\ud83d\udd27\ud83d\udd28\ud83d\udd29\ud83d\udd2a\ud83d\udd2b\ud83d\udd2c\ud83d\udd2d\ud83d\udd2f\ud83d\udd2f\ud83d\udd30\ud83d\udd31\ud83d\udd32\ud83d\udd33\ud83d\udd34\ud83d\udd32\ud83d\udd33\ud83d\udd33\ud83d\udd33\ud83d\udd33\ud83d\udd3a\ud83d\udd3b\ud83d\udd3c\ud83d\udd67\ud83d\uddfb\ud83d\udd51\ud83d\udd52\ud83d\udd53\ud83d\udd54\ud83d\udd55\ud83d\udd56\ud83d\udd57\ud83d\udd58\ud83d\udd59\ud83d\udd5a\ud83d\udd5b\ud83d\udd5c\ud83d\udd5d\ud83d\udd5e\ud83d\udd5f\ud83d\udd60\ud83d\udd61\ud83d\udd62\ud83d\udd63\ud83d\udd64\ud83d\udd65\ud83d\udd66\ud83d\ude14\ud83d\ude45\ud83d\uddfc\ud83d\uddfd\ud83d\uddfe\ud83d\uddff\ud83d\ude00\ud83d\ude01\ud83d\ude02\ud83d\ude03\ud83d\ude04\ud83d\ude04\ud83d\udca6\ud83d\ude0c\ud83d\ude07\ud83d\ude08\ud83d\ude09\ud83d\ude0a\ud83d\ude0a\ud83d\ude0c\ud83d\ude0d\ud83d\ude0e\ud83d\ude0f\ud83d\ude10\ud83d\ude11\ud83d\ude12\ud83d\ude13\ud83d\ude14\ud83d\ude15\ud83d\ude16\ud83d\ude17\ud83d\ude18\ud83d\ude19\ud83d\ude1a\ud83d\ude1b\ud83d\ude1c\ud83d\ude1d\ud83d\ude1e\ud83d\ude1f\ud83d\ude20\ud83d\ude21\ud83d\ude22\ud83d\ude23\ud83d\ude01\ud83d\ude25\ud83d\ude26\ud83d\ude27\ud83d\ude28\ud83d\ude14\ud83d\ude2a\ud83d\ude23\ud83d\ude2c\ud83d\ude2d\ud83d\ude2e\ud83d\ude2f\ud83d\ude30\ud83d\ude31\ud83d\ude32\ud83d\ude33\ud83d\ude34\ud83d\ude23\ud83d\ude36\ud83d\ude37\ud83d\ude01\ud83d\ude02\ud83d\ude03\ud83d\ude0d\ud83d\ude01\ud83d\ude18\ud83d\ude21\ud83d\ude22\ud83d\ude4f\ud83d\ude80\ud83d\ude46\ud83d\ude47\ud83d\ude48\ud83d\ude49\ud83d\ude4a\u270b\ud83d\ude4c\ud83d\ude14\ud83d\ude21\ud83d\ude8a\ud83d\udd96\ud83c\udf2c\ud83c\udf2a\ud83c\udf9f\ud83d\ude80\ud83d\ude81\ud83d\ude82\ud83d\ude83\ud83d\ude84\ud83d\ude85\ud83d\ude86\ud83d\ude87\ud83d\ude88\ud83d\ude89\ud83d\ude8a\ud83d\ude81\ud83d\ude82\ud83d\ude83\ud83d\ude84\ud83d\ude85\ud83d\ude86\ud83d\ude87\ud83d\ude88\ud83d\ude89\ud83d\ude8a'&]/g;
      // var oRegExp = new RegExp('\'','g');
      if(allemoji.test(val)){
        $(this).addClass('input-error');
      }else{
        $(this).removeClass('input-error');
      }

    });
  }
  symbol('.js-symbol','change');
  symbol("tbody","change",'.nested-fields .js-symbol');

  //商品&活动&应援最小值
  $('tbody').on('keyup','.nested-fields .js-limitNum',function(){
   if($(this).parents('td').prev().find('.js-isChecked').prop('checked')==true){
    $(this).attr('min','1');
   }else{
    $(this).attr('min','0');
   }
  });
  $('tbody').on('change','.nested-fields .js-isChecked',function(){
   if($(this).prop('checked')==true){
    $(this).parents('td').next().find('.js-limitNum').attr('min','1');
   }else{
    $(this).parents('td').next().find('.js-limitNum').attr('min','0'); 
   }
  });


  //商品&活动&应援只允许输入整数
  $('tbody').on('keydown','.nested-fields .js-limitNum',function(e){
    if(event.keyCode==13)event.keyCode=9;
  })
  $('tbody').on('keypress','.nested-fields .js-limitNum',function(e){
    if ((event.keyCode<48 || event.keyCode>57)) event.returnValue=false;
  })
});
// 免费活动不需要添加现价Function
function isFree(){
  var flag = $('.js-isFree').prop('checked');
  // console.log(flag);
  if (flag) {
    $('.js-price-infos').find('.js-salePrice').attr('readonly', 'readonly').val('0');
  }else{
    $('.js-price-infos').find('.js-salePrice').attr('readonly', false);
  }
}
