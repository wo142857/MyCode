<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ taglib prefix="s" uri="/struts-tags" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title>Struts2实现分页显示</title>
</head>
<body>
<s:if test="%{#session.login_name!=null}">
	page now: <s:property value="pageNow"/>
	page count: <s:property value="pageCount"/>

	<div align="center">
		<table border="1" width="100%">
			<tr>
				<th>学号</th>
				<th>姓名</th>
				<th>性别</th>
				<th>年龄</th>
				<th>操作</th>
			</tr>
			<s:iterator value="students">
				<tr>
					<td><s:property value="id"/></td>
					<td><s:property value="name"/></td>
					<td><s:property value="gender"/></td>
					<td><s:property value="age"/></td>
					<td align="center">
						<s:url id="url_update" value="select.action">
							<s:param name="id" value="id"></s:param>
						</s:url>
						<s:url id="url_delete" value="delete.action">
						    <s:param name="id" value="id"></s:param>
						</s:url>
						<s:a href="%{url_update}">修改</s:a>
						<s:a href="%{url_delete}">删除</s:a>
					</td>
				</tr>
			</s:iterator>
		</table>
		
		<s:url id="url_first" value="show.action">
        		<s:param name="pageNow" value="1"></s:param>
	    </s:url>
		
		<s:url id="url_pre" value="show.action">
        		<s:param name="pageNow" value="pageNow-1"></s:param>
	    </s:url>  
	  
	    <s:url id="url_next" value="show.action"> 
	        <s:param name="pageNow" value="pageNow+1"></s:param>  
	    </s:url>
	    
	    <s:url id="url_last" value="show.action"> 
	        <s:param name="pageNow" value="pageCount"></s:param>  
	    </s:url>
	    
	    <s:a href="%{url_first}">首页</s:a> 
	  
		<s:if test="pageNow>1">
	    	<s:a href="%{url_pre}">上一页</s:a>
	    </s:if>
	       
	    <s:iterator value="students" status="status">  
	       <s:url id="url" value="show.action">  
	           <s:param name="pageNow" value="pageNow"/>  
	       </s:url>  
	    </s:iterator>
	     
	  	<s:if test="pageNow<pageCount">
	    	<s:a href="%{url_next}">下一页</s:a>
	    </s:if>
	    
	    <s:a href="%{url_last}">尾页</s:a>
	</div>
</s:if>
<s:else>
	<%-- <s:a href="login.jsp">请先登录</s:a> --%>
	<jsp:useBean id="alert" class="utils.Alert">
		<jsp:setProperty name="alert" property="message" value="Please Login..."/>
	</jsp:useBean>
		
	<jsp:getProperty name="alert" property="result"/>
</s:else>
</body>
</html>