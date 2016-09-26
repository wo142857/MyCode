package utils;

public class Alert {
	private String message;
	private String result;
	
	public String alert() {
		String href = "";
		if("Please Login...".equals(message)) {
			href = "login.jsp";
		}
		return "<script language=\"JavaScript\">" +
				"alert(\"" + message + "\");" +
				"window.location.href=\"" + href + "\";" +
				"</script>";
	}
	
	public String getResult() {
		return alert();
	}
	
	public String getMessage() {
		return message;
	}
	public void setMessage(String message) {
		this.message = message;
	}
}
