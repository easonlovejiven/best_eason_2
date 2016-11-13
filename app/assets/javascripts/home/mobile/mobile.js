
function resetFontSize() {
  var html = document.documentElement;
  var windowWidth = html.clientWidth;
  html.style.fontSize = windowWidth / 6.4 + 'px';
};
$(window).resize(function(){
  var bodyWidth = document.body.clientWidth;
  if (bodyWidth<=767) {
    resetFontSize();
  }
});
document.addEventListener('DOMContentLoaded', function () {
  // 手机版初始化尺寸
  var bodyWidth = document.body.clientWidth;
  if (bodyWidth<=767) {
    resetFontSize();
  };
}, false);

$(function() {
  // 手机版侧边导航
  // $('.navbar-toggle').click(function(){
  //   var target = $(this).data('toggle');
  //   $(target).stop().animate({
  //     right: 0
  //   });
  //   $('body').addClass('open-menu');
  // });
  // $('.open-menu, .navbar-collapse-sm, .overlay-sm').click(function(){
  // // $('body').on('click','.backdrop-sm, .navbar-collapse-sm',function(){
  //   // alert(1)
  //   $('#navbar-sm').stop().animate({
  //     right: '-65%'
  //   });
  //   $('.backdrop-sm').remove();
  //   $('body').removeClass('open-menu');
  // });

  // 手机版导航搜索
  // $('.form-search-sm').find('.btn').click(function(){
  //   $(this).parents('.form-search-sm').addClass('search-full-sm').find('.form-search').stop().animate({
  //     width: '100%'
  //   }, 200).find('input').focus();
  // });
  // $('.form-search-sm').find('input').blur(function(){
  //   $(this).parents('.form-search-sm').removeClass('search-full-sm').find('.form-search').stop().animate({
  //     width: '44px'
  //   }, 200);
  // })
})
