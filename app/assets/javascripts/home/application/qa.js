$(function(){
  //问答
  var a=document.querySelector('.js-qa-timer');
  if(a){
    var qaTrueAnswer = 0;
    var qaFalseAnswer = 0;
    var oqaLen = 0;
    var oQaTrVa = $('.js-trueAnswer').html();
    var oQaTrEx = $('.js-trueExp').html();
    var oQaTrRMB = $('.js-trueRMB').html();
    var questionH = $('.js-questionP').height();
    var timer = null;
    var oRe = window.location.search;
    var bAgain = /time/.test(oRe);
    var oTime = oRe.match(/\d+/g);
    var oHostMs = 10000;
    //向上滑动
    if($(window).width()<768){
      $('.form-currentGroup').height(questionH+20+'px');
      console.log($('.form-currentGroup').height());
    }
    var setTranslateY = function(y){
      $('.js-questionP').css({
        '-webkit-transform': 'translateY('+y+'px)',
        '-moz-transform':'translateY('+y+'px)',
        '-ms-transform': 'translateY('+y+'px)',
        '-o-transform':'translateY('+y+'px)',
        'transform': 'translateY('+y+'px)',
      });
      $('.js-questionP').find('.pull-left').css('display','inline-block');
    }      
    console.log($('.js-questionP'))                     
    //只有#qa-start出现的时候才会出现js_qa_start
    $('.js_qa_start').click(function(){
        $('#qa-start').modal('hide');
        changeTime('.js-qa-timer');
    }); 
    $('.js_qa_again_start').click(function(){
        $('#qa-start-again').modal('hide');
        changeTime('.js-qa-timer');
    });
    //继续
    $('.js_qa_again_continue').click(function(){
      $("#qa-start-continue").modal('hide');
      changeTime('.js-qa-timer');
    });    
    //如果登录
    if($('.js_qa_user_login').length){
      //如果是重新进来的
     if(bAgain){
        $('#qa-start-again').modal('show');
      }else{
        $('#qa-start').modal('show');     
      }
      //1.点击
      $('input:radio').click(function(){
        var that=$(this);
        var oJsQuestion=$(this).parent().find('.js-question').attr('value');
        var oJsAnswer=$(this).parent().find('.js-answer').attr('value');
        var oSuccStr='<div class="answer form-control answer-right">'+
                    '<span class="ellipsis ellipsis-l2 translate-middle-y">'+
                    // '<i class="icons">&#xe625;</i>'+
                    '腻害,回答正确！'+
                    '</span>'+
                  '</div>';
        var oErrorStr='<div class="answer form-control answer-wrong">'+
                      '<span class="ellipsis ellipsis-l2 translate-middle-y">'+
                      // '<i class="icons">&#xe623;</i>'+
                      '回答错误,正确答案为'+
                      '<span class="js-rightAnswer"></span>'                      
                      '</span>'+
                  '</div>';
        var oId = $('.js-qaCheck').val();
        $.ajax({
          url:'/qa/posters/'+oId+'/answer.json',
          type:'PUT',
          data:{
            question_id:oJsQuestion,
            answer_id:oJsAnswer
          },
          success:function(msg){
            var saa=msg.right;
            console.log(msg);
            //sa是正确的
            //做错了
            oqaLen++;
            //如果错误
            if(saa){
              qaFalseAnswer +=1;
              $('.js-wrong').html('0'+qaFalseAnswer);              
              that.parent().parent().append(oErrorStr);
                console.log(that.parent());
              $('.js-answer').each(function(){
                //循环所有的选项，然后找到对应的去除选项值
                if($(this).attr('value')==saa){
                  var val = $(this).siblings('span').children('.answer-select').html().replace('.','');
                  that.parent().parent().find('.js-rightAnswer').html(val);
                }
              });
              //如果正确
            }else{
              qaTrueAnswer += 1;
              $('.js-right').html('0'+qaTrueAnswer);              
              that.parent().parent().append(oSuccStr);
            }

          clearInterval(timer);
          if(oqaLen <= 4){
          console.log(oqaLen);
          setTimeout(function(){
            setTranslateY(-(questionH+20)*oqaLen);
            changeTime('.js-qa-timer');
           },2000);
          }else{
            
            var oQaId=$('.js-qaCheck').val();
            //答题完成
            // $(oMs).text(toDou(0));
            oQaTrVa = qaTrueAnswer;
            $('.js-trueAnswer').html(oQaTrVa);
            $('.js-trueExp').html(oQaTrVa*1);
            $('.js-trueRMB').html(oQaTrVa*1);


            $('#questionsDoneModal').modal();
            $('#questionsDoneModal').on('shown.bs.modal.bs.modal', function (e) {
            });
            $.ajax({
              url:'/qa/posters/'+oQaId+'/complete.json',
              type:'PUT',
              data:{
                id:oQaId,
                obi:oQaTrVa
              }
            });
            clearInterval(timer);
            var oHrefStr = window.location.href;
            var oHrefReg = oHrefStr.replace(/\?time=(\d+)/g,function(){
              return '';
            });
            history.pushState("", "Title", oHrefReg);
            }  
        }
      })
      $(this).parents('.js-questionP').find('.question').each(function(){
        $(this).attr('disabled',true);
      });        
    })
    }else{
      $('#qa-login').modal();
        var oHrefStr = $('.js_qa_login_timer').attr('href');
        var oHrefReg = oHrefStr.replace(/\?time=(\d+)/g,function(){
          return '?time='+oHostMs+'';
        });
        $('.js_qa_login_timer').attr('href',oHrefReg);
    }
  }
  function changeTime(oClass){
      var os=$(oClass).find('.js-timer').attr('data-time');
      var oM=$(oClass).find('.minute');
      var oS=$(oClass).find('.second');
      var oMs=$(oClass).find('.ms'); 
      var oQaId=$('.js-qaCheck').val();
      timer=setInterval(function(){
        os-=31;
        if(os<60){
          os=0;
          $(oM).text(toDou(parseInt(os/1000/60)));
          $(oS).text(toDou(parseInt(os/1000%60)));
          $(oMs).text(toDou(os).substring(0,2));
        }
         oQaTrVa = qaTrueAnswer;
        if(oQaTrVa > 5){
          oQaTrVa = 5 ;
        }         
        console.log(oQaTrVa);
        // if(oQaTrVa <= 0){
        //   console.log('hahhahahh');
        //   $('.js-qaInfo').html('没有答对不获得任何奖励');
        // }
          $('.js-trueAnswer').html(oQaTrVa);
          $('.js-trueExp').html(oQaTrVa*1);
          $('.js-trueRMB').html(oQaTrVa*1);            
          if(oqaLen+1 > 5){
           oqaLen= 4;
          }
           $('.js-current-question').html(oqaLen+1);
        if(os <=0){
          qaFalseAnswer++;
          $('.js-wrong').html('0'+qaFalseAnswer); 
          // console.log($('.js-questionP').attr('data-answered'));
          clearInterval(timer);
          if(oqaLen < 4){
            if($('.js-questionP').attr('data-answered')==0){
              $("#qa-start-continue").modal('show');
              oqaLen = oqaLen+1;
              $('.js_qa_again_continue').click(function(){
                setTranslateY(-(questionH+20)*oqaLen);
              });               
            }
            $('.js-questionP').attr('data-answered','0');
          }else{
            //答题完成
            $(oMs).text(toDou(0));
            $('#questionsDoneModal').modal();
            $('#questionsDoneModal').on('shown.bs.modal.bs.modal', function (e) {
          });
          $.ajax({
            url:'/qa/posters/'+oQaId+'/complete.json',
            type:'PUT',
            data:{
              id:oQaId,
              obi:oQaTrVa
            }
          });
          clearInterval(timer);
          var oHrefStr = window.location.href;
          var oHrefReg = oHrefStr.replace(/\?time=(\d+)/g,function(){
            return '';
          });
          history.pushState("", "Title", oHrefReg);
          $('.js-questionP').find('.question').each(function(index, el) {
              $(this).attr('disabled',true);
          });
          }
        }else{
          var oStart = toDou(os).length-2;
          var oEnd = toDou(os).length; 
          $(oM).text(toDou(parseInt(os/1000/60)));
          $(oS).text(toDou(parseInt(os/1000%60)));
          $(oMs).text(toDou(os).substring(oStart,oEnd));
         
        }
     oHostMs = os;  
    },31)
  }
  function toDou(i){
  return i<10?'0'+i:''+i;
  }
})