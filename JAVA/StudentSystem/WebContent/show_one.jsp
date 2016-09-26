<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ taglib prefix="s" uri="/struts-tags" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title>学生信息</title>
</head>
<body>
	<h2 class="stu_title">修改学生信息</h2>
	<s:form action="update.action" method="post">
		<table>
			<tr>
				<td>学号：</td>
				<td><input type="text" name="id" value="${student.getId()}"/></td>
			</tr>
			<tr>
				<td>姓名：</td>
				<td><input type="text" name="name" value="${student.getName()}"/></td>
			</tr>
			<tr>
				<td>性别：</td>
				<td><input type="text" name="gender" value="${student.getGender()}"/></td>
			</tr>
			<tr>
				<td>年龄：</td>
				<td><input type="text" name="age" value="${student.getAge()}"/></td>
			</tr>
			<tr>
				<td></td>
				<td><input type="submit" value="提交"></td>
			</tr>
		</table>
	</s:form>
</body>
</html>