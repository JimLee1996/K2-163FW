function dropdown_click(cur_this){
    var str_class = $(cur_this).children("span").attr("class");
    var cur_input_val = $(cur_this).children("input").val();
    $(cur_this).children("span").removeClass(str_class);
    $(cur_this).next("ul").find("a").attr("style","");
    var cur_select = $(cur_this).next("ul").find("a[value='"+cur_input_val+"']");
    cur_select.attr("style","color:#F08300;margin-left:2px;margin-right:2px;");
    if($(cur_this).parents(".dropdown_div").hasClass("open"))
    {
        $(cur_this).children("span").addClass("icon-downarrow");
    }else{
        $(cur_this).children("span").addClass("icon-uparrow");
    }
}
function changeInputType(curInput,input_type){
    var v_input = $('<input type="'+input_type+'"/>');
    v_input.attr("name",curInput.attr("name"));
    v_input.attr("id",curInput.attr("id"));
    v_input.attr("class",curInput.attr("class"));
    v_input.attr("onkeyup",curInput.attr("onkeyup"));
    v_input.val(curInput.val());
    curInput.replaceWith(v_input);
}
function hide_show_passwd(cur_this,prev_input){
    var img_src = $(cur_this).attr("src");
    var img = img_src.substring(0,img_src.length-6);
    var img_i = img_src.substring(img_src.length-6,img_src.length-4);
    if(img_i == "on"){
         $(cur_this).attr("src",img+"off.png");
         changeInputType(prev_input,"password");
    }else{
         $(cur_this).attr("src",img+"n.png");
         changeInputType(prev_input,"text");
    }
}
$(function(){
    $(".hide_show_pwd").click(function(){
        var str_value = $(this).attr("value");
        var str_input = $(this).parents("td").prev("td").find("input");
        if(str_value == "0"){
            changeInputType(str_input,"text");
            $(this).attr("value","1");
        }else{
            changeInputType(str_input,"password");
            $(this).attr("value","0");
        }
    });
    $(".dropdown_button").click(function(){
        var str_class = $(this).children("span").attr("class");
        $(this).children("span").removeClass(str_class);
        if($(this).parents(".dropdown_div").hasClass("open")){
            $(this).children("span").addClass("icon-downarrow");
        }else{
            $(this).children("span").addClass("icon-uparrow");
        }
    });
    $(".dropdown_button").next("ul").children("li").click(function(){
        var str = $(this).children("a").html();
        $(this).parents(".dropdown_div").find(".dropdown_input").val(str);
        $(this).parent("ul").prev("div").find("span").removeClass("icon-uparrow");
        $(this).parent("ul").prev("div").find("span").addClass("icon-downarrow");
    });
    $(".img_change").click(function(){
        var img_src = $(this).attr("src");
        var img = img_src.substring(0,img_src.length-6);
        var img_i = img_src.substring(img_src.length-6,img_src.length-4);
        if(img_i == "on"){
            $(this).attr("src",img+"off.png");
        }else{
            $(this).attr("src",img+"n.png");
        }
    });
    $('.content_body').niceScroll({
        cursorcolor: "#CCCCCC",
        cursoropacitymax: 1, 
        touchbehavior: false, 
        cursorwidth: "10px", 
        cursorborder: "0", 
        cursorborderradius: "5px",
        autohidemode: false 
    });
});
