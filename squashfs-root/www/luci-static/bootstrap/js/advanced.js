	var media_path;
	$(function(){
		$(".radioSwitch").click(function(){
			var radio_name = $(this).attr("name");			
			$("img[name='"+radio_name+"']").attr("src",media_path+"/images/icon_radio_off.png");
			$(this).attr("src",media_path+"/images/icon_radio_on.png");	
		});	
		
		$(".showOrHide").click(function(){
			var radio_val = $(this).attr("value");
			if(radio_val == 1){
				$(".contentDisplay").show();
			}else{
				$(".contentDisplay").hide();
			}
		});
		
		$(".setval").click(function(){	
			var radio_val = $(this).attr("value");
			
			$("#radio_val").val(radio_val);	
			var val = $("#radio_val").val();
		});	
		
		$(".passwdDis").click(function(){
			if( $(this).hasClass('icon-invisible') ){
				$(this).removeClass("icon-invisible");
				$(this).addClass("icon-visible");
				$(this).prev("input").attr("type","text");
			}else if($(this).hasClass('icon-visible')){
				$(this).removeClass("icon-visible");
				$(this).addClass("icon-invisible");	
				$(this).prev("input").attr("type","password");
			}					
		});
		
		$(".advanced .dropdown_button").click(function(){
			var str_class = $(this).children("span").attr("class");
			$(this).children("span").removeClass("icon-downarrow");
	        if($(this).parents(".dropdown_div").hasClass("open")){
	            $(this).children("span").addClass("icon-downarrow");
	        }else{
	            $(this).children("span").addClass("icon-uparrow");
	        }
		});
		$(".advanced .dropdown_button").next("ul").children("li").click(function(){
			var str = $(this).children("a").attr("value");
			$(this).parents(".dropdown_div").find("input[name=select_opt]").val(str);
			$(this).parent("ul").prev("div").find("span").removeClass("icon-uparrow");
			$(this).parent("ul").prev("div").find("span").addClass("icon-downarrow");
		});		
	});
