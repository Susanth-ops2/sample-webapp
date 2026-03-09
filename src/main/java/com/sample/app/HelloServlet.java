package com.sample.app;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;

@WebServlet("/hello")
public class HelloServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("text/html;charset=UTF-8");
        PrintWriter out = response.getWriter();

        out.println("<!DOCTYPE html>");
        out.println("<html><head><title>Sample App</title></head>");
        out.println("<body>");
        out.println("<h1>Hello from CI/CD Pipeline!</h1>");
        out.println("<p>App Version: 1.0.0</p>");
        out.println("<p>Deployed via: Jenkins + Maven + Ansible</p>");
        out.println("<p>Server: " + request.getServerName() + "</p>");
        out.println("</body></html>");
    }
}
