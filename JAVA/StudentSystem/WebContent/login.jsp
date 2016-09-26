<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ taglib prefix="s" uri="/struts-tags" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title>Login</title>
</head>
<body align="center">
	<h1 align="center">Please Login: </h1>
    <form action="login.action" method="post">
    	<table border="1" align="center">
    		<tr>
    			<th align="left">User: </th>
    			<td><input type="text" name="synName"/></td>
    		</tr>
    		<tr>
    			<th align="left">Password: </th>
    			<td><input type="password" name="password"/></td>
    		</tr>
    		<tr>
    			<th></th>
    			<td align="center"><input type="submit" value="登陆"/></td>
    		</tr>
    	</table>
    </form>
</body>
</html>