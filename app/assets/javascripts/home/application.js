// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery-2.1.4.min
//= require jquery_ujs
//= require bootstrap.min
//= require moment
//= require bootstrap-datetimepicker
//= require moment/zh-cn
//= require pickers
//= require md5
//= require plupload/plupload.full.min
//= require plupload/qiniu.min
//= require select2
//= require select2_locale_zh-CN
//= require select2_locale_en
//= require linkageSelect/LinkageSelect
//= require linkageSelect/location
//= require cocoon
//= require player/sewise.player.min
//= require player/swfobject
//= require jquery.validate.min.js
//= require slick.min
//= require home/common
//= require home/lazyload
//= require_tree .
//= require ./application/core/account

// $( "#dropdown" ).select2({
//     theme: "bootstrap"
// });
$(document).ready(function() {
  // console.log('111cccccccc')
  $("a.follow").on("ajax:success", function(event, success){
    // console.log('111cccccccc')
    var parent = $(event.target).parent()
    parent.find(".follow").addClass("hide");
    parent.find(".unfollow").removeClass("hide");
  });
  $("a.unfollow").on("ajax:success", function(event, success){
    // console.log('cccccccc')
    var parent = $(event.target).parent();
    parent.find(".follow").removeClass("hide");
    parent.find(".unfollow").addClass("hide");
  });
});
