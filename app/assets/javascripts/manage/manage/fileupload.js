$(function(){
  if(document.querySelector('.js-upload-photoadd-1')&&document.querySelector('.js-upload-photo-1')){
    $('.js-photobtn1').each(function(index){
      $(this).on('click',function(){
        var str='<div class="thumb-img-add topics-btn js-upload-photoadd-1"></div>';
        $($('.js-upload-photo-1')[index]).html(str).toggleClass('hide');
        var oPhotoAdd = $('.js-upload-photoadd-1')[index],
        oPhoto = $('.js-upload-photo-1')[index];
        fnuploadphotoradio(oPhotoAdd,oPhoto,1);
      });
    });
  }
  //shu xi
  if($('.js_letter_form').length){
    var oldImgChange = $('.js_img_active').length;
    var oldImgCount = $('.js_img_active').length;
    if(oldImgCount >=30){
      $('.js-upload-photoadd1').css('display','none');
    }
    var letterObj = {
      count : 30
    };
    letterObj.count = 30-oldImgChange;
    $('.js_letter_form').bind('submit',function(){
      var oName=$('.js-name1').attr('data-name');
      $('.js-upload-photo1').find('.js-inputImg').each(function(index){
        $('.js-upload-photo1').append('<input type="hidden" name="'+oName+'['+(index+oldImgCount)+'][pic]" class="js-inputkey" value="'+$(this).attr('data-src')+'"/><input type="hidden" name="'+oName+'['+(index+oldImgCount)+'][active]" value="1"/>');
      });
      $("form[class='js_letter_form']").submit();
    });
    $('.js_delete_letter').each(function(){
      $(this).click(function(){
        $(this).parents('.js_letter_box').find('.js_input_active').val('0');
        $(this).parents('.js_letter_box').find('.js_img_active').remove();
        $(this).parents('.js_letter_box').css('display','none');
        oldImgChange = $('.js_img_active').length;
        if(oldImgChange<30){
           $('.js-upload-photoadd1').css('display','inline-block');
        }
        letterObj.count = 30-oldImgChange;
      });
    });
    if(document.querySelector('.js-upload-photoadd1')&&document.querySelector('.js-upload-photo1')){
      fnuploadphoto('.js-upload-photoadd1','.js-upload-photo1',letterObj);
    }
    if(document.querySelector('.js-upload-photoadd2')&&document.querySelector('.js-upload-photo2')){
        fnuploadphotoradio('.js-upload-photoadd2','.js-upload-photo2',1);
    }
  }
  //最终单选
  //js-tagbox  js-name js-upload-photo-1  js-upload-photoadd-1
  function fnuploadphotoradio(oPhotoAdd,oPhoto,maxlen){
    var oPhotoAdd2=oPhotoAdd;
    var oPhoto2=oPhoto;
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
              chunk_size: '2mb',                //分块上传时，每片的体积
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
    //oPhotoAdd:添加按钮
  //ophoto 添加到的元素
  // 上传图片
  function fnuploadphoto(oPhotoAdd,oPhoto,maxlen){
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
              max_file_size: '10M',           //最大文件体积限制
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
                    if(imglen>maxlen.count){
                      bAdd=false;
                      uploader.splice(maxlen.count,9999);
                      alert('最多上传'+maxlen.count+'张');
                      imglen--;
                      oPhotoAdd2.style.display='none';
                    }
                    else if(imglen==maxlen.count){
                      bAdd=true;
                      uploader.splice(maxlen.count,999);
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

  //验证图片
  $('.back_submit').click(function(){
    var bImg = true,
      i = 0,
      max,
      maxName = $('.file_required');
    for(i = 0,max = maxName.length; i < max; i += 1 ){
      if(maxName[i].value === ""){
        bImg = false;
        $(maxName[i]).parent().find('.js-textError').html('请上传图片');
      }
    }
    if(!bImg){
      event.preventDefault();
    }
  });
});
