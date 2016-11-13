  
  /*
  模板
  <div class="countdown text-center" data-end-at="<%= @subject.start_at %>">
                <div class="time">
                  <span class="timeblock label label-danger">0</span>
                  <span class="timeblock label label-white">0</span>
                  <span class="label-unit">天</span>
                  <span class="timeblock label label-danger">0</span>
                  <span class="timeblock label label-white">0</span>
                  <span class="label-unit">时</span>
                  <span class="timeblock label label-danger">0</span>
                  <span class="timeblock label label-white">0</span>
                  <span class="label-unit">分</span>
                  <span class="timeblock label label-danger">0</span>
                  <span class="timeblock label label-white">0</span>
                  <!-- <span class="label-unit">秒</span> -->
                </div>
                <div class="countdown-title">直播倒计时</div>
              </div>
  页面下面调用
  var Timer=null;
  Timer=setInterval(function(){
    var endAt = $('.countdown').attr('data-end-at');
    var t2=GetRTime(endAt);
    if(t2<0){
      clearInterval(Timer);
      window.location.href='/';
    }
  },1000);
  */
  function GetRTime(time){
    var enDt = time.replace(/-/g,"/");
    var EndTime= new Date(enDt);
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
    $('.time').find("span.timeblock:eq(0)").html(d1);
    $('.time').find("span.timeblock:eq(1)").html(d2);
    $('.time').find("span.timeblock:eq(2)").html(h1);
    $('.time').find("span.timeblock:eq(3)").html(h2);
    $('.time').find("span.timeblock:eq(4)").html(m1);
    $('.time').find("span.timeblock:eq(5)").html(m2);
    $('.time').find("span.timeblock:eq(6)").html(s1);
    $('.time').find("span.timeblock:eq(7)").html(s2);
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
  function isExpired(time){
    var enDt = time.replace(/-/g,"/");
    var EndTime= new Date(enDt);
    var NowTime = new Date();
    var t =EndTime.getTime() - NowTime.getTime();
    if(t<0){
      return false;
    }else{
      return true;
    }
  }
  function changeTime(){
    var Timer=null;
    Timer=setInterval(function(){
      var endAt = $('.time').attr('data-end-at');
      var startAt = $('.time').attr('data-start-at');
      if(endAt == undefined){
        clearInterval(Timer);
      }
      if(isExpired(startAt)){
        $('.js-timeTip').html('距开始:');
        var t2 = GetRTime(startAt);
      }else{
        $('.js-timeTip').html('距结束:');
        var t2 = GetRTime(endAt);
      }
      if(t2<0){
        clearInterval(Timer);
      }
    },1000);
  }