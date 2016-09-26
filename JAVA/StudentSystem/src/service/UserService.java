package service;

import java.util.List;

import dao.UserDAO;
import model.User;
import service.UserService;

public class UserService {
	public String userLogin(String synName, String password) {
		UserDAO userDAO = new UserDAO();
		return userDAO.userLogin(synName, password);
	}

}
