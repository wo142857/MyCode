<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ taglib prefix="s" uri="/struts-tags" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title>录入</title>
</head>
<body>

	<s:if test="%{#session.login_name!=null}">

		<h2>录入学生信息</h2>
		<form  action="add" method="post">
				<table>
					<tr>
						<td>学号：</td>
						<td><input type="text" name="id" /></td>
					</tr>
					<tr>
						<td>姓名：</td>
						<td><input type="text" name="name" /></td>
					</tr>
					<tr>
						<td>性别：</td>
						<td>
						    男<input class="short_input" type="radio" name="gender" value="men" checked />
						    女<input class="short_input" type="radio" name="gender" value="women"/>
						
						</td>
					</tr>
					<tr>
						<td>年龄：</td>
						<td><input type="text" name="age" /></td>
					</tr>
					<tr>
					   <td></td>
					   <td><input type="submit" value="提交"></td>
					</tr>
				</table>
		</form>
	</s:if>
	<s:else>
	<%-- 	<s:a href="login.jsp">请先登录</s:a> --%>
		
		<jsp:useBean id="alert" class="utils.Alert">
			<jsp:setProperty name="alert" property="message" value="Please Login..."/>
		</jsp:useBean>
		
		<jsp:getProperty name="alert" property="result"/>
	</s:else>
</body>
</html>