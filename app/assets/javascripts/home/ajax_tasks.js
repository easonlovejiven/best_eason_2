$(function(){
  function elAjaxHome(url,that,targetContent){
    var that =that;
    var targetContent = targetContent;
    $.ajax({
      type:'GET',
      url:url,
      data:{
        category : $(that).attr('data-category')
      },
      success:function(msg){
        $(targetContent).html('');
        for(var i=0;i<msg.tasks.length;i++){
          homeAjax(msg.tasks[i],i,targetContent);
        }
        if(msg.tasks.length == 0){
          var str = '<div class="col-xs-12">'+
                      '<div class="null-content">'+
                        '<div class="text-center translate-middle-y">'+
                          '<p>'+
                            '<img src="http://qimage.owhat.cn/null-content.png">'+
                          '</p>'+
                          '<p>请关注您喜爱的明星来获取任务~</p>'+
                        '</div>'+
                      '</div>'+
                    '</div>';
          $(targetContent).html(str);
        }
      },
      error:function(){
        $(targetContent).html('<h3>请稍后重试</h3>');
      }
    })
  }
  $('.js_home_ajax a[data-toggle="tab"]').on('shown.bs.tab', function (e) {
    // e.target // newly activated tab
    // e.relatedTarget // previous active tab
    var that = e.target;  //当前元素
    var targetContent = $(e.target).attr('href');     //显示的div
    elAjaxHome('/home/home/tasks.json',that,targetContent);
  })
  $('.js_welfare_ajax a[data-toggle="tab"]').on('shown.bs.tab', function (e) {
    // e.target // newly activated tab
    // e.relatedTarget // previous active tab
    var that = e.target;  //当前元素
    var targetContent = $(e.target).attr('href');     //显示的div
    elAjaxHome('/home/home/welfares.json',that,targetContent);
  })

  function homeAjax(msg,con,content){
    var userTitle = msg.user.name || 'O星人',
    taskClass= '',
    isShare = '',
    userStatus = '',
    oMediaClass = '',
    eventStyle = 'shop';
    switch(msg.user.identity){
      case 'expert':
      userStatus = '<i class="icons v-icon v-expert"><span>&#xe609;</span></i>';
      break;
      case 'organization':
      userStatus = '<i class="icons v-icon v-organ"><span>&#xe609;</span></i>';
      break;
    }
    switch(con<8){
      case con<1:
      taskClass = 'task-D '+con+'';
      break;
      case con>=1 && con<=4:
      taskClass = 'task-E '+con+'';
      break;
      case con >4 && con<=7:
      taskClass = 'task-F '+con+'';
      break;
      default:
      taskClass = con;
      break;
    }
    switch(msg.shop_type){
      case 'Shop::Event':
      eventStyle = 'shop';
      break;
      case 'Shop::Funding':
      eventStyle = 'funding';
      break;
      case 'Shop::Topic':
      eventStyle = 'news';
      break;
      case 'Qa::Poster':
      eventStyle = 'FAQ';
      break;
      case 'Shop::Media':
      eventStyle = 'media';
      if(msg.user.is_login == true){
        oMediaClass = 'js-media_achieve';
      }
      break;
      case 'Shop::Subject':
      eventStyle = 'topic';
      break;
      case 'Welfare::Event':
      eventStyle = 'event';
      break;
      case 'Welfare::Product':
      eventStyle = 'product';
      break;
      case 'Welfare::Letter':
      eventStyle = 'letter';
      break;
      case 'Welfare::Voice':
      eventStyle = 'voice';
      break;
    }
    var str = '<div class="'+taskClass+'">'+
              '<div class="task-item">'+
                '<a class="task-item-thumb '+oMediaClass+'" href="'+msg.url+'">'+
                  '<img src="'+msg.pic+'" alt="">'+
                  '<span class="task-mark task-mark-'+eventStyle+'"></span>'+
                '</a>'+
                '<div class="limit-height">'+
                  '<h5 class="title ellipsis">'+
                    '<a href="'+msg.url+'">'+msg.title+'</a>'+
                  '</h5>'+
                  '<div class="ellipsis">'+
                    '<a href="'+msg.user.url+'">'+userTitle+'</a> '+userStatus+''+
                  '</div>'+
                '</div>'+
              '</div>'+
            '</div>';
    if(con < 8){
      $(content).append(str);
    }
  }
  //直播的评论
  var userId = $('.js_subject_info').attr('data-userId'),
  subjectId = $('.js_subject_info').attr('data-subjectId'),
  subjectClass = $('.js_subject_info').attr('data-subjectClass');
  $('.js-publish').click(function(){
    var userContent = $('.js-topicTextarea').val();
    $(this).attr('disabled',true);
    if($('.js-subject-list').find('.null-content').length){
      $('.js-subject-list').find('.null-content').remove();
    }
    $.ajax({
      url:'/home/home/create_subject_comments.json',
      type:'post',
      data:{
        uid : userId,
        subject_id:subjectId,
        task_type:subjectClass,
        content:userContent,
        sign : $.md5('subject_id:'+subjectId+'&task_type:'+subjectClass+'&uid:'+userId+'OTjnsYwSZ76IR98')
      },
      success:function(msg){
        if(msg.error){
          alert(msg.error);
        }else{
          $('.js_comment_count').html(msg.data.total_count+1);
            // if(msg.data.count<3){
          var userStatus = '';
          switch(msg.data.identity){
            case 'expert':
            userStatus = '<i class="icons v-icon v-expert"><span>&#xe609;</span></i>';
            break;
            case 'organization':
            userStatus = '<i class="icons v-icon v-organ"><span>&#xe609;</span></i>';
            break;
            case 'common':
            userStatus = '<i class="v-lv badge badge-yellow-light">Lv.'+msg.data.level+'</i>';
            break;
          }
          var s = new Date(msg.data.created_at);
          var now = new Date();
          var oT = now.getTime()-s.getTime();
          var tShow = '1';
          if(oT<60){
            tShow='1';
          }
          var subjectStr ='<div class="avatar-head has-bordered clearfix">'+
                            '<div class="pull-right text-right">'+
                              '<span class="date"><span title="'+msg.data.created_at+'" class="datetime datetime_ago">'+tShow+'分钟前</span></span>'+
                            '</div>'+
                            '<a class="avatar-round avatar-xs pull-left" href="/home/users/'+userId+'">'+
                              '<img alt="" class="img-circle" src="'+msg.data.user_pic+'">'+
                            '</a>'+
                            '<div class="name-location">'+
                              '<div class="ellipsis"><a href="/home/users/'+userId+'">'+msg.data.user_name+' &nbsp;&nbsp;'+userStatus+'</a></div>'+
                              '<div class="comment-article word-bread">'+
                                ''+msg.data.content+''+
                              '</div>'+
                            '</div>'+
                          '</div>';
          $('.js-subject-list').append(subjectStr);
        // }else{
        //   alert('只能发送三条评论哦');
        // }
          $('.js-topicTextarea').val('');
        }
      },
      error:function(msg){
        alert(msg.error);
      }
    });
  });
  //动态评论
  $('.js_dynamic_publish').click(function(event){
    var userId,dynamicId,parentId,oContent;
    userId = $('.js_dynamic_user_id').val();
    dynamicId = $('.js_dynamic_id').val();
    parentId = 0;
    oContent = $('.js-topicTextarea').val();
    event.preventDefault();
    if(oContent.trim() == ''){
      alert('内容不能为空');
      $('.js-topicTextarea').val('');
    }else{
      $.ajax({
        url:'/home/home/create_dynamic_comments.json',
        type:'POST',
        data:{
          'user_id':userId,
          'dynamic_id':dynamicId,
          'parent_id':parentId,
          'content':oContent,
          'sign':$.md5('dynamic_id:'+dynamicId+'&parent_id:'+parentId+'&user_id:'+userId+'OTjnsYwSZ76IR98')
        },
        success:function(msg){
          if(msg.status){
            var oCreateDate = new Date(msg.data.created_at);
            var str = '<div class="avatar-head has-bordered" data-replay="replayBox">'+
                        '<div class="pull-right text-right">'+
                          '<span class="date">'+
                            ''+oCreateDate.getFullYear()+'-'+dTodou(oCreateDate.getMonth()+1)+'-'+dTodou(oCreateDate.getDate())+' '+dTodou(oCreateDate.getHours())+':'+dTodou(oCreateDate.getMinutes())+':'+dTodou(oCreateDate.getMinutes())+''+
                          '</span>'+
                          '<a class="reply-btn js-reply-show " href="javascript:;">回复(<span class="comment_8">0</span>)</a>'+
                        '</div>'+
                        '<a class="avatar-round avatar-xs pull-left" href="#">'+
                          '<img class="img-circle" src="'+msg.data.user_pic+'" alt="B259342c01803c19c284ffeede72da35">'+
                        '</a>'+
                        '<div class="name-location">'+
                          '<div class="ellipsis"><a href="#">'+msg.data.user_name+' &nbsp;&nbsp;'+sIdentity(msg.data.identity,msg.data.level)+'</div>'+
                          '<div class="comment-article word-bread">'+
                            ''+msg.data.content+''+
                          '</div>'+
                        '</div>'+
                      '</div>'
            $('.js_comments_list').append(str);
            $('.js-topicTextarea').val('');
            if($('.js_no_comments').length){
              $('.js_no_comments').css('display','none');
            }
            $('.js_dynamic_count').text(msg.data.total_count);
          }else{
            alert(msg.error);
          }
        },
        error:function(msg){
          alert('服务器正忙,请稍候重试');
        }
      })
    }
  });
  function dTodou(n){
    return n<10?'0'+n:''+n;
  }
  function sIdentity(str,lev){
    switch(str){
      case 'expert':
      return '<i class="icons v-icon v-expert"><span>&#xe609;</span></i>';
      case 'organization':
      return '<i class="icons v-icon v-organ"><span>&#xe609;</span></i>';
      case 'common':
      return '<i class="v-lv badge badge-yellow-light">Lv.'+lev+'</i>';
    }
  }
});
