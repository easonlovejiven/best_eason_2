$(function(){
	$(document).on({
		click: function(){
			var site = $(this).data('site');
			window.open('/connections/new?redirect=%2Fconnections%2Fpopup%3Fredirect%3D'+encodeURIComponent(encodeURIComponent($('#user_login_redirect').val() || $('#user_signup_redirect').val() || $(this).data('url') || '/'))+'&site='+site.name, '', 'width='+site.width+',height='+site.height+'');
			return false;
		}
	}, '.js_user_connection');
	$(document).on({
		click: function(){
			$('#captcha_image').attr('src', $('#captcha_image').attr('src').replace(/\?.*/, '')+'?'+(new Date()).getTime());
			$('#user_reset_account_captcha, #user_signup_captcha').val('').focus().select();
		}
	}, '#captcha_refresh');
	$(document).on({
		click: function(){
			$('#captcha_image_phone').attr('src', $('#captcha_image_phone').attr('src').replace(/\?.*/, '')+'?'+(new Date()).getTime());
			// $('#user_reset_account_captcha, #jqcaptcha').val('').focus().select();
		}
	}, '#captcha_refresh_phone');

	//登陆
	$("#userlogin").validate({
		errorPlacement: function(error, element) {
			// Append error within linked label
			$( element )
				.closest( "form" )
					.find( "label[for='" + element.attr( "id" ) + "']" )
						.next('div').append( error );
		},
		submitHandler: function(form) {
			$('.js-submit').attr('disabled',true);
			$.ajax({
				url:'/sessions.json',
				data:{
					'account[login]':$('.js-user').val(),
					'account[password]':$('.js-pass').val(),
          'connection_id':$('#account_connection_id').val(),
          'connection_sign': $('#account_connection_sign').val(),
					'redirect':$('#user_login_redirect').val()
				},
				type:'post',
				success:function(msg){
					if(msg.error){
						$('.js-submit').attr('disabled',false);
						alert(msg.error);
					}else{
						window.location.href=msg.url;
					}
				}
			})
		}
	});

	//切换tab的时候 验证码改变
	$('#myTabs a').click(function (e) {
	  e.preventDefault();
	  $(this).tab('show');
	  if($(this).attr('href')=='#modile-register'){
	  	$('#captcha_image_phone').attr('src', $('#captcha_image_phone').attr('src').replace(/\?.*/, '')+'?'+(new Date()).getTime());
	  }else{
			$('#captcha_image').attr('src', $('#captcha_image').attr('src').replace(/\?.*/, '')+'?'+(new Date()).getTime());
	  }
	})
	//手机号注册 短信倒计时  切换验证码
	$('.message').click(function(){
			if(!bOk){
				return;
			}
			$.ajax({
				url:'/accounts/send_phone_code.json',
				type:'post',
				data:{
							'_rucaptcha':$('.jqcaptcha').val(),
							'phone':$('.jqphone').val(),
							'type' : 'sms'
						},
				success:function(msg){
					if(msg.error){
						$('#captcha_image_phone').attr('src', $('#captcha_image_phone').attr('src').replace(/\?.*/, '')+'?'+(new Date()).getTime());
	 					alert(msg.error);
					}else{
						tickclick();
					}
				}
		})
	});
  //邮箱注册 邮箱倒计时  切换验证码
	$('#email_message').click(function(){
			if(!bOk){
				return;
			}
			$.ajax({
				url:'/accounts/send_email_code.json',
				type:'post',
				data:{
							'_rucaptcha':$('#user_signup_captcha').val(),
							'email':$('#jqemail').val()
						},
				success:function(msg){
					if(msg.error){
						$('#captcha_image').attr('src', $('#captcha_image').attr('src').replace(/\?.*/, '')+'?'+(new Date()).getTime());
	 					alert(msg.error);
					}else{
						ticEmailkclick();
					}
				}
		})
	});
	//手机号码检验
	$('.js_accounts_phone').blur(function(){
		$.ajax({
			url:'/accounts/validate_account.json',
			type: 'get',
			data: {
				'login' : $('.jqphone').val()
			},
			success : function(msg){
				if(msg.error){
					if($('.js_accounts_phone_error').length){
						$('.js_accounts_phone_error').text(msg.error);
					}else{
						$('.js_accounts_phone').parent().append('<span class="js_accounts_phone_error text-highlight-r">'+msg.error+'</span>')
					}
				}else{
					$('.js_accounts_phone_error').remove();
				}
			}
		})
	});
	$('.js_accounts_voice').on('click','.js_accounts_voice_btn',function(){
		$.ajax({
			url:'/accounts/send_phone_code.json',
			type:'post',
			data:{
				'_rucaptcha' : $('.jqcaptcha').val(),
				'phone' : $('.jqphone').val(),
				'type' : 'voice'
			},
			success:function(msg){
				if(msg.error){
					$('#captcha_image_phone').attr('src', $('#captcha_image_phone').attr('src').replace(/\?.*/, '')+'?'+(new Date()).getTime());
	 				alert(msg.error);
				}else{
					// $('.message').attr('disabled',true);
					// $('.js_accounts_voice_btn').attr('disabled',true);
					tickclick();
					$('.js_accounts_voice').text('正在向'+$('.jqphone').val()+'拨打电话,请留意接听。');
				}
			}
		})
	});

	//手机号注册
	$('#modile-register .jqsubmit').click(function(event){
		$('#modile-register .jqsubmit').attr('disabled',true);
		if($('.jqphone').val()==''||$('.jqcaptchafree').val()==''||$('.jqpassword').val()==''||$('.jqconfirmpassword').val()==''){
			$('#modile-register .jqsubmit').attr('disabled',false);
			alert('请认真填写');
			event.preventDefault();
		}else if($('#modile-register .jqpassword').val().length<6){
			$('#modile-register .jqsubmit').attr('disabled',false);
			alert('密码不得小于6位');
			event.preventDefault();
		}
		// else if(/\s+/g.test($('#modile-register .jqpassword').val())){
		// 	$('#modile-register .jqsubmit').attr('disabled',false);
		// 	alert('密码中有空格等特殊字符,请重试');
		// 	event.preventDefault();
		// }
		else if($('#modile-register .jqpassword').val() !==$('#modile-register .jqconfirmpassword').val()){
			$('#modile-register .jqsubmit').attr('disabled',false);
			alert('两次密码不一致,请重试');
			event.preventDefault();
		}else{
			$.ajax({
					type:'post',
					url:'/accounts.json',
					data:{'account[phone]':$('.jqphone').val(),
								'captcha':$('.jqcaptchafree').val(),
								'account[password]':$('.jqpassword').val(),
								'password_confirmation':$('.jqconfirmpassword').val(),
                'connection_id':$('#account_connection_id').val(),
                'sign':$('#account_connection_sign').val()
							},
					success:function(msg){
						if(msg.error){
              //$('#captcha_image_phone').attr('src', $('#captcha_image_phone').attr('src').replace(/\?.*/, '')+'?'+(new Date()).getTime());
							$('#modile-register .jqsubmit').attr('disabled',false);
							alert(msg.error);
							event.preventDefault();
							return false;
						}else{
							$('#showUserBox').modal();
						}
					},
					error:function(){
						$('#modile-register .jqsubmit').attr('disabled',false);
					}
			});
		};
	});
	//验证邮箱的格式 /^[A-Za-zd]+([-_.][A-Za-zd]+)*@([A-Za-zd]+[-.])+[A-Za-zd]{2,5}$/
	$('#jqemail').blur(function(){
		var rEmail =/^([a-zA-Z0-9_\.\-])+\@(([a-zA-Z0-9\-])+\.)+([a-zA-Z0-9]{2,4})+$/;
		var bEmail = rEmail.test($(this).val());
		if(bEmail){
			$('.js_accounts_email_error').remove();
		}else{
			if($('.js_accounts_email_error').length){
				$('.js_accounts_email_error').text('请输入正确邮箱');
			}else{
				$(this).parent().append('<span class="js_accounts_email_error text-highlight-r">请输入正确邮箱</span>')
			}
		}
	});
	//邮箱页面点击注册
	$('#email-register .jqsubmit').click(function(event){
		$('#email-register .jqsubmit').attr('disabled',true);
		if($('#jqemail').val()==''||$('#user_signup_captcha').val()==''||$('#jqpassword').val()==''||$('#jqpasswordconfirmation').val()==''){
			$('#email-register .jqsubmit').attr('disabled',false);
			alert('请认真填写');
			event.preventDefault();
		}else if($('#jqpassword').val().length<6){
			$('#email-register .jqsubmit').attr('disabled',false);
			alert('密码不得小于6位');
			event.preventDefault();
		}
		// else if(/\s+/g.test($('#jqpassword').val())){				//(!(/^[a-zA-Z0-9_@-]+$/g.test(oPass)))
		// 	$('#email-register .jqsubmit').attr('disabled',false);
		// 	alert('密码中有空格等特殊字符,请重试');
		// 	event.preventDefault();
		// }
		else if($('#jqpassword').val()!==$('#jqpasswordconfirmation').val()){
			$('#email-register .jqsubmit').attr('disabled',false);
			alert('两次密码不一致,请重试');
			event.preventDefault();
		}else{
			$.ajax({
				type:'post',
				url:'/accounts.json',
				data:{'account[email]':$('#jqemail').val(),
							'captcha':$('#jqcaptchafree_email').val(),
							'account[password]':$('#jqpassword').val(),
							'connection_id':$('#account_connection_id').val(),
							'sign':$('#account_connection_sign').val(),
							'account[password_confirmation]':$('#jqpasswordconfirmation').val()
						},
				success:function(msg){
					if(msg.error){
            $('#captcha_image').attr('src', $('#captcha_image').attr('src').replace(/\?.*/, '')+'?'+(new Date()).getTime());
            $('#email-register .jqsubmit').attr('disabled',false);
						alert(msg.error);
						event.preventDefault();
					}else{
						$('#showUserBox').modal();
					}
				},
				error:function(){
					$('#email-register .jqsubmit').attr('disabled',false);
				}
			});
		}
	});
	// $('.js-checkPhone').click(function(){
	// 	$.ajax({
	// 		url:'/'
	// 		type:'PUT',
	// 		data:{
	// 			phone:$('.jqphone').val(),
	// 			captcha:$('.jqcaptchafree').val()
	// 		},
	// 		success:function(){
	// 			alert('绑定成功');
	// 			event.preventDefault();
	// 		},
	// 		error:function(){
	// 			alert('绑定失败');
	// 			event.preventDefault();
	// 		}
	// 	});
	// });
	$('.js-checkPhone').on('click',function(){
		var oAuthurPass = $('#passoAuthur').val();
		var oConfirmAuthur = $('#confirmPassoAuthur').val();
		if(oAuthurPass){
			$.ajax({
				url: $('.js-checkPhoneForm').attr('action')+'.json',
				type:'PUT',
				data:{
					phone:$('.jqphone').val(),
					captcha:$('.jqcaptchafree').val(),
					password:oAuthurPass,
					password_confirmation:oConfirmAuthur
				},
				success:function(msg){
					if(msg.error){
						alert(msg.error);
					}else{
						window.location.href = '/accounts/edit_phone';
					}
				},
				error:function(){
					alert('修改失败');
				}
			})
		}else{
			$.ajax({
				url: $('.js-checkPhoneForm').attr('action')+'.json',
				type:'PUT',
				data:{
					phone:$('.jqphone').val(),
					captcha:$('.jqcaptchafree').val()
				},
				success:function(msg){
					if(msg.error){
						alert(msg.error);
					}else{
						window.location.href = '/accounts/edit_phone';
					}
				},
				error:function(){
					alert('修改失败');
				}
			})
		}
	});
	
	//短信倒计时
	var oMessage=$('.message');
  var oEmail = $('#email_message');
	var s=91;
 	var timer=null;
 	var bOk=true;

 	function tickclick(){
 		if(bOk){
 			clearInterval(timer);
 			bOk=false;
 			oMessage.attr('disabled','true')
 			oMessage.css('background-color','#ccc');
 			$('.js_accounts_voice_btn').attr('disabled',true);
 			function tick(){
 				s--;
 				oMessage.html('验证码发送中'+s+'s');
 				if(s<0){
 					clearInterval(timer);
 					s=91;
 					bOk=true;
 					oMessage.html('重新发送验证码');
 					oMessage.removeAttr('disabled');
 					oMessage.css('background-color','#FE4227');
 					$('.js_accounts_voice').removeClass('hide');
 					$('.js_accounts_voice_btn').attr('disabled',false);
 					$('.js_accounts_voice').html('没有收到短信验证码？您可以尝试重新发送或使用<a href="#" class="text-primary js_accounts_voice_btn">语音验证码</a>');
 				}
 			}
 			tick();
 			timer=setInterval(tick,1000);
 		}
	}
  function ticEmailkclick(){
 		if(bOk){
 			clearInterval(timer);
 			bOk=false;
 			oEmail.attr('disabled','true')
 			oEmail.css('background-color','#ccc');
 			$('.js_accounts_voice_btn').attr('disabled',true);
 			function tick(){
 				s--;
 				oEmail.html('验证码发送中'+s+'s');
 				if(s<0){
 					clearInterval(timer);
 					s=91;
 					bOk=true;
 					oEmail.html('重新发送验证码');
 					oEmail.removeAttr('disabled');
 					oEmail.css('background-color','#FE4227');
 				}
 			}
 			tick();
 			timer=setInterval(tick,1000);
 		}
	}

})
