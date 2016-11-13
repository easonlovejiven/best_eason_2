$(function(){
  if ($('.bdsharebuttonbox').length) {
    var hostName = window.location.origin;
    with(document)0[(getElementsByTagName('body')[0]||body).appendChild(createElement('script')).src='http://bdimg.share.baidu.com/static/api/js/share.js?cdnversion='+~(-new Date()/36e5)];
    window._bd_share_config = {
      common : {
        //此处放置通用设置
        bdText : '自定义分享内容',//
        bdDesc : '自定义分享摘要',
        bdUrl : '自定义分享url地址',
        bdPic : '自定义分享图片',
        onBeforeClick : function(cmd, config){ //在用户点击分享按钮时执行代码，更改配置。cmd为分享目标id，config为当前设置，返回值为更新后的设置。
          var obdText = '', obdUrl = '', obdPic = '';
          var cls = this.tag;
          var shareHash = JSON.parse($('.'+cls).find('input').val());
          var shareType = shareHash.type;
          var ourl = hostName;
          // console.log(ourl);
          obdUrl = ourl + shareHash.url;
          obdDesc = '';
          obdPic = shareHash.pic;
          if (shareHash.type == 'task' && shareHash.text == '我喜欢这个话题') {
            obdText = shareHash.text + ':' + shareHash.title + '' + obdUrl;
          }else if(shareHash.type == 'task'){
            obdText = (!shareHash.text ? '' : (shareHash.text + ':')) + shareHash.title + ' ' + obdUrl;
          }else if(shareHash.type == 'topic_dynamic'){
            obdText = shareHash.text + ': ' + obdUrl + ' ' + shareHash.title;
          }else if(shareHash.type == 'order'){
            obdText = shareHash.text;
          }else{
            obdText = shareHash.title + '的Owhat主页' + ' ' + obdUrl;
          }
          return {
            //此处放置通用设置
            bdText : obdText,//
            bdDesc : obdDesc,
            bdUrl : obdUrl,
            bdPic : obdPic
          }
        },
        onAfterClick: function(cmd){
          var cls = this.tag;
          var shareHash = JSON.parse($('.'+cls).find('input').val());
          // console.log(cmd);
          if ($('.'+cls).attr('data-current')) {
            $.ajax({
              type: 'POST',
              url: '/home/users/share_callback.json',
              data:{
                'share_id': shareHash.share_id,
                'type': shareHash.type
              },
              success: function(msg) {
                // 请求成功之后执行
              },
              error: function(msg) {
                // 请求失败后执行
              }
            })
          }
        }
      },
      share : [
        //此处放置分享按钮设置
      ]//,
      // slide : [
      //   //此处放置浮窗分享设置
      // ],
      // image : [
      //   //此处放置图片分享设置
      // ],
      // selectShare : [
      //   //此处放置划词分享设置
      // ]
    };
    var arrShare = [],
        arrJson = {};
    $('.bdsharebuttonbox').each(function(index){
      arrShare.push($(this).attr('data-tag'));
    });
    for(var i = 0; i < arrShare.length; i++){
      if(!arrJson[arrShare[i]]){
        arrJson[arrShare[i]] = 1;
      }else{
        arrJson[arrShare[i]] += 1;
      }
    }
    for(var o in arrJson){
      window._bd_share_config.share.push({'tag':o});
    }
  }
})
