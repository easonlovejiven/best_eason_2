$(function() {
  // 控制语音开始/暂停/关闭
  if($('.audio-play[data-id="js_audio"]').length){
    $('.audio-play[data-id="js_audio"]').on('click', function() {
      var thisId = $(this).data('id');
      var audio = document.getElementById(thisId);
      if(audio.paused){
        audio.play();
        $(this).html('<i class="icons">&#xe6be;</i>');
      }else{
        audio.pause();
        $(this).html('<i class="icons">&#xe6b0;</i>');
      };
    });
  }
});
