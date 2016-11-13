$(function(){
  var aImage=document.querySelectorAll('.formPhoto .thumb-show');
  var oNum=document.querySelector('.topics-photo .topics-num');
  var bAdd=true;
  var oPhotoAdd=document.querySelector('.photoadd');
  var oVideoAdd=document.querySelector('.videoadd');
  var oPhoto=document.querySelector('.formPhoto');
  var oVideo=document.querySelector('.formVideo');
  var oVideoNum=document.querySelector('.topics-video-num');
  var oClosePhoto=document.querySelector('.closephoto');
  var oCloseVideo=document.querySelector('.closevideo');
  $('.topics-botton .btnphoto').on('click',function(){
    clearphoto();
    clearvideo();
    var $photoShow = $('.topics-photo');
    $photoShow.addClass('active').toggle();
    var str='<div class="thumb-img-add topics-btn photoadd">';
    $('.formPhoto').html(str);
    if ($photoShow.css('display') == 'block') {
      fnaddPhoto('.photoadd','.formPhoto',oNum,oClosePhoto);
      $('.js-name').attr('data-name','shop_topic_dynamic[pictures_attributes]');
    };
    $('.topics-video').hide();
  });
  $('.topics-botton .btnvideo').click(function(){
    clearphoto();
    clearvideo();
    var $videoShow=$('.topics-video');
    $videoShow.addClass('active').toggle();
    var str='<div class="thumb-img-add topics-btn videoadd">';
    $('.formVideo').html(str);
    if($videoShow.css('display')=='block'){
      fnaddVideo('.videoadd','.formVideo',oVideoNum,oCloseVideo);
      $('.js-name').attr('data-name','shop_topic_dynamic[videos_attributes]');
    }
    $('.topics-photo').hide();
  });
  if(document.querySelector('.js-upload-photoadd')&&document.querySelector('.js-upload-photo')){
    fnuploadphoto('.js-upload-photoadd','.js-upload-photo',1,2);
  }
  //shu xi
  if(document.querySelector('.js-upload-photoadd1')&&document.querySelector('.js-upload-photo1')){
      fnuploadphoto('.js-upload-photoadd1','.js-upload-photo1',30,10);
  }
  if(document.querySelector('.js-upload-photoadd2')&&document.querySelector('.js-upload-photo2')){
      fnuploadphotoradio('.js-upload-photoadd2','.js-upload-photo2',1);
  }
  //
  if(document.querySelector('.js-upload-photoadd-1')&&document.querySelector('.js-upload-photo-1')){
    $('.js-photobtn1').on('click',function(){
      var str='<div class="thumb-img-add topics-btn js-upload-photoadd-1"></div>';
      $('.js-upload-photo-1').html(str).toggleClass('hide');
      fnuploadphotoradio('.js-upload-photoadd-1','.js-upload-photo-1',1);
    });
  }
  if(document.querySelector('.js-upload-photoadd-2')&&document.querySelector('.js-upload-photo-2')){
    $('.js-photobtn2').on('click',function(){
      var str='<div class="thumb-img-add topics-btn js-upload-photoadd-2"></div>';
      $('.js-upload-photo-2').html(str).toggleClass('hide');
      fnuploadphotoradio('.js-upload-photoadd-2','.js-upload-photo-2',1);
    });
  }
  if(document.querySelector('.js-upload-photoadd-3')&&document.querySelector('.js-upload-photo-3')){
    $('.js-photobtn3').on('click',function(){
      var str='<div class="thumb-img-add topics-btn js-upload-photoadd-3"></div>';
      $('.js-upload-photo-3').html(str).toggleClass('hide');
      fnuploadphotoradio('.js-upload-photoadd-3','.js-upload-photo-3',1);
    });
  }
  if(document.querySelector('.js-upload-photoadd-01')&&document.querySelector('.js-upload-photo-01')){
    fnuploadphotoradio('.js-upload-photoadd-01','.js-upload-photo-01',1);
    fnuploadphotoradio('.js-upload-photoadd-02','.js-upload-photo-02',1);
    fnuploadphotoradio('.js-upload-photoadd-03','.js-upload-photo-03',1);
    fnuploadphotoradio('.js-upload-photoadd-04','.js-upload-photo-04',1);
    fnuploadphotoradio('.js-upload-photoadd-05','.js-upload-photo-05',1);
  }

  //oPhotoAdd:添加按钮
  //ophoto 添加到的父级元素
  //oNum  上传成功的数量
  //oClose 关闭按钮
  // 上传图片
  function fnaddPhoto(oPhotoAdd,oPhoto,oNum,oClosePhoto){
    var oPhotoAdd=document.querySelector(oPhotoAdd);
    var oPhoto=document.querySelector(oPhoto);
    var imglen=0;
    $.ajax({
      type:'post',
      url:'/api/qiniu_uptoken',
      success:function(msg){
          // 引入Plupload 、qiniu.js后
          var uploader = Qiniu.uploader({
              runtimes: 'html5,flash,html4',    //上传模式,依次退化
              browse_button: oPhotoAdd,       //上传选择的点选按钮，**必需**
              //uptoken_url:'http://192.168.1.139:3000/api/qiniu_uptoken',            //Ajax请求upToken的Url，**强烈建议设置**（服务端提供）
              //uptoken_url: 'http://101.200.73.14/api/qiniu_uptoken',            //Ajax请求upToken的Url，**强烈建议设置**（服务端提供）
              uptoken :msg.uptoken, //若未指定uptoken_url,则必须指定 uptoken ,uptoken由其他程序生成
              // unique_names: true, // 默认 false，key为文件名。若开启该选项，SDK为自动生成上传成功后的key（文件名）。
              // save_key: true,   // 默认 false。若在服务端生成uptoken的上传策略中指定了 `sava_key`，则开启，SDK会忽略对key的处理
              domain:msg.qiniu_host,   //bucket 域名，下载资源时用到，**必需**
              get_new_uptoken: true,  //设置上传文件的时候是否每次都重新获取新的token
              max_file_size: '2M',           //最大文件体积限制
              flash_swf_url: 'js/plupload/Moxie.swf',  //引入flash,相对路径
              max_retries: 3,                   //上传失败最大重试次数
              dragdrop:false,                   //开启可拖曳上传
              // drop_element: 'container',        //拖曳上传区域元素的ID，拖曳文件或文件夹后可触发上传
              chunk_size: '4mb',                //分块上传时，每片的体积
              auto_start: true,                 //选择文件后自动上传，若关闭需要自己绑定事件触发上传
              filters: {
                mime_types : [ //只允许上传图片和zip文件
                  { title : "Image files", extensions : "jpg,gif,png,jpeg" },
                ],
                max_file_size : '2048kb', //最大只能上传4000kb的文件
                prevent_duplicates : false //不允许选取重复文件
              },
              init: {
                'FileFiltered':function(uploader,file){
                  if(oNum.innerHTML==0){
                    imglen=0;
                  }
                 },
                'FilesAdded': function(up, files) {
                  plupload.each(files, function(file) {
                    // 文件添加进队列后,处理相关的事情
                    if(!checkImgExtension(file.name)){
                      uploader.stop();
                      uploader.destroy();
                      alert('格式需是jpg/jpeg/gif/png');
                    }
                  });
                },
                'BeforeUpload': function(up, file) {
                         // 每个文件上传前,处理相关的事情
                },
                'UploadProgress': function(up, file) {
                   // 每个文件上传时,处理相关的事情
                   oClosePhoto.onclick=function(){
                    uploader.stop();
                    uploader.destroy();
                   };
                },
                'FileUploaded': function(up, file, info) {
                   // 每个文件上传成功后,处理相关的事情
                   // 其中 info 是文件上传成功后，服务端返回的json，形式如
                   // {
                   //    "hash": "Fh8xVqod2MQ1mocfI4S4KpRL6D98",
                   //    "key": "gogopher.jpg"
                   //  }
                   // 参考http://developer.qiniu.com/docs/v6/api/overview/up/response/simple-response.html

                    // imglen++;
                    // if(imglen==9){
                    //   oPhotoAdd.style.display='none';
                    //   bAdd=true;
                    //   uploader.splice(9,9999);
                    //   alert('最多上传9张');
                    // }
                    // else{
                    //   oPhotoAdd.style.display='inline-block';
                    //   bAdd=true;
                    // }
                    imglen++;
                    if(imglen>9){
                      bAdd=false;
                      uploader.splice(9,9999);
                      alert('最多上传'+9+'张');
                      imglen--;
                      oPhotoAdd.style.display='none';
                    }
                    else if(imglen==9){
                      bAdd=true;
                      uploader.splice(9,999);
                      oPhotoAdd.style.display='none';
                    }
                    else{
                      bAdd=true;
                      oPhotoAdd.style.display='inline-block';
                    }
                    if(bAdd){
                      var domain = up.getOption('domain');
                      var res =$.parseJSON(info);
                      var sourceLink ='http://'+domain+'/'+res.key; //获取上传成功后的文件的Url
                      var div=document.createElement('div');
                      div.className='thumb-show';
                      div.innerHTML='<span class="thumbnail-cover"><img class="js-inputImg" src='+sourceLink+'?imageMogr2/auto-orient/thumbnail/!244x244r/gravity/Center/crop/244x244'+' data-src='+res.key+'></span>';
                      oPhoto.insertBefore(div,oPhotoAdd);
                      var oA=document.createElement('a');
                      oA.innerHTML='&times';
                      oA.className='close close-rounded-sm deletephoto';
                      oA.setAttribute('href','javascript:;')
                      div.appendChild(oA);
                      oA.onclick=function(){
                       oPhoto.removeChild(this.parentNode);
                       imglen--;
                       if(imglen<9){
                         oPhotoAdd.style.display='inline-block';
                       }
                       oNum.innerHTML=imglen;
                      }
                      oNum.innerHTML=imglen;
                    };
                },
                'Error': function(up, err, errTip) {
                   //上传出错时,处理相关的事情
                     alert(errTip);
                },
                'UploadComplete': function() {
                  //队列文件处理完毕后,处理相关的事情
                },
                'Key': function(up, file) {
                  // 若想在前端对每个文件的key进行个性化处理，可以配置该函数
                  // 该配置必须要在 unique_names: false , save_key: false 时才生效
                  var date = new Date();
                  var time = date.getTime();
                  var md = $.md5('' + time);
                  var key = "tasktype" + "/" + "uid" + "/" + md + ".jpg";
                  return key;
                }
              }
          });
      },
      error:function(msg){
        alert('暂时无法上传图片');
      }
    });
  }

  //上传视频
  function fnaddVideo(oVideoAdd,oVideo,oVideoNum,oCloseVideo){
    var oVideoAdd=document.querySelector(oVideoAdd);
    var oVideo=document.querySelector(oVideo);
    oVideoNum.innerHTML=0;
    $.ajax({
      url:'/api/qiniu_uptoken',
      type:'post',
      success:function(msg){
        var uploader = Qiniu.uploader({
          runtimes: 'html5,flash,html4',    //上传模式,依次退化
          browse_button: oVideoAdd,       //上传选择的点选按钮，**必需**
          // uptoken_url: msg.,            //Ajax请求upToken的Url，**强烈建议设置**（服务端提供）
          uptoken : msg.uptoken, //若未指定uptoken_url,则必须指定 uptoken ,uptoken由其他程序生成
          // unique_names: true, // 默认 false，key为文件名。若开启该选项，SDK为自动生成上传成功后的key（文件名）。
          // save_key: true,   // 默认 false。若在服务端生成uptoken的上传策略中指定了 `sava_key`，则开启，SDK会忽略对key的处理
          domain: msg.qiniu_host,   //bucket 域名，下载资源时用到，**必需**
          get_new_uptoken: false,  //设置上传文件的时候是否每次都重新获取新的token
          //container: 'container',           //上传区域DOM ID，默认是browser_button的父元素，
          max_file_size: '5000mb',           //最大文件体积限制
          flash_swf_url: 'js/plupload/Moxie.swf',  //引入flash,相对路径
          max_retries: 3,                   //上传失败最大重试次数
          //dragdrop: true,                   //开启可拖曳上传
         // drop_element: 'container',        //拖曳上传区域元素的ID，拖曳文件或文件夹后可触发上传
          chunk_size: '4mb',                //分块上传时，每片的体积
          auto_start: true,                 //选择文件后自动上传，若关闭需要自己绑定事件触发上传
          filters: {
                mime_types : [ //只允许上传图片和zip文件
                  { title : "Video files", extensions : "mp4" },
                ],
                max_file_size : '5000mb', //最大只能上传5000mb的文件
                prevent_duplicates : false //不允许选取重复文件
          },
          init: {
              'FilesAdded': function(up, files) {
                  plupload.each(files, function(file) {
                      // 文件添加进队列后,处理相关的事情
                  });
              },
              'BeforeUpload': function(up, file) {
                     // 每个文件上传前,处理相关的事情
                     oVideoAdd.style.display='none';
                     var div=document.createElement('div');
                     div.className='thumb-show';
                     div.innerHTML='<span class="thumbnail-cover"><img class="js-inputImg" src="http://7xlmj0.com1.z0.glb.clouddn.com/tasktype/uid/c778516b996887f66ecf4d1839dd8fbb.jpg?imageMogr2/auto-orient/thumbnail/!244x244r/gravity/Center/crop/244x244"/></span>'
                     oVideo.appendChild(div);
                    var oA=document.createElement('a');
                    oA.className='close close-rounded-sm';
                    oA.innerHTML='&times';
                    oA.setAttribute('href','javascript:;');
                    div.appendChild(oA);
                    oA.onclick=function(){
                      uploader.stop();
                      oVideo.removeChild(this.parentNode);
                      oVideoAdd.style.display='inline-block';
                      oVideoNum.innerHTML=0;
                    };

              },
              'UploadProgress':function(uploader,file){
                oVideoNum.innerHTML=file.percent;
                oCloseVideo.onclick=function(){
                    uploader.stop();
                    uploader.destroy();
                };
              },
              'FileUploaded': function(up, file, info) {
                     // 每个文件上传成功后,处理相关的事情
                     // 其中 info 是文件上传成功后，服务端返回的json，形式如
                     // {
                     //    "hash": "Fh8xVqod2MQ1mocfI4S4KpRL6D98",
                     //    "key": "gogopher.jpg"
                     //  }
                     // 参考http://developer.qiniu.com/docs/v6/api/overview/up/response/simple-response.html
                     var domain = up.getOption('domain');
                     var res =$.parseJSON(info);
                     var sourceLink = 'http://'+domain+'/'+res.key; //获取上传成功后的文件的Url
                      $('.thumb-show .js-inputImg').attr('data-src',res.key);
              },
              'Error': function(up, err, errTip) {
                     //上传出错时,处理相关的事情
              },
              'UploadComplete': function() {
                     //队列文件处理完毕后,处理相关的事情
              },
              'Key': function(up, file) {
                  // 若想在前端对每个文件的key进行个性化处理，可以配置该函数
                  // 该配置必须要在 unique_names: false , save_key: false 时才生效

                  var date = new Date();
                  var time = date.getTime();
                  var md = $.md5('' + time);
                  var key = "tasktype" + "/" + "uid" + "/" + md;
                  return key;
              }
          }
        });

      },
      error:function(){
        alert('暂时无法上传视频');
      }
    });
  }

    //oPhotoAdd:添加按钮
  //ophoto 添加到的元素
  // 上传图片
  function fnuploadphoto(oPhotoAdd,oPhoto,maxlen,maxSize){
    var oPhotoAdd2=document.querySelector(oPhotoAdd);
    var oPhoto2=document.querySelector(oPhoto);
    var imglen=0;
    $.ajax({
      type:'post',
      url:'/api/qiniu_uptoken',
      success:function(msg){
          // 引入Plupload 、qiniu.js后
          var uploader = Qiniu.uploader({
              runtimes: 'html5,flash,html4',    //上传模式,依次退化
              browse_button: oPhotoAdd2,       //上传选择的点选按钮，**必需**
              //uptoken_url:'http://192.168.1.139:3000/api/qiniu_uptoken',            //Ajax请求upToken的Url，**强烈建议设置**（服务端提供）
              //uptoken_url: 'http://101.200.73.14/api/qiniu_uptoken',            //Ajax请求upToken的Url，**强烈建议设置**（服务端提供）
              uptoken :msg.uptoken, //若未指定uptoken_url,则必须指定 uptoken ,uptoken由其他程序生成
              // unique_names: true, // 默认 false，key为文件名。若开启该选项，SDK为自动生成上传成功后的key（文件名）。
              // save_key: true,   // 默认 false。若在服务端生成uptoken的上传策略中指定了 `sava_key`，则开启，SDK会忽略对key的处理
              domain:msg.qiniu_host,   //bucket 域名，下载资源时用到，**必需**
              get_new_uptoken: true,  //设置上传文件的时候是否每次都重新获取新的token
              max_file_size: ''+maxSize+'M',           //最大文件体积限制
              flash_swf_url: 'js/plupload/Moxie.swf',  //引入flash,相对路径
              max_retries: 3,                   //上传失败最大重试次数
              dragdrop:false,                   //开启可拖曳上传
              // drop_element: 'container',        //拖曳上传区域元素的ID，拖曳文件或文件夹后可触发上传
              chunk_size: '4mb',                //分块上传时，每片的体积
              auto_start: true,                 //选择文件后自动上传，若关闭需要自己绑定事件触发上传
              filters: {
                mime_types : [ //只允许上传图片和zip文件
                  { title : "Image files", extensions : "jpg,gif,png,jpeg" },
                ],
                prevent_duplicates : false //不允许选取重复文件
              },
              init: {
                'FileFiltered':function(uploader,file){

                 },
                'FilesAdded': function(up, files) {
                  plupload.each(files, function(file) {
                    // 文件添加进队列后,处理相关的事情
                    if(!checkImgExtension(file.name)){
                      uploader.stop();
                      uploader.destroy();
                      alert('格式需是jpg/jpeg/gif/png');
                    }
                  });
                },
                'BeforeUpload': function(up, file) {
                         // 每个文件上传前,处理相关的事情

                },
                'UploadProgress': function(up, file) {
                   // 每个文件上传时,处理相关的事情

                },
                'FileUploaded': function(up, file, info) {
                   // 每个文件上传成功后,处理相关的事情
                   // 其中 info 是文件上传成功后，服务端返回的json，形式如
                   // {
                   //    "hash": "Fh8xVqod2MQ1mocfI4S4KpRL6D98",
                   //    "key": "gogopher.jpg"
                   //  }
                   // 参考http://developer.qiniu.com/docs/v6/api/overview/up/response/simple-response.html
                    imglen++;
                    if(imglen>maxlen){
                      bAdd=false;
                      uploader.splice(maxlen,9999);
                      alert('最多上传'+maxlen+'张');
                      imglen--;
                      oPhotoAdd2.style.display='none';
                    }
                    else if(imglen==maxlen){
                      bAdd=true;
                      uploader.splice(maxlen,999);
                      oPhotoAdd2.style.display='none';
                    }
                    else{
                      bAdd=true;
                      oPhotoAdd2.style.display='inline-block';
                    }
                    if(bAdd){
                      var domain = up.getOption('domain');
                      var res =$.parseJSON(info);
                      var sourceLink ='http://'+domain+'/'+res.key; //获取上传成功后的文件的Url
                      var div=document.createElement('div');
                      div.className='thumb-show';
                      div.innerHTML='<span class="thumbnail-cover"><img class="js-inputImg" src='+sourceLink+'?imageMogr2/auto-orient/thumbnail/!120x120r/gravity/Center/crop/120x120'+' data-src='+res.key+'></span>';
                      oPhoto2.insertBefore(div,oPhotoAdd2);
                      var oA=document.createElement('a');
                      oA.innerHTML='&times';
                      oA.className='close close-rounded-sm deletephoto';
                      oA.setAttribute('href','javascript:;')
                      div.appendChild(oA);
                      oA.onclick=function(){
                       oPhoto2.removeChild(this.parentNode);
                       imglen--;
                       oPhotoAdd2.style.display='inline-block';
                      }
                    };
                },
                'Error': function(up, err, errTip) {
                   //上传出错时,处理相关的事情
                     alert(errTip);
                },
                'UploadComplete': function() {
                  //队列文件处理完毕后,处理相关的事情
                },
                'Key': function(up, file) {
                  // 若想在前端对每个文件的key进行个性化处理，可以配置该函数
                  // 该配置必须要在 unique_names: false , save_key: false 时才生效
                  var date = new Date();
                  var time = date.getTime();
                  var md = $.md5('' + time);
                  var key = "tasktype" + "/" + "uid" + "/" + md + ".jpg";
                  return key;
                }
              }
          });
      },
      error:function(msg){
        alert('暂时无法上传');
      }
    });
  }
  //最终单选
  //js-tagbox  js-name js-upload-photo-1  js-upload-photoadd-1
  function fnuploadphotoradio(oPhotoAdd,oPhoto,maxlen){
    var oPhotoAdd2=document.querySelector(oPhotoAdd);
    var oPhoto2=document.querySelector(oPhoto);
    var imglen=0;
    $.ajax({
      type:'post',
      url:'/api/qiniu_uptoken',
      success:function(msg){
          // 引入Plupload 、qiniu.js后
          var uploader = Qiniu.uploader({
              runtimes: 'html5,flash,html4',    //上传模式,依次退化
              browse_button: oPhotoAdd2,       //上传选择的点选按钮，**必需**
              //uptoken_url:'http://192.168.1.139:3000/api/qiniu_uptoken',            //Ajax请求upToken的Url，**强烈建议设置**（服务端提供）
              //uptoken_url: 'http://101.200.73.14/api/qiniu_uptoken',            //Ajax请求upToken的Url，**强烈建议设置**（服务端提供）
              uptoken :msg.uptoken, //若未指定uptoken_url,则必须指定 uptoken ,uptoken由其他程序生成
              // unique_names: true, // 默认 false，key为文件名。若开启该选项，SDK为自动生成上传成功后的key（文件名）。
              // save_key: true,   // 默认 false。若在服务端生成uptoken的上传策略中指定了 `sava_key`，则开启，SDK会忽略对key的处理
              domain:msg.qiniu_host,   //bucket 域名，下载资源时用到，**必需**
              get_new_uptoken: true,  //设置上传文件的时候是否每次都重新获取新的token
              max_file_size: '2M',           //最大文件体积限制
              flash_swf_url: 'js/plupload/Moxie.swf',  //引入flash,相对路径
              max_retries: 3,                   //上传失败最大重试次数
              dragdrop:false,                   //开启可拖曳上传
              // drop_element: 'container',        //拖曳上传区域元素的ID，拖曳文件或文件夹后可触发上传
              chunk_size: '4mb',                //分块上传时，每片的体积
              auto_start: true,                 //选择文件后自动上传，若关闭需要自己绑定事件触发上传
              filters: {
                mime_types : [ //只允许上传图片和zip文件
                  { title : "Image files", extensions : "jpg,gif,png,jpeg" },
                ],
                max_file_size : '2048kb', //最大只能上传4000kb的文件
                prevent_duplicates : false //不允许选取重复文件
              },
              init: {
                'FileFiltered':function(uploader,file){

                 },
                'FilesAdded': function(up, files) {
                  plupload.each(files, function(file) {
                    // 文件添加进队列后,处理相关的事情
                    if(!checkImgExtension(file.name)){
                      uploader.stop();
                      uploader.destroy();
                      alert('格式需是jpg/jpeg/gif/png');
                    }
                    console.log(checkImgExtension(file.name)+'========='+file.name);

                  });
                },
                'BeforeUpload': function(up, file) {
                         // 每个文件上传前,处理相关的事情

                },
                'UploadProgress': function(up, file) {
                   // 每个文件上传时,处理相关的事情

                },
                'FileUploaded': function(up, file, info) {
                   // 每个文件上传成功后,处理相关的事情
                   // 其中 info 是文件上传成功后，服务端返回的json，形式如
                   // {
                   //    "hash": "Fh8xVqod2MQ1mocfI4S4KpRL6D98",
                   //    "key": "gogopher.jpg"
                   //  }
                   // 参考http://developer.qiniu.com/docs/v6/api/overview/up/response/simple-response.html
                    imglen++;
                    if(imglen>maxlen){
                      bAdd=false;
                      uploader.splice(maxlen,9999);
                      alert('最多上传'+maxlen+'张');
                      imglen--;
                      oPhotoAdd2.style.display='none';
                    }
                    else if(imglen==maxlen){
                      bAdd=true;
                      uploader.splice(maxlen,999);
                      oPhotoAdd2.style.display='none';
                    }
                    else{
                      bAdd=true;
                      oPhotoAdd2.style.display='inline-block';
                    }
                    if(bAdd){
                      var domain = up.getOption('domain');
                      var res =$.parseJSON(info);
                      var sourceLink ='http://'+domain+'/'+res.key; //获取上传成功后的文件的Url
                      var div=document.createElement('div');
                      div.className='thumb-show';
                      div.innerHTML='<span class="thumbnail-cover"><img class="js-inputImg" src='+sourceLink+'?imageMogr2/auto-orient/thumbnail/!120x120r/gravity/Center/crop/120x120'+' data-src='+res.key+'></span>';
                      oPhoto2.appendChild(div);
                      var oA=document.createElement('a');
                      oA.innerHTML='&times';
                      oA.className='close close-rounded-sm deletephoto';
                      oA.setAttribute('href','javascript:;')
                      div.appendChild(oA);
                      oA.onclick=function(){
                       oPhoto2.removeChild(this.parentNode);
                       imglen--;
                       oPhotoAdd2.style.display='inline-block';
                      }
                      $(oPhoto).parents('.js-tagbox').find('.js-name').attr('value',res.key);

                    };
                },
                'Error': function(up, err, errTip) {
                   //上传出错时,处理相关的事情
                     alert(errTip);
                },
                'UploadComplete': function() {
                  //队列文件处理完毕后,处理相关的事情
                },
                'Key': function(up, file) {
                  // 若想在前端对每个文件的key进行个性化处理，可以配置该函数
                  // 该配置必须要在 unique_names: false , save_key: false 时才生效
                  var date = new Date();
                  var time = date.getTime();
                  var md = $.md5('' + time);
                  var key = "tasktype" + "/" + "uid" + "/" + md + ".jpg";
                  return key;
                }
              }
          });
      },
      error:function(msg){
        alert('暂时无法上传');
        window.alert=function(str){
          return;
        };
      }
    });
  }
  //多选的添加
  $('.js-sub').on('click',function(){
    var oName=$('.js-name').attr('name');
    $('.js-upload-photo').find('.js-inputImg').each(function(index){
      $('.js-upload-photo').append('<input type="hidden" name="'+oName+'" class="js-inputkey" value="'+$(this).attr('data-src')+'"/>');
    })
  })



  $('.topics-photo .closephoto').click(function(){
    $('.topics-photo').hide();
    clearphoto();
  });
  $('.topics-video .closevideo').click(function(){
    $('.topics-video').hide();
    clearvideo();
  });
})
function clearphoto(){
  $('.topics-photo .thumb-show').remove();
  $('.topics-photo .topics-num').html('0');
  $('.photoadd').css('display','inline-block');
}
function clearvideo(){
  $('.topics-video .thumb-show').remove();
  $('.topics-video .topics-num').html('0');
  $('.videoadd').css('display','inline-block');
}
function checkImgExtension(fileName){
  var fileExtension = fileName.substring(fileName.lastIndexOf('.'),fileName.length).toLowerCase();
  if(fileExtension !='.jpg'&& fileExtension!='.jpeg'&& fileExtension!='.png'&& fileExtension!='.gif'){
    return false;
  }else{
    return true;
  }
}
