$(function(){
  // 点赞
  var targetEle = $(".js-like");
  $(targetEle).on('click', function(e){
    var that = $(this);
    var id = that.data('id');
    var likeCount = that.find('.js-like-count').text();
    $.ajax({
      url: '/shop/subjects/' + id + '/like.json',
      type: 'PUT',
      success: function(msg){
        if (msg.error) {
          window.location.href = '/sessions/new?redirect=/shop/subjects/'+ id;
        }else{
          if (msg.status) {
            that.html("<i class='icons text-highlight-r'>&#xe641;</i> <span class='js-like-count'>" + (parseInt(likeCount)+1) + "</span>");
          }
        }
      },
      error: function(){

      }
    })
  });
});
